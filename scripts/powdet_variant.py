#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 The SPARX Team
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# Description: Rewrite an emitted VACASK or ngspice testbench netlist into a power-detector design variant (m16, m1_pex, m1_kpex).
"""Power-detector design variants for the VACASK and ngspice testbenches.

The testbenches netlist the schematic as fabricated. The paper compares that
design against two variants that do not exist as schematics, so they are
produced by rewriting the emitted netlist. Any bench that instantiates the
detector qualifies, the receiver benches sparx_top_le_tb_*_vacask included, and
the rewritten netlist runs in simulations/<variant>/, so every include with a
relative path gets one more ../ on the way (relocate_includes):

  m1       the design as fabricated, copied unchanged
  m16      the Schottky diodes with 16 parallel unit cells (nx = ny = 4) instead
           of one, both the signal and the replica diode, everything else as is
  m1_pex   the fabricated design with its layout parasitics: the schematic
           subcircuit is replaced by the Magic full-RC extraction from
           netlist/pex, translated by the rules below
  m1_kpex  the same with the kpex 2.5D full-RC extraction, for the ngspice
           benches only, since its VACASK translation is not verified

The file suffix selects the dialect, .spectre for VACASK and .spice for
ngspice. The ngspice benches write their result tables themselves, so in a
SPICE netlist each `wrdata ../plot_simulations/data/<file>` also gets one more
../ and the variant as a suffix of <file>, as the post-processing scripts of the
VACASK benches do with POWDET_VARIANT (relocate_outputs).

The rewrite keeps the subcircuit name and pin order, so the testbench
instance and every save directive stay valid.

Translation of the extracted SPICE subcircuit, and why each rule exists:

- Node and instance names become plain identifiers. Magic writes `vss.t1` and
  `a_8474_2725#`, kpex `X$65` and `\\$I52.P1.MIM`, VACASK accepts neither `.`
  nor `#`. Every non-identifier character maps to `_`, and the map is checked
  to be injective, because a collision would short two nets in silence.
- Engineering suffixes are resolved to plain floats. SPICE is case-insensitive
  and reads `M` as milli, VACASK follows Verilog-A where `M` is mega.
- The Schottky diodes keep the schematic's PCell parameters. Magic reports the
  drawn outline of the PCell as `l=1.2u w=2.655u`, which is not the junction
  geometry the compact model expects: fed to `schottky_nbl1` it would scale the
  saturation current and junction capacitance by the outline area, 10.6 times
  the real cell, while the series resistance stays that of one cell. The
  instances are therefore emitted with `nx=1 ny=1` and no `l`/`w`, exactly as
  the schematic netlists them, and only the parasitics around them come from
  the extraction.
- The extracted resistors and capacitors use the `resistor` and `capacitor`
  models the testbench already declares for its source resistor and filter
  capacitors. `resistor` carries thermal noise by default, which is right for
  a physical interconnect.
- The ground net of the Magic extraction is idealized: every piece of `vss`
  that the resistance extraction produced (`vss.t1`, `vss.n35`, ...) is
  collapsed onto the pin.
  As extracted, the NMOS sources reach the pin only through a 1.4 kOhm
  substrate-like path (edges of 5 kOhm and 15 kOhm), which lifts them to
  0.5 V and cuts the bias current 12-fold, so the netlist would describe a
  different circuit. Whether the layout really grounds the TIA sources
  through the substrate or Magic's extresist lost the contact path is an
  open question for the layout, not for these testbenches. The coupling
  capacitors from the signal nets to ground stay, only the elements inside
  the ground net go. With the Makefile's resistance-gated extresist defaults
  (THRESHOLD=1000, MINRES=100, MINDELAY=0) what remains is the schematic, its
  parasitic capacitors, and the deterministic resistors of the vdd, vout and
  vref routes (22 Ohm in series with the feedback resistor, 6.4 Ohm per drain
  finger). The RF nets stay below the threshold and carry none. The operating
  point matches the schematic. The kpex extraction keeps its ground net, a
  metal mesh that carries the resistance of the bias MIM array.
- Nodes that touch nothing but coupling capacitors get a 1 TOhm resistor to
  the cell's ground pin. Without a DC path VACASK stops on a zero pivot, in
  the operating point and, since its gshunt option does not reach them, in
  the HB and HBAC matrices as well.
- The operating-point save file of the testbench names the schematic's
  instances, which the extracted view does not have, so its include is
  dropped. The plot scripts do not read those vectors.
"""

