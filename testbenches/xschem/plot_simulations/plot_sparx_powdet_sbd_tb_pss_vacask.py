# SPDX-FileCopyrightText: 2025-2026 The SPARX Team
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# Description: Transfer curve of the SBD power detector from single-tone HB, checked against shooting PSS.

# ANALYZE THE SINGLE-TONE POWER SWEEP of the SBD power detector.
#
# The testbench drives one RF tone through a 50 Ohm source resistance Rs and
# sweeps its amplitude with harmonic balance on a decade grid (powdet_pss1),
# then runs the shooting periodic steady-state analysis at five drive levels
# (powdet_pss2a to powdet_pss2e, one analysis each). HB supplies the curve,
# PSS is the check: the period average of the PSS output waveform has to equal
# the HB curve at the same amplitude, interpolated in log-log, and the script
# prints how far apart the two are.
#
#   P_avail = a^2 / (8 * Rs)              available power of the source [W]
#   dV      = V_dc(a) - V_off             detected voltage, offset removed [V]
#   beta    = dV / P_avail                responsivity [V/W], flat in the
#                                         square-law region
#   Z_in    = V(rfin) / I,  I = (V(src) - V(rfin)) / Rs
#
# V_off is a fitted parameter of the square-law line, see below.
#
# Writes the fitted responsivity and the whole curve to
# plot_simulations/data/sparx_powdet_sbd_beta<suffix>.json, which the
# noise-figure testbench reads, and the curve as CSV for pgfplots.
#
# POWDET_VARIANT selects a design variant run by the Makefile (m16, m1_pex):
# the rawfiles are read from simulations/<variant>/ and every output carries
# the variant as a suffix. Empty means the design as fabricated.

from rawfile import rawread
import numpy as np
import os
import json
import re
import matplotlib
# Default to the non-interactive Agg backend: write the PNG, open no window.
# This is required under a VACASK postprocess, where a Qt window crashes VACASK's
# boost::asio loop ("Bad file descriptor"). To pop up the figure when running the
# script standalone, set the environment variable SHOW_PLOTS=1.
SHOW_PLOTS = os.environ.get('SHOW_PLOTS', '0') == '1'
if not SHOW_PLOTS:
    matplotlib.use('Agg')
import matplotlib.pyplot as plt

# Source resistance of the testbench [Ohm]. Must match Rs in the schematic.
RS = 50.0
# Hard sanity floor on the detected voltage. The testbench runs HB with
# reltol=1e-8 on a -7 mV output offset, which resolves a few 1e-10 V, so this
# is about an order of magnitude above the solver's own residual. The usable
# lower end of the sweep is then found from the data, not from this constant.
DV_FLOOR = 1e-9          # [V]
RAW_HB = 'powdet_pss1.raw'
TB = 'sparx_powdet_sbd_tb_pss_vacask'
VARIANT = os.environ.get('POWDET_VARIANT', '').strip()
SUFFIX = f'_{VARIANT}' if VARIANT else ''


def find_design_root():
    cands = [os.getcwd()]
    try:
        cands.append(os.path.dirname(os.path.abspath(__file__)))
    except NameError:
        pass
    for start in cands:
        d = start
        while True:
            if os.path.isdir(os.path.join(d, 'testbenches', 'xschem', 'simulations')):
                return d
            parent = os.path.dirname(d)
            if parent == d:
                break
            d = parent
    raise RuntimeError('Could not locate design root (need testbenches/xschem/simulations)')


DESIGN_ROOT = find_design_root()
SIM_DIR = os.path.join(DESIGN_ROOT, 'testbenches', 'xschem', 'simulations', VARIANT)
PLOT_DIR = os.path.join(DESIGN_ROOT, 'testbenches', 'xschem', 'plot_simulations')
FIG_DIR = os.path.join(PLOT_DIR, 'figures')
DATA_DIR = os.path.join(PLOT_DIR, 'data')
NETLIST = os.path.join(SIM_DIR, TB + '.spectre')
# The operating point analysis carries the testbench name.
OP_FILE = os.path.join(SIM_DIR, TB + '.raw')


def parse_var(netlist, name):
    """Read a `var <name>=<value>` line from the emitted netlist."""
    m = re.search(rf'var\s+{name}\s*=\s*([\d.eE+\-]+[GMKkT]?)', netlist)
    val = m.group(1)
    for suf, exp in (('G', 'e9'), ('M', 'e6'), ('K', 'e3'), ('k', 'e3'), ('T', 'e12')):
        val = val.replace(suf, exp)
    return float(val)


def dbm(p):
    return 10.0 * np.log10(p / 1e-3)


with open(NETLIST) as f:
    netlist = f.read()
freq_rf = parse_var(netlist, 'freq_rf')

op = rawread(OP_FILE).get()
v_op = float(np.real(op['out'])[0])

