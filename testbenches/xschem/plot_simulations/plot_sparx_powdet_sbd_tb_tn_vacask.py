# SPDX-FileCopyrightText: 2025-2026 The SPARX Team
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# Description: Validate the SBD detector's small-signal noise in the linear limit of a transient-noise noisescale ladder.

# TRANSIENT NOISE OF THE SBD POWER DETECTOR.
#
# At full noise amplitude the transient-noise output of this detector comes
# out 3 to 8 times above the small-signal noise analysis. This script runs the
# same transient at several values of noisescale, which multiplies every
# device noise source amplitude, and splits the output PSD as
#
#   S_out(f, x) = a(f) * x + b(f) * x^2,     x = noisescale^2
#
# a(f) is the linear term. It must reproduce the small-signal noise analysis
# from the NF testbench, and it does, to within 12 % at 0.3, 1 and 3 GHz.
# That is the validation that the transient-noise setup (SDE mode, the rsw
# workaround, the LTE floor) is sound.
#
# b(f) is the excess, and it is NOT the detector rectifying its own noise,
# although that was the first reading of it. Two things rule that out:
#
#   size    Rectified Gaussian noise has a known magnitude. With the junction
#           curvature k = I0 / (2 n^2 V_T^2) = 0.020 A/V^2 (I0 = 30 uA) and
#           the white sources putting 0.36 mV RMS across the junction in the
#           20 GHz noise bandwidth, the rectified term is 2 k^2 S_v^2 B,
#           which is 2.6e-14 A/rtHz at the TIA input and 2.4e-11 V/rtHz at
#           the output. The observed excess at 1 GHz is 1.9e-8 V/rtHz, 770
#           times larger, 58 dB in power.
#   order   Rectified Gaussian noise is exactly second order in the noise
#           amplitude, so the excess would scale as x^2 and the middle rung
#           of the ladder would fall on the a x + b x^2 line through the outer
#           two. It falls 2 to 3 dB below it, so the excess grows faster than
#           second order between the upper rungs. The script prints the
#           apparent order.
#
# Single devices (a resistor, a PSP103 MOSFET, a schottky_nbl1 diode) show no
# excess with the same settings, and the excess grows with noisefmax without
# converging (6.3, 8.4, 7.7, 9.5, 11.4 times the linear ASD at 1 GHz for
# 10, 20, 50, 100 and 200 GHz). The working conclusion is a numerical
# artefact of transient noise on this stiff, strongly nonlinear circuit,
# mechanism not identified. Until it is, treat the full-amplitude transient
# noise of this detector as unusable and this bench as a linear-limit check
# of the small-signal analysis. It is deliberately not part of sim-all.

from rawfile import rawread
import numpy as np
import os
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

# The testbench runs one analysis per noisescale rather than sweeping it: a
# transient-noise run that aborts writes no rawfile, so one failing rung of a
# sweep costs every other rung too. The values are read back out of the
# netlist so they stay defined in one place.
NETLIST = 'sparx_powdet_sbd_tb_tn_vacask.spectre'
# POWDET_VARIANT selects a design variant run by the Makefile (m16, m1_pex).
VARIANT = os.environ.get('POWDET_VARIANT', '').strip()
SUFFIX = f'_{VARIANT}' if VARIANT else ''
ANALYSIS_RE = r'analysis\s+(\w+)\s+tran\b[^\n]*?noisescale=([\d.eE+\-]+)'
# Small-signal reference written by the noise-figure testbench. Optional: if it
# is missing the script still runs, it just cannot cross-check the linear term.
REF_NAME = 'powdet_nf_noise.raw'
DISCARD_FRAC = 0.05      # drop this fraction of the record (op to tran settling)
N_SEGMENTS = 12          # Welch segments, sets the frequency resolution
# Frequencies the summary table reports.
REPORT_F = (3e8, 1e9, 3e9)


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
FIG_DIR = os.path.join(DESIGN_ROOT, 'testbenches', 'xschem', 'plot_simulations', 'figures')


