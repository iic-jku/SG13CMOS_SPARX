#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 The SPARX Team
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# Description: Rewrite an emitted VACASK testbench netlist into a power-detector design variant (m16, m1_pex).
"""Power-detector design variants for the VACASK testbenches.

The testbenches netlist the schematic as fabricated. The paper compares that
design against two variants that do not exist as schematics, so they are
produced by rewriting the emitted netlist. Any bench that instantiates the
detector qualifies, the receiver bench sparx_top_le_tb_rx_vacask included, and
the rewritten netlist runs in simulations/<variant>/, so every include with a
relative path gets one more ../ on the way (relocate_includes):

  m1      the design as fabricated, copied unchanged
  m16     the Schottky diodes with 16 parallel unit cells (nx = ny = 4) instead
          of one, both the signal and the replica diode, everything else as is
  m1_pex  the fabricated design with its layout parasitics: the schematic
          subcircuit is replaced by the Magic full-RC extraction from
          netlist/pex, translated from SPICE into VACASK syntax

The rewrite keeps the subcircuit name and pin order, so the testbench
instance and every save directive stay valid.

Translation of the extracted SPICE subcircuit, and why each rule exists:

- Node and instance names become plain identifiers. Magic writes `vss.t1` and
  `a_8474_2725#`, VACASK accepts neither `.` nor `#`. Every non-identifier
  character maps to `_`, and the map is checked to be injective, because a
  collision would short two nets in silence.
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
- The ground net is idealized: every piece of `vss` that the resistance
  extraction produced (`vss.t1`, `vss.n35`, ...) is collapsed onto the pin.
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
  point matches the schematic.
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

# The full-RC Magic extraction, EXT_MODE=3 of the Makefile's magic-pex target.
PEX_DEFAULT = Path(__file__).resolve().parent.parent / 'netlist' / 'pex' / 'sparx_powdet_sbd_magic_pex_3.spice'
SUBCKT = 'sparx_powdet_sbd'
SUFFIX = {'t': 1e12, 'g': 1e9, 'meg': 1e6, 'k': 1e3, 'm': 1e-3, 'u': 1e-6, 'n': 1e-9, 'p': 1e-12, 'f': 1e-15, 'a': 1e-18}
# PCell devices whose extracted geometry must not reach the model, keyed by
# subcircuit name, with the parameters to emit instead.
PCELL_OVERRIDE = {'schottky_nbl1': 'nx=1 ny=1'}
# Nets whose extracted pieces (vss.t1, vss.n35, ...) are collapsed onto the
# pin, dropping the resistors and capacitors inside the net. See the docstring.
IDEAL_NETS = {'vss'}


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


def translate_pex(pex_text, subckt):
    """Return the VACASK subcircuit text for the extracted SPICE subcircuit."""
    lines = logical_lines(pex_text)
    head = next(i for i, l in enumerate(lines) if l.lower().startswith('.subckt'))
    tail = next(i for i, l in enumerate(lines) if l.lower().startswith('.ends'))
    pins = lines[head].split()[2:]
    mangle = Mangler()
    out = [f'subckt {subckt} ( {" ".join(mangle(p) for p in pins)} )']
    counts = {}
    touched = {}

    def net(name):
        """Collapse the pieces of an idealized net onto its pin name."""
        base = name.split('.', 1)[0]
        return base if base in IDEAL_NETS else name

    for line in lines[head + 1:tail]:
        tok = line.split()
        kind = tok[0][0].upper()
        if kind == 'X':
            params = [t for t in tok[1:] if '=' in t]
            fields = [t for t in tok[1:] if '=' not in t]
            nodes, model = [net(n) for n in fields[:-1]], fields[-1]
            if model in PCELL_OVERRIDE:
                plist = PCELL_OVERRIDE[model]
            else:
                plist = ' '.join(f'{k}={spice_value(v)}' for k, v in (p.split('=', 1) for p in params))
            out.append(f'{tok[0]} ( {" ".join(mangle(n) for n in nodes)} ) {model} {plist}'.rstrip())
        elif kind in ('R', 'C'):
            nodes = [net(tok[1]), net(tok[2])]
            if nodes[0] == nodes[1]:
                # both ends on the idealized net: a short or a capacitor to itself
                counts['collapsed'] = counts.get('collapsed', 0) + 1
                continue
            elem = 'resistor r=' if kind == 'R' else 'capacitor c='
            out.append(f'{tok[0]} ( {mangle(nodes[0])} {mangle(nodes[1])} ) {elem}{spice_value(tok[3])}')
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
        out.append(f'Rfloat{k} ( {mangle(n)} {mangle(gnd)} ) resistor r=1e12')
    counts['float'] = len(floating)
    out.append('ends')
    return '\n'.join(out) + '\n', counts


def relocate_includes(netlist):
    """The variant netlist runs one directory deeper (simulations/<variant>/), so
    every include with a relative path (the fitted core models under
    netlist/spectre) gets one more ../. Bare file names (the PDK libraries,
    the .save file the Makefile copies next to the netlist) are left alone."""
    return re.sub(r'^(\s*include\s+")\.\./', r'\1../../', netlist, flags=re.M)


def rewrite(netlist, variant, pex_path):
    netlist = relocate_includes(netlist)
    if variant == 'm1':
        return netlist, 'copied unchanged, relative includes relocated'
    if variant == 'm16':
        pat = re.compile(r'^(X[Dd]\d+ \( [^)]* \) schottky_nbl1 )nx=1 ny=1', re.M)
        new, n = pat.subn(r'\1nx=4 ny=4', netlist)
        if n != 2:
            raise SystemExit(f'expected two schottky_nbl1 nx=1 ny=1 instances, found {n}')
        return new, 'both Schottky diodes set to nx=4 ny=4 (16 cells)'
    if variant == 'm1_pex':
        body, counts = translate_pex(pex_path.read_text(encoding='utf-8'), SUBCKT)
        pat = re.compile(r'^subckt ' + SUBCKT + r' \( [^)]* \)\n.*?^ends\s*$', re.M | re.S)
        new, n = pat.subn(lambda m: body.rstrip('\n'), netlist)
        if n != 1:
            raise SystemExit(f'expected one subckt {SUBCKT} block in the netlist, found {n}')
        # The operating-point save file names the schematic's instances, which
        # the extracted view does not have, and VACASK refuses to bind a save
        # directive to a missing node. Drop the include, the plot scripts do
        # not read those vectors.
        new = re.sub(r'^[ \t]*include "[^"\n]*\.save"[^\n]*\n', '', new, flags=re.M)
        return new, (f'subckt {SUBCKT} replaced by the Magic full-RC extraction: '
                     f'{counts.get("X", 0)} devices, {counts.get("R", 0)} resistors, {counts.get("C", 0)} capacitors, '
                     f'{counts.get("collapsed", 0)} elements inside the idealized nets {sorted(IDEAL_NETS)} dropped, '
                     f'{counts.get("float", 0)} capacitor-only nodes tied to ground through 1 TOhm, '
                     'operating-point save include dropped')
    raise SystemExit(f'unknown variant {variant!r}')


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('src', type=Path, help='emitted VACASK netlist (.spectre)')
    ap.add_argument('dst', type=Path, help='rewritten netlist')
    ap.add_argument('--variant', required=True, choices=['m1', 'm16', 'm1_pex'])
    ap.add_argument('--pex', type=Path, default=PEX_DEFAULT, help='extracted SPICE netlist for m1_pex')
    a = ap.parse_args()
    text = a.src.read_text(encoding='utf-8')
    new, what = rewrite(text, a.variant, a.pex)
    a.dst.parent.mkdir(parents=True, exist_ok=True)
    a.dst.write_text(new, encoding='utf-8')
    print(f'{a.dst}: {what}')


if __name__ == '__main__':
    main()