# --- harmonic balance sweep ------------------------------------------------
hb = rawread(os.path.join(SIM_DIR, RAW_HB)).get(sweeps=1)
ampl, v_dc, z_in = [], [], []
for g in range(hb.sweepGroups):
    a = float(np.abs(hb.sweepData(g)['ampl_rf']))
    freq = np.real(hb[g, 'frequency'])
    i_dc = int(np.argmin(np.abs(freq)))
    i_f0 = int(np.argmin(np.abs(freq - freq_rf)))
    v_rfin = hb[g, 'rfin'][i_f0]
    v_src = hb[g, 'src'][i_f0]
    # Current into the detector, from the drop across the known Rs. Taking it
    # from Rs rather than from the source branch flow avoids any sign convention.
    i_in = (v_src - v_rfin) / RS
    ampl.append(a)
    v_dc.append(float(np.real(hb[g, 'out'][i_dc])))
    z_in.append(v_rfin / i_in if abs(i_in) > 0 else complex('nan'))

order = np.argsort(ampl)
ampl = np.asarray(ampl)[order]
v_dc = np.asarray(v_dc)[order]
z_in = np.asarray(z_in)[order]
p_avail = ampl ** 2 / (8.0 * RS)          # [W]

# --- zero-drive reference and responsivity -------------------------------
# The zero-drive output V_off is a fitted parameter of the square-law line
# V_dc = V_off + beta * P, not a measured point. The two obvious references
# both bias the low end: the lowest HB point carries its own detected term
# (1e-9 V at -76 dBm, a 6 % error at -64 dBm), and the OP analysis differs
# from the HB DC bin by a systematic 0.5 uV that HB-against-HB differencing
# cancels and OP-against-HB does not (the script prints it). Fitting V_off on
# the square-law region uses only HB data and subtracts nothing twice.
# Pass 1 finds the square-law region with the lowest point as a provisional
# reference, pass 2 fits V_off and beta together on that region.
v_off = v_dc[0]
for _ in range(2):
    dv = v_dc - v_off
    usable = np.abs(dv) > DV_FLOOR
    if usable.sum() < 3:
        raise RuntimeError(f'Only {usable.sum()} points above the {DV_FLOOR:.0e} V floor. '
                           'Extend the sweep upwards or lower DV_FLOOR.')
    lp, ldv = np.log10(p_avail[usable]), np.log10(np.abs(dv[usable]))
    slope = np.gradient(ldv, lp)
    square_law = usable.copy()
    square_law[usable] = np.abs(slope - 1.0) < 0.1
    if square_law.sum() < 2:
        raise RuntimeError('No square-law region found (no point with log-log slope '
                           'within 0.1 of 1).')
    # Weighted so that every decade of power counts the same, otherwise the
    # top of the region, where dV is largest, sets both parameters alone.
    w = 1.0 / np.abs(dv[square_law])
    beta, v_off = np.polyfit(p_avail[square_law], v_dc[square_law], 1, w=w)
    beta, v_off = float(beta), float(v_off)

dv = v_dc - v_off
usable = np.abs(dv) > DV_FLOOR
p_fit_lo = float(p_avail[square_law].min())
p_fit_hi = float(p_avail[square_law].max())

# --- 1 dB compression: where |dV| falls 1 dB below the ideal beta * P line
ideal = np.abs(beta) * p_avail
dev_db = np.full_like(p_avail, np.nan)
np.divide(np.abs(dv), ideal, out=dev_db, where=usable & (ideal > 0))
dev_db = 20.0 * np.log10(np.where(dev_db > 0, dev_db, np.nan))
above = np.where((p_avail > p_fit_hi) & (dev_db < -1.0))[0]
if above.size and above[0] > 0:
    j = above[0]
    # linear interpolation in log(P) onto the -1 dB crossing
    p1db = 10 ** np.interp(-1.0, [dev_db[j], dev_db[j - 1]],
                           [np.log10(p_avail[j]), np.log10(p_avail[j - 1])])
else:
    p1db = float('nan')

# --- lower end of the usable range --------------------------------------
# Below some power the detected voltage is smaller than the HB solver's own
# residual and the points scatter off the square-law line. Take the lowest
# power from which every point up to the fit region stays within 1 dB of it.
below = np.where((p_avail < p_fit_lo) & ~(np.abs(dev_db) < 1.0))[0]
p_floor = p_avail[below[-1] + 1] if below.size else p_avail[0]
dyn_range_db = 10.0 * np.log10(p1db / p_floor) if np.isfinite(p1db) else float('nan')

# --- shooting PSS against HB at the same amplitudes -----------------------
# One pss analysis per amplitude in the testbench, each preceded by an alter
# of the source amplitude, so the pairing is read back out of the netlist.
pss_rows = []
pairs = re.findall(r'alter instance\("vin3"\) ampl=([\d.eEmu+\-]+)\s*\n\s*analysis (powdet_pss2\w*) pss',
                   netlist)