def welch(t, v):
    """One-sided PSD of an unevenly sampled transient, Hann window, numpy only."""
    order = np.argsort(t)
    t, v = t[order], v[order]
    keep = t >= t[0] + DISCARD_FRAC * (t[-1] - t[0])
    t, v = t[keep], v[keep]
    # The integrator uses an adaptive step, so resample onto a uniform grid at
    # the same average rate before transforming.
    t_u = np.linspace(t[0], t[-1], t.size)
    v_u = np.interp(t_u, t, v)
    fs = (t.size - 1) / (t_u[-1] - t_u[0])
    nper = 1 << int(np.log2(max(256, t.size // N_SEGMENTS)))
    win = np.hanning(nper)
    wnorm = np.sum(win ** 2)
    acc = np.zeros(nper // 2 + 1)
    n = 0
    for s in range(0, v_u.size - nper + 1, nper // 2):
        seg = v_u[s:s + nper]
        acc += np.abs(np.fft.rfft((seg - seg.mean()) * win)) ** 2
        n += 1
    psd = acc / n / (fs * wnorm)
    psd[1:-1] *= 2.0
    return np.fft.rfftfreq(nper, 1.0 / fs), psd, fs, t.size


with open(os.path.join(SIM_DIR, NETLIST)) as fh:
    netlist = fh.read()
analyses = re.findall(ANALYSIS_RE, netlist)
# Above noisefmax no noise is injected, so the spectrum there is the
# integrator's own residual and carries nothing. Plot up to it, no further.
_m = re.search(r'noisefmax=([\d.eE+\-]+)([GMKkT]?)', netlist)
FMAX = float(_m.group(1)) * {'': 1, 'k': 1e3, 'K': 1e3,
                             'M': 1e6, 'G': 1e9, 'T': 1e12}[_m.group(2)]
if not analyses:
    raise RuntimeError(f'No transient-noise analyses found in {NETLIST}.')

runs, missing = [], []
for name, ns in analyses:
    path = os.path.join(SIM_DIR, name + '.raw')
    if not os.path.isfile(path) or os.path.getsize(path) == 0:
        missing.append((name, ns))
        continue
    tn = rawread(path).get()
    f, psd, fs, npts = welch(np.real(tn['time']), np.real(tn['out']))
    runs.append({'ns': float(ns), 'f': f, 'psd': psd, 'fs': fs, 'npts': npts})
runs.sort(key=lambda r: r['ns'])
for name, ns in missing:
    print(f'Note: {name}.raw is missing, so noisescale = {ns} is not in the fit. '
          'VACASK aborts a transient-noise run without writing a rawfile and still '
          'exits 0, so check the transcript for "Timestep too small".')
if len(runs) < 2:
    raise RuntimeError(f'Need at least 2 noisescale points to separate the linear and '
                       f'rectified terms, {len(runs)} produced a rawfile.')

# Each run sees a different noise realisation, so the adaptive integrator
# accepts a slightly different number of timepoints and the Welch grids differ
# by a fraction of a percent. Put them on the first run's grid.
f = runs[0]['f']
if max(abs(r['f'][-1] / f[-1] - 1.0) for r in runs) > 0.05:
    raise RuntimeError('The runs produced very different sample rates. '
                       'They must share stop, maxstep and noisefmax.')
for r in runs[1:]:
    r['psd'] = np.interp(f, r['f'], r['psd'])

# --- solve S(f, x) = a*x + b*x^2 with x = noisescale^2 -------------------
# Two unknowns, so use the two extreme scales and solve exactly. A least
# squares fit over all of them is wrong here: it is dominated by the largest
# scale, where the rectified term is the whole signal, and it then pushes the
# linear term to whatever makes that point fit. The lowest scale is where the
# rectified term is negligible, so it is the one that pins a(f), and the
# highest is the one that pins b(f). Intermediate scales become a check.
x = np.array([r['ns'] ** 2 for r in runs])
S = np.vstack([r['psd'] for r in runs])              # [scale, frequency]
xlo, xhi = x[0], x[-1]
det = xlo * xhi ** 2 - xhi * xlo ** 2
a_lin = (S[0] * xhi ** 2 - S[-1] * xlo ** 2) / det
b_rect = (S[-1] * xlo - S[0] * xhi) / det
a_lin = np.clip(a_lin, 0, None)
b_rect = np.clip(b_rect, 0, None)


def model(xv):
    return a_lin * xv + b_rect * xv ** 2

# --- small-signal reference, if the NF testbench has been run ------------
ref_path = os.path.join(SIM_DIR, REF_NAME)
ref_f = ref_s = None
if os.path.isfile(ref_path):
    ref = rawread(ref_path).get()
    ref_f = np.real(ref['frequency'])
    ref_s = np.real(ref['onoise'])
else:
    print(f'Note: {REF_NAME} is missing, so the linear term cannot be checked against '
          'the small-signal analysis. Run the NF testbench first '
          '(make sim-xschem TB=sparx_powdet_sbd_tb_nf_vacask).')


def band_mean(arr, f0, rel=0.2):
    m = (f > (1 - rel) * f0) & (f < (1 + rel) * f0)
    return float(np.mean(arr[m])) if m.any() else float('nan')


print(f'Records               : {runs[0]["npts"]} points, fs = {runs[0]["fs"]:.3e} Hz, '
      f'df = {f[1]:.3e} Hz')
print(f'noisescale points     : ' + ', '.join(f'{r["ns"]:g}' for r in runs))
print()
hdr = f'{"f [Hz]":>10} {"linear ASD":>12} {"small-signal":>12} {"ratio":>7} ' \
      f'{"total at ns=1":>14} {"excess":>8}'
print(hdr)
print(f'{"":>10} {"[V/rtHz]":>12} {"[V/rtHz]":>12} {"":>7} {"[V/rtHz]":>14} {"[x]":>8}')
for f0 in REPORT_F:
    lin = np.sqrt(band_mean(a_lin, f0))
    tot = np.sqrt(band_mean(S[-1], f0))
    if ref_s is not None:
        j = int(np.argmin(np.abs(ref_f - f0)))
        ref_asd = float(np.sqrt(ref_s[j]))
        ratio = f'{lin / ref_asd:7.3f}'
    else:
        ref_asd, ratio = float('nan'), f'{"n/a":>7}'
    print(f'{f0:10.2e} {lin:12.4e} {ref_asd:12.4e} {ratio} {tot:14.4e} {tot/lin:8.2f}')

print()
print('The "ratio" column is the validation: the linear term of the transient-noise')
print('split against the small-signal noise analysis, and it should be near 1.')
print('The "excess" column is what a raw transient-noise run reports on top of it.')
print('It is not physical rectified noise, see the header, and it depends on the')
print('noise settings. Do not quote it.')

if len(runs) > 2:
    print()
    print('Order of the excess between the middle and top rungs, from the excess')
    print('S - a*x at each. Rectified Gaussian noise is exactly 2. Anything well')
    print('above 2 is not rectification.')
    for r in runs[1:-1]:
        x_mid, x_top = r['ns'] ** 2, x[-1]
        line = []
        for f0 in REPORT_F:
            e_mid = band_mean(r['psd'], f0) - band_mean(a_lin, f0) * x_mid
            e_top = band_mean(S[-1], f0) - band_mean(a_lin, f0) * x_top
            if e_mid > 0 and e_top > 0:
                order = np.log(e_top / e_mid) / np.log(x_top / x_mid)
                line.append(f'{f0/1e9:.1f} GHz {order:.1f}')
            else:
                line.append(f'{f0/1e9:.1f} GHz n/a (no excess at the middle rung)')
        print(f'  from noisescale {r["ns"]:g} to {runs[-1]["ns"]:g}:   ' + '   '.join(line))

def band_ylim(ax, arrays):
    """Fit the y range to what is actually inside the plotted x range."""
    band = (f >= f[1]) & (f <= FMAX)
    vals = np.concatenate([np.sqrt(a[band]) for a in arrays])
    vals = vals[np.isfinite(vals) & (vals > 0)]
    if vals.size:
        ax.set_ylim(vals.min() / 3, vals.max() * 3)

# --- plot ----------------------------------------------------------------
fig, (ax_raw, ax_split) = plt.subplots(2, 1, figsize=(8, 9), constrained_layout=True)
fig.suptitle('SBD Power Detector - Transient Noise, Linear and Rectified Terms')

sl = slice(1, None)
for r in runs:
    # r['psd'] is on the common grid f after the interpolation above.
    ax_raw.loglog(f[sl], np.sqrt(r['psd'][sl]) / r['ns'], lw=1, alpha=0.8,
                  label=f'noisescale = {r["ns"]:g}')
if ref_s is not None:
    ax_raw.loglog(ref_f, np.sqrt(ref_s), 'k--', lw=2, label='small-signal noise')
ax_raw.set_xlim(f[1], FMAX)
band_ylim(ax_raw, [r['psd'] / r['ns'] ** 2 for r in runs])
ax_raw.set_xlabel('Frequency (Hz)')
ax_raw.set_ylabel('Output ASD / noisescale (V/$\\sqrt{\\mathrm{Hz}}$)')
ax_raw.set_title('Normalised by noisescale: a purely linear circuit would collapse '
                 'onto one curve', fontsize=9)
ax_raw.legend(fontsize=8)
ax_raw.grid(True, which='both')

ax_split.loglog(f[sl], np.sqrt(a_lin[sl]), label='linear term $\\sqrt{a}$')
# b is clipped at zero, so hide the bins where the split found none rather
# than drawing a solid block of downward spikes.
b_plot = np.where(b_rect > 0, b_rect, np.nan)
ax_split.loglog(f[sl], np.sqrt(b_plot[sl]), label='rectified term $\\sqrt{b}$ at noisescale = 1')
ax_split.loglog(f[sl], np.sqrt(S[-1][sl]), 'k', lw=1, alpha=0.5, label='total at noisescale = 1')
if ref_s is not None:
    ax_split.loglog(ref_f, np.sqrt(ref_s), 'k--', lw=2, label='small-signal noise')
ax_split.set_xlim(f[1], FMAX)
band_ylim(ax_split, [a_lin, b_rect, S[-1]])
ax_split.set_xlabel('Frequency (Hz)')
ax_split.set_ylabel('Output noise ASD (V/$\\sqrt{\\mathrm{Hz}}$)')
ax_split.legend(fontsize=8)
ax_split.grid(True, which='both')

os.makedirs(FIG_DIR, exist_ok=True)
plt.savefig(os.path.join(FIG_DIR, f'sparx_powdet_sbd_tn{SUFFIX}.png'), dpi=150)
print(f'\nWrote {os.path.join(FIG_DIR, f"sparx_powdet_sbd_tn{SUFFIX}.png")}')

if SHOW_PLOTS:
    plt.show()