import argparse
import re
import sys
from pathlib import Path

PEX_DIR = Path(__file__).resolve().parent.parent / 'netlist' / 'pex'
# Full-RC extraction (EXT_MODE=3 of the Makefile's magic-pex and klayout-pex
# targets) and the nets collapsed onto their pin, per PEX variant.
PEX_VARIANTS = {
    'm1_pex': (PEX_DIR / 'sparx_powdet_sbd_magic_pex_3.spice', {'vss'}, 'the Magic full-RC extraction'),
    'm1_kpex': (PEX_DIR / 'sparx_powdet_sbd_klayout_pex_3.spice', set(), 'the kpex 2.5D full-RC extraction'),
}
SPICE_ONLY = {'m1_kpex'}
SUBCKT = 'sparx_powdet_sbd'
SUFFIX = {'t': 1e12, 'g': 1e9, 'meg': 1e6, 'k': 1e3, 'm': 1e-3, 'u': 1e-6, 'n': 1e-9, 'p': 1e-12, 'f': 1e-15, 'a': 1e-18}
# PCell devices whose extracted geometry must not reach the model, keyed by
# subcircuit name, with the parameters to emit instead.
PCELL_OVERRIDE = {'schottky_nbl1': 'nx=1 ny=1'}
# Nets whose extracted pieces (vss.t1, vss.n35, ...) are collapsed onto the
# pin in the Magic extraction, dropping the resistors and capacitors inside
# the net. See the docstring.
IDEAL_NETS = PEX_VARIANTS['m1_pex'][1]


def spice_value(tok):
    """`5.38u` -> `5.38e-06`, `0.26832m` -> `0.00026832`, `12.3` -> `12.3`."""
    m = re.fullmatch(r'([-+]?[\d.]+(?:[eE][-+]?\d+)?)([a-zA-Z]*)', tok)
    if not m:
        raise ValueError(f'cannot parse value {tok!r}')
    num, suf = m.groups()
    suf = suf.lower()
    if suf.startswith('meg'):
        scale = SUFFIX['meg']
    elif suf[:1] in SUFFIX:
        scale = SUFFIX[suf[:1]]
    elif suf == '':
        scale = 1.0
    else:
        raise ValueError(f'unknown suffix on {tok!r}')
    return repr(float(num) * scale)


class Mangler:
    def __init__(self):
        self.map = {}

    def __call__(self, name):
        clean = re.sub(r'[^A-Za-z0-9_]', '_', name)
        if clean[0].isdigit():
            clean = 'n' + clean
        prev = self.map.setdefault(clean, name)
        if prev != name:
            raise SystemExit(f'node name collision after mangling: {prev!r} and {name!r} both become {clean!r}')
        return clean


def logical_lines(text):
    out = []
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith('*'):
            continue
        if line.startswith('+') and out:
            out[-1] += ' ' + line[1:].strip()
        else:
            out.append(line)
    return out


