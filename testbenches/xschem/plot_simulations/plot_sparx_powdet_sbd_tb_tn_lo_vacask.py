# SPDX-FileCopyrightText: 2026 The SPARX Team
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# Description: Noise figure of the SBD detector against LO power from four noise estimates, with the transient-noise ladder at five LO levels.

# TRANSIENT NOISE OF THE SBD POWER DETECTOR AGAINST LO DRIVE.
#
# The testbench runs the noisescale ladder of the TN bench at five LO levels.
# At each level the output PSD is split as in plot_sparx_powdet_sbd_tb_tn_vacask.py,
#
#   S_out(f, x) = a(f) * x + b(f) * x^2,     x = noisescale^2,
#
# from the two extreme rungs, and the linear term a is averaged over the
# band +-20 % around the 2 GHz IF of the NF bench's LO sweep. The levels are
# points of that sweep's grid, so the noise figure follows with the same
# hbac conversion in the denominator as hbnoise, pnoise and the small-signal
# noise at the dc operating point of that sweep:
#
#   F_tn = 1 + (F_hbnoise - 1) * S_tn / S_hbnoise
#
# which is 1 + S_tn / ((g_U + g_L) k T0) without restating the conversion.
# S_tn is the linear term less the source-resistor share of hbnoise, as in
# the TN script. Reads plot_simulations/data/sparx_powdet_sbd_nf<suffix>.json
# and the hbnoise LO sweep rawfile, so the NF testbench must run first.

from rawfile import rawread
import numpy as np
import os
import re
import json
import matplotlib
# Default to the non-interactive Agg backend: write the PNG, open no window.
# This is required under a VACASK postprocess, where a Qt window crashes VACASK's
# boost::asio loop ("Bad file descriptor"). To pop up the figure when running the
# script standalone, set the environment variable SHOW_PLOTS=1.
SHOW_PLOTS = os.environ.get('SHOW_PLOTS', '0') == '1'
if not SHOW_PLOTS:
    matplotlib.use('Agg')
import matplotlib.pyplot as plt

TB = 'sparx_powdet_sbd_tb_tn_lo_vacask'
NETLIST = TB + '.spectre'
VARIANT = os.environ.get('POWDET_VARIANT', '').strip()
SUFFIX = f'_{VARIANT}' if VARIANT else ''
RS = 50.0
F_IF = 2e9               # the IF of the NF bench's LO sweep (values=[2G])
BAND = 0.2               # relative half width of the band the linear term is averaged over
DISCARD_FRAC = 0.1       # drop this fraction of the record (op to tran settling)
DF_TARGET = 100e6        # Welch frequency resolution, sets the segment length
HBNOISE_LO = 'powdet_nf_hbnoise_lo.raw'
SOURCE_VEC = 'n(Rs)'


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
NF_FILE = os.path.join(DATA_DIR, f'sparx_powdet_sbd_nf{SUFFIX}.json')


def db(x):
    return 10.0 * np.log10(x)


