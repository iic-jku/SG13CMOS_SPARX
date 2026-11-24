#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 The SPARX Team
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# Description: Print the detector input match at rfin from the ngspice S-parameter bench and check it against the VACASK PSS bench.
"""Input match of the power detector at rfin, from sparx_powdet_sbd_tb_acsp_ngspice.

Reads data/sparx_powdet_sbd_tb_acsp_ngspice<suffix>.txt, the wrdata table of
the bench, prints S11 and Z_in at 160 GHz and 161 GHz, and compares Z_in at
161 GHz with the small-signal input impedance of the VACASK PSS bench of the
same variant (`z_in_small_signal_ohm` in data/sparx_powdet_sbd_beta<suffix>.json,
from the HB solution at -76 dBm). A resistor between the RF port and rfin
shifts the ngspice value by its resistance and fails the check. Without that
JSON (m1_kpex, which has no VACASK run) the comparison is skipped, and a
table older than the netlist of the run fails, since it was not written by it.

POWDET_VARIANT selects the variant run by the Makefile (m16, m1_pex, m1_kpex),
as for the VACASK post-processing scripts.
"""
import json
import os
import sys

import ngspice2python as ng

TB = 'sparx_powdet_sbd_tb_acsp_ngspice'
VARIANT = os.environ.get('POWDET_VARIANT', '').strip()
SUFFIX = f'_{VARIANT}' if VARIANT else ''
DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'data')
SIM_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'simulations')
# ngspice and VACASK agree within 0.01 Ohm on m1, m16 and m1_pex, a source
# resistor in the wrong place is off by 50 Ohm.
TOL_OHM = 1.0


def main():
    table = os.path.join(DATA_DIR, f'{TB}{SUFFIX}.txt')
    if not os.path.isfile(table):
        sys.exit(f'{table} not found, run `make sim-xschem TB={TB}` first')
    # ngspice exits 0 when wrdata fails, so an older table is the committed one, not this run's
    netlist = os.path.join(SIM_DIR, VARIANT, f'{TB}.spice')
    if os.path.isfile(netlist) and os.path.getmtime(table) < os.path.getmtime(netlist):
        sys.exit(f'{table} is older than {netlist}, the run did not write it')
    f = ng.loadngspicecol(table, 'frequency')
    cols = {n: ng.loadngspicecol(table, n) for n in ('s11_db', 'zin_re', 'zin_im')}

    def at(f0):
        k = min(range(len(f)), key=lambda i: abs(f[i] - f0))
        if abs(f[k] - f0) > 1e6:
            sys.exit(f'{table} has no point at {f0 / 1e9:g} GHz')
        return cols['s11_db'][k], complex(cols['zin_re'][k], cols['zin_im'][k])

    for f0 in (160e9, 161e9):
        s11, z = at(f0)
        print(f'{TB}{SUFFIX}: S11 {s11:.2f} dB, Z_in {z.real:.2f} {z.imag:+.2f}j Ohm at {f0 / 1e9:.0f} GHz')

    beta = os.path.join(DATA_DIR, f'sparx_powdet_sbd_beta{SUFFIX}.json')
    if not os.path.isfile(beta):
        print(f'{os.path.basename(beta)} not found, comparison with the VACASK PSS bench skipped')
        return
    with open(beta, encoding='utf-8') as fh:
        z_hb = complex(*json.load(fh)['z_in_small_signal_ohm'])
    dz = abs(at(161e9)[1] - z_hb)
    print(f'VACASK PSS bench: Z_in {z_hb.real:.2f} {z_hb.imag:+.2f}j Ohm at 161 GHz, difference {dz:.2f} Ohm')
    if dz > TOL_OHM:
        sys.exit(f'Z_in differs from the VACASK PSS bench by {dz:.2f} Ohm, more than {TOL_OHM} Ohm')


if __name__ == '__main__':
    main()