def translate_pex(pex_text, subckt, dialect='vacask', ideal_nets=IDEAL_NETS):
    """Return the subcircuit text in VACASK or SPICE syntax for the extracted
    SPICE subcircuit, the element counts, and the pins of the extraction."""
    lines = logical_lines(pex_text)
    head = next(i for i, l in enumerate(lines) if l.lower().startswith('.subckt'))
    tail = next(i for i, l in enumerate(lines) if l.lower().startswith('.ends'))
    pins = lines[head].split()[2:]
    mangle = Mangler()
    instance = Mangler()
    spice = dialect == 'spice'

    def element(name, nodes, rest):
        if spice:
            return f'{name} {" ".join(nodes)} {rest}'.rstrip()
        return f'{name} ( {" ".join(nodes)} ) {rest}'.rstrip()

    pinlist = ' '.join(mangle(p) for p in pins)
    out = [f'.subckt {subckt} {pinlist}' if spice else f'subckt {subckt} ( {pinlist} )']
    counts = {}
    touched = {}

    def net(name):
        """Collapse the pieces of an idealized net onto its pin name."""
        base = name.split('.', 1)[0]
        return base if base in ideal_nets else name

    for line in lines[head + 1:tail]:
        tok = line.split()
        kind = tok[0][0].upper()
        name = instance(tok[0])
        if kind == 'X':
            params = [t for t in tok[1:] if '=' in t]
            fields = [t for t in tok[1:] if '=' not in t]
            nodes, model = [net(n) for n in fields[:-1]], fields[-1]
            if model in PCELL_OVERRIDE:
                plist = PCELL_OVERRIDE[model]
            else:
                plist = ' '.join(f'{k}={spice_value(v)}' for k, v in (p.split('=', 1) for p in params))
            out.append(element(name, [mangle(n) for n in nodes], f'{model} {plist}'))
        elif kind in ('R', 'C'):
            nodes = [net(tok[1]), net(tok[2])]
            if nodes[0] == nodes[1]:
                # both ends on the idealized net: a short or a capacitor to itself
                counts['collapsed'] = counts.get('collapsed', 0) + 1
                continue
            value = spice_value(tok[3])
            if not spice:
                value = ('resistor r=' if kind == 'R' else 'capacitor c=') + value
            out.append(element(name, [mangle(nodes[0]), mangle(nodes[1])], value))
        else:
            raise SystemExit(f'unhandled element in the extracted netlist: {line!r}')
        counts[kind] = counts.get(kind, 0) + 1
        for n in nodes:
            touched.setdefault(n, set()).add(kind)
    # Nodes that hang on coupling capacitors only have no DC path. VACASK adds
    # no conductance to ground on its own, and its gshunt option covers the
    # operating point but not the HB and HBAC matrices, which then stop on a
    # zero pivot. Every such node gets a 1 TOhm resistor to the ground pin of
    # the cell, invisible next to the 52 Ohm termination and the diode.
    gnd = next((p for p in pins if p.lower() in ('vss', 'gnd')), pins[-1])
    floating = sorted(n for n, kinds in touched.items() if kinds == {'C'} and n not in pins)
    for k, n in enumerate(floating):
        out.append(element(f'Rfloat{k}', [mangle(n), mangle(gnd)], '1e12' if spice else 'resistor r=1e12'))
    counts['float'] = len(floating)
    out.append('.ends' if spice else 'ends')
    return '\n'.join(out) + '\n', counts, pins


def relocate_includes(netlist, dialect='vacask'):
    """The variant netlist runs one directory deeper (simulations/<variant>/), so
    every include with a relative path (the fitted core models under
    netlist/spectre) gets one more ../. Bare file names (the PDK libraries,
    the .save file the Makefile copies next to the netlist) are left alone."""
    if dialect == 'spice':
        return re.sub(r'^(\s*\.include\s+)\.\./', r'\1../../', netlist, flags=re.M | re.I)
    return re.sub(r'^(\s*include\s+")\.\./', r'\1../../', netlist, flags=re.M)


def relocate_outputs(netlist, variant):
    """An ngspice bench writes its table to ../plot_simulations/data/<file>,
    which from simulations/<variant>/ is one more ../ away and carries the
    variant as a suffix, so the variants do not overwrite each other."""
    return re.sub(r'^(\s*wrdata\s+)\.\./(plot_simulations/data/\S+?)(\.\w+)(?=\s|$)',
                  rf'\1../../\2_{variant}\3', netlist, flags=re.M | re.I)