for a_txt, name in pairs:
    a = float(a_txt.replace('m', 'e-3').replace('u', 'e-6'))
    path = os.path.join(SIM_DIR, name + '.raw')
    if not os.path.isfile(path) or os.path.getsize(path) == 0:
        print(f'Note: {name}.raw is missing, the shooting PSS point at {a*1e3:g} mV is skipped.')
        continue
    pss = rawread(path).get()
    t = np.real(pss['time'])
    v = np.real(pss['out'])
    o = np.argsort(t)
    t, v = t[o], v[o]
    v_mean = float(np.trapezoid(v, t) / (t[-1] - t[0]))
    # HB reference at exactly this amplitude: log-log interpolation of the
    # usable part of the HB curve, so the check does not depend on where the
    # decade grid of the HB sweep happens to fall.
    p = a * a / (8.0 * RS)
    p_hb, dv_hb_abs = p_avail[usable], np.abs(dv[usable])
    if not (p_hb[0] <= p <= p_hb[-1]):
        continue
    dv_hb = np.sign(beta) * 10 ** np.interp(np.log10(p), np.log10(p_hb), np.log10(dv_hb_abs))
    pss_rows.append((a, v_mean - v_off, float(dv_hb)))
pss_rows.sort()
if not pairs:
    print('Note: no shooting PSS analyses in the netlist, the check is skipped.')

print(f'Variant               : {VARIANT or "as fabricated"}')
print(f'RF frequency          : {freq_rf/1e9:.1f} GHz')
print(f'Source resistance     : {RS:.0f} Ohm')
print(f'Output offset V_dc(0) : {v_off*1e3:.4f} mV  (fitted; OP analysis says '
      f'{v_op*1e3:.4f} mV, HB DC bin sits {(v_off-v_op)*1e9:+.1f} nV from it)')
print(f'Responsivity beta     : {beta:.4g} V/W  (fit over '
      f'{dbm(p_fit_lo):.1f} .. {dbm(p_fit_hi):.1f} dBm)')
print(f'1 dB compression      : {dbm(p1db):.2f} dBm' if np.isfinite(p1db)
      else '1 dB compression      : not reached in this sweep')
print(f'HB solver floor       : {dbm(p_floor):.1f} dBm (points below this scatter off '
      'the square-law line)')
print(f'Solver floor to P1dB  : {dyn_range_db:.1f} dB' if np.isfinite(dyn_range_db)
      else 'Solver floor to P1dB  : not bounded by this sweep')
print(f'Z_in at {freq_rf/1e9:.0f} GHz     : {z_in[0].real:.1f} {z_in[0].imag:+.1f}j Ohm '
      f'(small signal), {z_in[-1].real:.1f} {z_in[-1].imag:+.1f}j Ohm at '
      f'{dbm(p_avail[-1]):.1f} dBm')

pss_dev_max = None
if pss_rows:
    print()
    print('Shooting PSS against HB, detected voltage at equal source amplitude:')
    print(f'{"P_avail":>9} {"HB":>12} {"PSS":>12} {"PSS/HB":>8}')
    devs = []
    for a, dv_pss, dv_hb in pss_rows:
        ratio = dv_pss / dv_hb if dv_hb else float('nan')
        flag = '' if abs(dv_hb) > 100 * DV_FLOOR else '  (below the resolved range)'
        print(f'{dbm(a*a/(8*RS)):8.1f}dBm {dv_hb*1e3:10.5f}mV {dv_pss*1e3:10.5f}mV {ratio:8.4f}{flag}')
        if abs(dv_hb) > 100 * DV_FLOOR:
            devs.append(abs(ratio - 1.0))
    if devs:
        pss_dev_max = float(max(devs))
        print(f'  largest deviation over the resolved range: {100*pss_dev_max:.2f} %')

# --- plot ----------------------------------------------------------------
fig, (ax_tr, ax_beta, ax_z) = plt.subplots(3, 1, figsize=(8, 10), constrained_layout=True)
fig.suptitle(f'SBD Power Detector {VARIANT} - single-tone HB at {freq_rf/1e9:.0f} GHz, '
             f'shooting PSS as check')

ax_tr.loglog(p_avail[usable], np.abs(dv[usable]), 'o-', label='|detected voltage|, HB')
if pss_rows:
    ax_tr.loglog([a * a / (8 * RS) for a, _, _ in pss_rows], [abs(x) for _, x, _ in pss_rows],
                 'k+', ms=9, mew=1.5, label='shooting PSS')
ax_tr.loglog(p_avail, np.abs(beta) * p_avail, 'k--', alpha=0.5,
             label=f'square law, beta = {beta:.3g} V/W')