def welch(t, v):
    """One-sided PSD of an unevenly sampled transient, Hann window, as in the TN script."""
    order = np.argsort(t)
    t, v = t[order], v[order]
    keep = t >= t[0] + DISCARD_FRAC * (t[-1] - t[0])
    t, v = t[keep], v[keep]
    t_u = np.linspace(t[0], t[-1], t.size)
    v_u = np.interp(t_u, t, v)
    fs = (t.size - 1) / (t_u[-1] - t_u[0])
    nper = 1 << int(round(np.log2(fs / DF_TARGET)))
    win = np.hanning(nper)
    acc, n = np.zeros(nper // 2 + 1), 0
    for s in range(0, v_u.size - nper + 1, nper // 2):
        seg = v_u[s:s + nper]
        acc += np.abs(np.fft.rfft((seg - seg.mean()) * win)) ** 2
        n += 1
    psd = acc / n / (fs * np.sum(win ** 2))
    psd[1:-1] *= 2.0
    return np.fft.rfftfreq(nper, 1.0 / fs), psd


def si(txt):
    return float(txt.replace('m', 'e-3').replace('u', 'e-6'))


# --- LO levels and their rungs, in netlist order ----------------------------
with open(os.path.join(SIM_DIR, NETLIST)) as fh:
    netlist = fh.read()
levels = []
for m in re.finditer(r'alter instance\("vin2"\) ampl=([\d.eE+\-mu]+)|'
                     r'analysis\s+(\w+)\s+tran\b[^\n]*?noisescale=([\d.eE+\-]+)', netlist):
    if m.group(1):
        levels.append({'ampl': si(m.group(1)), 'rungs': []})
    elif levels:
        levels[-1]['rungs'].append((m.group(2), float(m.group(3))))
if not levels:
    raise RuntimeError(f'No LO levels found in {NETLIST}.')

# --- references from the NF testbench's LO sweep -----------------------------
with open(NF_FILE) as fh:
    nf = json.load(fh)
lo = nf['nf_vs_plo']
p_grid = np.asarray(lo['p_lo_W'])
nf_hb = np.asarray(lo['nf_dsb_dB'])
nf_q = np.asarray(lo['nf_dsb_quiescent_dB'])
s_hb = np.asarray(lo['s_out_pumped_V2_per_Hz'])
shooting = nf.get('shooting_check')
nf_pn = np.asarray(shooting['nf_vs_plo_nf_dsb_pnoise_dB']) if shooting else None
s_src = np.zeros_like(p_grid)
path = os.path.join(SIM_DIR, HBNOISE_LO)
if os.path.isfile(path):
    h = rawread(path).get(sweeps=1)
    for gi in range(h.sweepGroups):
        sd = h.sweepData(gi)
        a = float(np.abs(sd[next(iter(sd))]))
        j = int(np.argmin(np.abs(p_grid / (a * a / (8 * RS)) - 1)))
        if SOURCE_VEC in h.names:
            s_src[j] = float(np.real(h[gi, SOURCE_VEC])[0])
else:
    print(f'Note: {HBNOISE_LO} is missing, the source-resistor share is not subtracted. '
          'It is below 1e-4 of the output noise here.')

# --- linear term at the IF, one LO level at a time ---------------------------
rows = []
for lv in levels:
    p = lv['ampl'] ** 2 / (8 * RS)
    j = int(np.argmin(np.abs(p_grid / p - 1)))
    if abs(p_grid[j] / p - 1) > 1e-4:
        raise RuntimeError(f'LO amplitude {lv["ampl"]:g} V is not on the LO sweep grid of the NF bench.')
    runs = []
    for name, ns in lv['rungs']:
        rp = os.path.join(SIM_DIR, name + '.raw')
        if not os.path.isfile(rp) or os.path.getsize(rp) == 0:
            print(f'Note: {name}.raw is missing, VACASK aborts a transient-noise run without '
                  'writing a rawfile and still exits 0.')
            continue
        tn = rawread(rp).get()
        f, psd = welch(np.real(tn['time']), np.real(tn['out']))
        runs.append((ns, f, psd))
    if len(runs) < 2:
        print(f'Note: fewer than two rungs at {db(p / 1e-3):.1f} dBm, the level is skipped.')
        continue
    runs.sort(key=lambda r: r[0])
    f = runs[0][1]
    S = np.vstack([np.interp(f, r[1], r[2]) for r in runs])
    x = np.array([r[0] ** 2 for r in runs])
    det = x[0] * x[-1] ** 2 - x[-1] * x[0] ** 2
    a_lin = np.clip((S[0] * x[-1] ** 2 - S[-1] * x[0] ** 2) / det, 0, None)
    band = (f > (1 - BAND) * F_IF) & (f < (1 + BAND) * F_IF)
    s_tn = max(float(np.mean(a_lin[band])) - s_src[j], 0.0)
    # Normalised band power per rung. A linear ladder gives one value, the
    # spread includes the Welch scatter of about 9 % in this band.
    norm = [float(np.mean(S[i][band])) / x[i] for i in range(len(runs))]
    nf_tn = float(db(1.0 + (10 ** (nf_hb[j] / 10) - 1.0) * s_tn / s_hb[j]))
    rows.append({'p_lo_W': float(p_grid[j]), 'nf_dsb_transient_dB': nf_tn,
                 'nf_dsb_hbnoise_dB': float(nf_hb[j]),
                 'nf_dsb_pnoise_dB': float(nf_pn[j]) if nf_pn is not None else float('nan'),
                 'nf_dsb_quiescent_dB': float(nf_q[j]),
                 'tn_over_hbnoise': s_tn / s_hb[j], 'rung_spread': max(norm) / min(norm) - 1.0})
# Levels are appended to the netlist as they are added, not in power order.
rows.sort(key=lambda r: r['p_lo_W'])

print(f'Variant              : {VARIANT or "as fabricated"}')
print(f'IF                    : {F_IF/1e9:g} GHz, linear term averaged over +-{100*BAND:.0f} %')
print()
print(f'{"P_LO":>8} {"TN":>7} {"hbnoise":>8} {"pnoise":>7} {"dc op.":>8} {"TN-hbn":>7} {"pn-hbn":>7} {"q-hbn":>7} {"rungs":>6}')
for r in rows:
    print(f'{db(r["p_lo_W"]/1e-3):6.1f}dBm {r["nf_dsb_transient_dB"]:7.2f} {r["nf_dsb_hbnoise_dB"]:8.2f} '
          f'{r["nf_dsb_pnoise_dB"]:7.2f} {r["nf_dsb_quiescent_dB"]:8.2f} '
          f'{r["nf_dsb_transient_dB"]-r["nf_dsb_hbnoise_dB"]:+7.2f} '
          f'{r["nf_dsb_pnoise_dB"]-r["nf_dsb_hbnoise_dB"]:+7.2f} '
          f'{r["nf_dsb_quiescent_dB"]-r["nf_dsb_hbnoise_dB"]:+7.2f} {100*r["rung_spread"]:5.1f}%')
d_tn = [r['nf_dsb_transient_dB'] - r['nf_dsb_hbnoise_dB'] for r in rows]
print(f'\nTransient against hbnoise over the LO levels: {min(d_tn):+.2f} to {max(d_tn):+.2f} dB')
if nf_pn is not None:
    d_pn = nf_pn - nf_hb
    print(f'pnoise against hbnoise over the whole LO sweep: {d_pn.min():+.2f} to {d_pn.max():+.2f} dB')
d_q = nf_q - nf_hb
print(f'Small-signal noise at the dc operating point against hbnoise over the whole LO sweep: {d_q.min():+.2f} to {d_q.max():+.2f} dB')

# --- figure: NF against LO drive from the four estimates, and their offsets --
p_dbm = db(p_grid / 1e-3)
r_dbm = np.array([db(r['p_lo_W'] / 1e-3) for r in rows])
r_tn = np.array([r['nf_dsb_transient_dB'] for r in rows])
fig, (ax, ax_d) = plt.subplots(2, 1, figsize=(8, 8), sharex=True, constrained_layout=True,
                               gridspec_kw={'height_ratios': [2, 1]})
fig.suptitle(f'SBD Power Detector {VARIANT} - Noise Figure at {F_IF/1e9:g} GHz IF against LO Drive, '
             'Four Noise Estimates')
ax.plot(p_dbm, nf_hb, 'k', lw=2, label='hbnoise with hbac, LO on')
if nf_pn is not None:
    ax.plot(p_dbm, nf_pn, 'o', color='k', mfc='none', label='pnoise with pac, around a shooting PSS')
ax.plot(r_dbm, r_tn, 'o', color='tab:blue', ms=7, label='transient noise, linear term of the ladder')
ax.plot(p_dbm, nf_q, 'k--', lw=1.5, label='small-signal noise at the dc operating point, LO off')
ax.set_ylabel('NF$_{DSB}$ (dB)')
ax.legend(fontsize=8)
ax.grid(True)
ax_d.axhline(0, color='k', lw=2)
if nf_pn is not None:
    ax_d.plot(p_dbm, nf_pn - nf_hb, 'o', color='k', mfc='none', label='pnoise')
ax_d.plot(r_dbm, r_tn - np.interp(r_dbm, p_dbm, nf_hb), 'o', color='tab:blue', ms=7, label='transient noise')
ax_d.plot(p_dbm, nf_q - nf_hb, 'k--', lw=1.5, label='small-signal noise at the dc operating point')
ax_d.set_xlabel('Available LO power (dBm)')
ax_d.set_ylabel('NF $-$ NF$_{hbnoise}$ (dB)')
ax_d.legend(fontsize=8)
ax_d.grid(True)
os.makedirs(FIG_DIR, exist_ok=True)
fig_file = os.path.join(FIG_DIR, f'sparx_powdet_sbd_nf_lo_compare{SUFFIX}.png')
plt.savefig(fig_file, dpi=150)
print(f'\nWrote {fig_file}')

# --- data ---------------------------------------------------------------------
os.makedirs(DATA_DIR, exist_ok=True)
with open(os.path.join(DATA_DIR, f'sparx_powdet_sbd_tn_lo{SUFFIX}.json'), 'w') as fh:
    json.dump({'variant': VARIANT or 'm1', 'f_if_Hz': F_IF, 'levels': rows,
               'tn_minus_hbnoise_dB': [min(d_tn), max(d_tn)],
               'pnoise_minus_hbnoise_dB': [float(d_pn.min()), float(d_pn.max())] if nf_pn is not None else None,
               'quiescent_minus_hbnoise_dB': [float(d_q.min()), float(d_q.max())],
               'source': TB}, fh, indent=2)
csv_file = os.path.join(DATA_DIR, f'sparx_powdet_sbd_tn_lo{SUFFIX}.csv')
np.savetxt(csv_file, np.array([[db(r['p_lo_W'] / 1e-3), r['nf_dsb_transient_dB'], r['nf_dsb_hbnoise_dB'],
                                r['nf_dsb_pnoise_dB'], r['nf_dsb_quiescent_dB'], r['tn_over_hbnoise'],
                                r['rung_spread']] for r in rows]),
           delimiter=',', comments='', fmt='%.6e',
           header='plo_dbm,nf_dsb_transient_db,nf_dsb_hbnoise_db,nf_dsb_pnoise_db,nf_dsb_quiescent_db,'
                  'tn_over_hbnoise,rung_spread')
print(f'Wrote {csv_file}')
if SHOW_PLOTS:
    plt.show()