def replace_subckt(netlist, body, pex_pins, dialect):
    """Swap the schematic subcircuit for the translated extraction, after
    checking that both list the same pins in the same order, since the
    testbench instance connects by position."""
    if dialect == 'spice':
        pat = re.compile(r'^\.subckt[ \t]+' + SUBCKT + r'[ \t]+([^\n]*)\n.*?^\.ends\b[^\n]*$', re.M | re.S | re.I)
    else:
        pat = re.compile(r'^subckt ' + SUBCKT + r' \( ([^)]*) \)\n.*?^ends\s*$', re.M | re.S)
    found = pat.findall(netlist)
    if len(found) != 1:
        raise SystemExit(f'expected one subckt {SUBCKT} block in the netlist, found {len(found)}')
    pins = found[0].split()
    if [p.lower() for p in pins] != [p.lower() for p in pex_pins]:
        raise SystemExit(f'pins of subckt {SUBCKT} {pins} differ from the extraction {pex_pins}')
    return pat.sub(lambda m: body.rstrip('\n'), netlist)


def rewrite(netlist, variant, pex_path=None, dialect='vacask'):
    spice = dialect == 'spice'
    netlist = relocate_includes(netlist, dialect)
    if spice:
        netlist = relocate_outputs(netlist, variant)
    if variant == 'm1':
        return netlist, 'copied unchanged, relative includes relocated'
    if variant == 'm16':
        if spice:
            pat = re.compile(r'^(X[Dd]\d+ (?:\S+ ){3}schottky_nbl1 )nx=1 ny=1', re.M | re.I)
        else:
            pat = re.compile(r'^(X[Dd]\d+ \( [^)]* \) schottky_nbl1 )nx=1 ny=1', re.M)
        new, n = pat.subn(r'\1nx=4 ny=4', netlist)
        if n != 2:
            raise SystemExit(f'expected two schottky_nbl1 nx=1 ny=1 instances, found {n}')
        return new, 'both Schottky diodes set to nx=4 ny=4 (16 cells)'
    if variant in PEX_VARIANTS:
        if variant in SPICE_ONLY and not spice:
            raise SystemExit(f'variant {variant} is for the ngspice benches only, its VACASK translation is not verified')
        default_path, ideal_nets, what = PEX_VARIANTS[variant]
        body, counts, pex_pins = translate_pex((pex_path or default_path).read_text(encoding='utf-8'),
                                               SUBCKT, dialect, ideal_nets)
        new = replace_subckt(netlist, body, pex_pins, dialect)
        # The operating-point save file names the schematic's instances, which
        # the extracted view does not have, and VACASK refuses to bind a save
        # directive to a missing node. Drop the include, the plot scripts do
        # not read those vectors.
        if spice:
            new = re.sub(r'^[ \t]*\.include[ \t]+\S+\.save[ \t]*\n', '', new, flags=re.M | re.I)
        else:
            new = re.sub(r'^[ \t]*include "[^"\n]*\.save"[^\n]*\n', '', new, flags=re.M)
        return new, (f'subckt {SUBCKT} replaced by {what}: '
                     f'{counts.get("X", 0)} devices, {counts.get("R", 0)} resistors, {counts.get("C", 0)} capacitors, '
                     f'{counts.get("collapsed", 0)} elements inside the idealized nets {sorted(ideal_nets)} dropped, '
                     f'{counts.get("float", 0)} capacitor-only nodes tied to ground through 1 TOhm, '
                     'operating-point save include dropped')
    raise SystemExit(f'unknown variant {variant!r}')


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('src', type=Path, help='emitted netlist, VACASK (.spectre) or ngspice (.spice)')
    ap.add_argument('dst', type=Path, help='rewritten netlist')
    ap.add_argument('--variant', required=True, choices=['m1', 'm16', *PEX_VARIANTS])
    ap.add_argument('--pex', type=Path, default=None, help='extracted SPICE netlist for m1_pex or m1_kpex')
    a = ap.parse_args()
    dialect = {'.spectre': 'vacask', '.spice': 'spice'}.get(a.src.suffix)
    if dialect is None:
        sys.exit(f'{a.src}: expected a .spectre or .spice netlist')
    text = a.src.read_text(encoding='utf-8')
    new, what = rewrite(text, a.variant, a.pex, dialect)
    a.dst.parent.mkdir(parents=True, exist_ok=True)
    a.dst.write_text(new, encoding='utf-8')
    print(f'{a.dst}: {what}')
    return [a.dst]


if __name__ == '__main__':
    main()