if np.isfinite(p1db):
    ax_tr.axvline(p1db, color='tab:red', ls=':', label=f'P(1 dB) = {dbm(p1db):.1f} dBm')
ax_tr.axvspan(p_avail[0] / 2, p_floor, color='tab:red', alpha=0.08, label='HB solver floor')
ax_tr.set_xlim(p_avail[0] / 2, p_avail[-1] * 2)
ax_tr.set_xlabel('Available input power (W)')
ax_tr.set_ylabel('|V_out - V_out(0)| (V)')
ax_tr.legend()
ax_tr.grid(True, which='both')

clean = usable & (p_avail >= p_floor)
ax_beta.semilogx(p_avail[clean], np.abs(dv[clean] / p_avail[clean]), 'o-')
ax_beta.axhline(abs(beta), color='k', ls='--', alpha=0.5)
ax_beta.axvspan(p_fit_lo, p_fit_hi, color='tab:green', alpha=0.12, label='fit region')
if np.isfinite(p1db):
    ax_beta.axvline(p1db, color='tab:red', ls=':', label=f'P(1 dB) = {dbm(p1db):.1f} dBm')
ax_beta.set_xlim(p_avail[0] / 2, p_avail[-1] * 2)
ax_beta.set_xlabel('Available input power (W)')
ax_beta.set_ylabel('Responsivity |beta| (V/W)')
ax_beta.legend()
ax_beta.grid(True, which='both')

ax_z.semilogx(p_avail, np.real(z_in), 'o-', label='Re(Z_in)')
ax_z.semilogx(p_avail, np.imag(z_in), 's-', label='Im(Z_in)')
ax_z.axhline(RS, color='k', ls='--', alpha=0.5, label=f'{RS:.0f} Ohm')
ax_z.set_xlabel('Available input power (W)')
ax_z.set_ylabel(f'Large-signal Z_in at {freq_rf/1e9:.0f} GHz (Ohm)')
ax_z.legend()
ax_z.grid(True, which='both')

os.makedirs(FIG_DIR, exist_ok=True)
plt.savefig(os.path.join(FIG_DIR, f'sparx_powdet_sbd_pss_sweep{SUFFIX}.png'), dpi=150)

# --- hand the responsivity and the curve to the noise-figure bench ---------
os.makedirs(DATA_DIR, exist_ok=True)
beta_file = os.path.join(DATA_DIR, f'sparx_powdet_sbd_beta{SUFFIX}.json')
with open(beta_file, 'w') as f:
    json.dump({
        'variant': VARIANT or 'm1',
        'beta_V_per_W': beta,
        'v_offset_V': v_off,
        'p_fit_lo_W': p_fit_lo,
        'p_fit_hi_W': p_fit_hi,
        'p_1db_W': None if not np.isfinite(p1db) else float(p1db),
        'p_floor_W': float(p_floor),
        'solver_floor_to_p1db_dB': None if not np.isfinite(dyn_range_db) else float(dyn_range_db),
        'z_in_small_signal_ohm': [float(z_in[0].real), float(z_in[0].imag)],
        'pss_vs_hb_max_deviation': pss_dev_max,
        # The whole transfer curve, so the NF testbench can take the local
        # slope dV/dP at the LO drive level instead of the small-signal beta.
        # A detector pumped near compression converts with its local slope.
        'p_avail_W': p_avail.tolist(),
        'v_detected_V': dv.tolist(),
        'freq_rf_Hz': freq_rf,
        'rs_ohm': RS,
        'source': TB,
    }, f, indent=2)
print(f'Wrote {beta_file}')

# --- CSV for pgfplots: the usable part of the curve and the square-law line
csv_file = os.path.join(DATA_DIR, f'sparx_powdet_sbd_pss{SUFFIX}.csv')
keep = usable & (p_avail >= p_floor)
np.savetxt(csv_file,
           np.column_stack((dbm(p_avail[keep]), np.abs(dv[keep]), np.abs(beta) * p_avail[keep],
                            np.abs(dv[keep] / p_avail[keep]), np.real(z_in[keep]), np.imag(z_in[keep]))),
           delimiter=',', header='pin_dbm,dv_v,squarelaw_v,beta_vw,zin_re,zin_im', comments='', fmt='%.6e')
print(f'Wrote {csv_file}')
if pss_rows:
    chk_file = os.path.join(DATA_DIR, f'sparx_powdet_sbd_pss_check{SUFFIX}.csv')
    np.savetxt(chk_file,
               np.array([(dbm(a * a / (8.0 * RS)), abs(dv_pss), abs(dv_hb)) for a, dv_pss, dv_hb in pss_rows]),
               delimiter=',', header='pin_dbm,dv_pss_v,dv_hb_v', comments='', fmt='%.6e')
    print(f'Wrote {chk_file}')

if SHOW_PLOTS:
    plt.show()
