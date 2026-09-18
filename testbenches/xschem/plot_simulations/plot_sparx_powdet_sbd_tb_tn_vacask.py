# SPDX-FileCopyrightText: 2025-2026 The SPARX Team
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# Description: Check hbnoise (or the quiescent noise analysis) of the SBD detector against the linear limit of a transient-noise noisescale ladder, and the noise figure from all three.

# TRANSIENT NOISE OF THE SBD POWER DETECTOR.
#
# The testbench runs the same LO-pumped transient at several values of
# noisescale, which multiplies every device noise source amplitude, and this
# script splits the output PSD as
#
#   S_out(f, x) = a(f) * x + b(f) * x^2,     x = noisescale^2
#
# a(f) is the linear term, the noise a small-signal analysis describes. With
# the LO on it must reproduce hbnoise from the NF testbench, with ampl_lo=0
# in the netlist it must reproduce the quiescent noise analysis instead. That
# agreement is the validation of both the transient-noise setup and the
# periodic noise analysis, since the two share no code path.
#
# b(f) is whatever is not linear. Rectified Gaussian noise would be there, it
# is exactly second order in the noise amplitude and its size follows from the
# junction curvature, 2.4e-11 V/rtHz at the output for this detector. What the
# transient shows instead is orders of magnitude larger, grows faster than
# second order between rungs, grows with noisefmax without converging, and is
# absent on single devices with the same settings. The working conclusion is a
# numerical artefact of SDE transient noise on this stiff, strongly nonlinear
# circuit. The ladder therefore stays at small noisescale, where the top rung
# is only mildly contaminated, and the script prints the apparent order of the
# excess so a change in that behaviour is visible. Do not quote the total at
# any rung as a noise level.
#
# The noise figure is then computed from the linear term with the same
# conversion the NF testbench uses, so the three noise estimates, transient,
# hbnoise and quiescent, can be compared on one number.

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

K_B = 1.380649e-23
T0 = 290.0
TB = 'sparx_powdet_sbd_tb_tn_vacask'
NETLIST = TB + '.spectre'
# POWDET_VARIANT selects a design variant run by the Makefile (m16, m1_pex).
VARIANT = os.environ.get('POWDET_VARIANT', '').strip()
SUFFIX = f'_{VARIANT}' if VARIANT else ''
# The testbench runs one analysis per noisescale rather than sweeping it: a
# transient-noise run that aborts writes no rawfile, so one failing rung of a
# sweep costs every other rung too. The values are read back out of the
# netlist so they stay defined in one place.
ANALYSIS_RE = r'analysis\s+(\w+)\s+tran\b[^\n]*?noisescale=([\d.eE+\-]+)'
# References written by the noise-figure testbench, in the same directory.
REF_PUMPED = 'powdet_nf_hbnoise_usb.raw'
REF_QUIESCENT = 'powdet_nf_noise.raw'
SOURCE_RES = 'Rs'
DISCARD_FRAC = 0.1       # drop this fraction of the record (op to tran settling)
DF_TARGET = 100e6        # Welch frequency resolution, sets the segment length
# Frequencies the summary table reports, all well inside the resolution and
# below noisefmax.
REPORT_F = (5e8, 1e9, 2e9, 3e9)


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


def parse_var(netlist, name):
    m = re.search(rf'var\s+{name}\s*=\s*([\d.eE+\-]+[GMKkTmu]?)', netlist)
    val = m.group(1)
    for suf, exp in (('G', 'e9'), ('M', 'e6'), ('K', 'e3'), ('k', 'e3'),
                     ('T', 'e12'), ('m', 'e-3'), ('u', 'e-6')):
        val = val.replace(suf, exp)
    return float(val)


def db(x):
    return 10.0 * np.log10(x)


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
    nper = 1 << int(round(np.log2(fs / DF_TARGET)))
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
    return np.fft.rfftfreq(nper, 1.0 / fs), psd, fs, t.size, n


with open(os.path.join(SIM_DIR, NETLIST)) as fh:
    netlist = fh.read()
analyses = re.findall(ANALYSIS_RE, netlist)
ampl_lo = parse_var(netlist, 'ampl_lo')
pumped = ampl_lo > 0
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
    f, psd, fs, npts, nseg = welch(np.real(tn['time']), np.real(tn['out']))
    runs.append({'ns': float(ns), 'f': f, 'psd': psd, 'fs': fs, 'npts': npts, 'nseg': nseg})
runs.sort(key=lambda r: r['ns'])
for name, ns in missing:
    print(f'Note: {name}.raw is missing, so noisescale = {ns} is not in the fit. '
          'VACASK aborts a transient-noise run without writing a rawfile and still '
          'exits 0, so check the transcript for "Timestep too small".')
if len(runs) < 2:
    raise RuntimeError(f'Need at least 2 noisescale points to separate the linear and '
                       f'excess terms, {len(runs)} produced a rawfile.')

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
# scale, where the excess is largest, and it then pushes the linear term to
# whatever makes that point fit. The lowest scale pins a(f), the highest pins
# b(f), and the scales in between become the check.
x = np.array([r['ns'] ** 2 for r in runs])
S = np.vstack([r['psd'] for r in runs])              # [scale, frequency]
xlo, xhi = x[0], x[-1]
det = xlo * xhi ** 2 - xhi * xlo ** 2
a_lin = (S[0] * xhi ** 2 - S[-1] * xlo ** 2) / det
b_exc = (S[-1] * xlo - S[0] * xhi) / det
a_lin = np.clip(a_lin, 0, None)
b_exc = np.clip(b_exc, 0, None)

# --- references from the NF testbench ---------------------------------------
def load_ref(name):
    path = os.path.join(SIM_DIR, name)
    if not os.path.isfile(path):
        return None, None, None
    r = rawread(path).get()
    fr = np.real(r['frequency'])
    src = f'n({SOURCE_RES})'
    s_src = np.real(r[src]) if src in r.names else np.zeros(fr.size)
    return fr, np.real(r['onoise']), s_src


ref_f_p, ref_s_p, ref_src_p = load_ref(REF_PUMPED)
ref_f_q, ref_s_q, _ = load_ref(REF_QUIESCENT)
ref_f, ref_s = (ref_f_p, ref_s_p) if pumped else (ref_f_q, ref_s_q)
ref_label = 'hbnoise, LO on' if pumped else 'noise, LO off'
if ref_s is None:
    print(f'Note: {REF_PUMPED if pumped else REF_QUIESCENT} is missing, so the linear term '
          'cannot be checked. Run the NF testbench first '
          '(make sim-xschem TB=sparx_powdet_sbd_tb_nf_vacask).')


def band_mean(arr, f0, rel=0.2):
    m = (f > (1 - rel) * f0) & (f < (1 + rel) * f0)
    return float(np.mean(arr[m])) if m.any() else float('nan')


def ref_at(fr, sr, f0):
    return float(np.interp(f0, fr, sr)) if sr is not None else float('nan')


print(f'LO                    : {"on, " + f"{ampl_lo*1e3:.0f} mV" if pumped else "off"}, '
      f'reference is {ref_label}')
print(f'Records               : {runs[0]["npts"]} points, fs = {runs[0]["fs"]:.3e} Hz, '
      f'{runs[0]["nseg"]} Welch segments, df = {f[1]:.3e} Hz')
print(f'noisescale points     : ' + ', '.join(f'{r["ns"]:g}' for r in runs))
print()
print(f'{"f [Hz]":>8} {"linear ASD":>11} {ref_label:>15} {"ratio":>6} {"noise, LO off":>13} {"ratio":>6} '
      f'{"top rung/ns":>11} {"excess":>7}')
print(f'{"":>8} {"[V/rtHz]":>11} {"[V/rtHz]":>15} {"":>6} {"[V/rtHz]":>13} {"":>6} {"[V/rtHz]":>11} {"[x]":>7}')
rows = []
for f0 in REPORT_F:
    lin = np.sqrt(band_mean(a_lin, f0))
    r_asd = np.sqrt(ref_at(ref_f, ref_s, f0))
    q_asd = np.sqrt(ref_at(ref_f_q, ref_s_q, f0))
    tot = np.sqrt(band_mean(S[-1], f0)) / runs[-1]['ns']
    rows.append({'f_Hz': f0, 'asd_linear_V': lin, 'asd_ref_V': r_asd, 'asd_quiescent_V': q_asd,
                 'asd_top_rung_normalised_V': tot})
    print(f'{f0:8.1e} {lin:11.3e} {r_asd:15.3e} {lin/r_asd:6.3f} {q_asd:13.3e} {lin/q_asd:6.3f} '
          f'{tot:11.3e} {tot/lin:7.2f}')
print()
print('"ratio" is the linear term of the transient-noise split against the small-signal')
print('reference and should be near 1. "excess" is what the top rung, normalised by its')
print('noisescale, reports on top of it.')
print('It is not physical rectified noise, see the header, and it depends on the noise')
print('settings. Do not quote it.')

print()
print('Normalised ASD per rung, sqrt(S)/noisescale at 1 GHz. A purely linear circuit')
print('gives one value on every rung:')
for r in runs:
    print(f'  noisescale {r["ns"]:<6g} {np.sqrt(band_mean(r["psd"], 1e9))/r["ns"]:.3e} V/rtHz')

if len(runs) > 2:
    print()
    print('Order of the excess between the middle and top rungs, from S - a*x at each.')
    print('Rectified Gaussian noise is exactly 2. Anything well above 2 is not rectification.')
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

# --- noise figure from the three noise estimates -----------------------------
nf_rows = []
if pumped and os.path.isfile(NF_FILE) and ref_s_p is not None:
    with open(NF_FILE) as fh:
        nf = json.load(fh)
    f_nf = np.asarray(nf['f_Hz'])
    g_sum = np.asarray(nf['g_usb_V2_per_W']) + np.asarray(nf['g_lsb_V2_per_W'])
    print()
    print(f'Double-sideband noise figure at {nf["p_lo_avail_W"]*1e3:.3g} mW LO from the three noise')
    print('estimates, with the hbac conversion of the NF testbench in the denominator. The')
    print('transient value uses the linear term of the ladder less the source resistor share')
    print('of the hbnoise result.')
    print(f'{"f_IF [Hz]":>10} {"transient":>10} {"hbnoise":>9} {"quiescent":>10}')
    for row in rows:
        f0 = row['f_Hz']
        g = float(np.interp(f0, f_nf, g_sum))
        s_src = float(np.interp(f0, ref_f_p, ref_src_p))
        s_tn = max(row['asd_linear_V'] ** 2 - s_src, 0.0)
        nf_tn = float(db(1.0 + s_tn / (g * K_B * T0)))
        nf_hbn = float(np.interp(f0, f_nf, nf['nf_dsb_dB']))
        nf_q = float(np.interp(f0, f_nf, nf['nf_dsb_quiescent_dB']))
        row.update({'nf_dsb_transient_dB': nf_tn, 'nf_dsb_hbnoise_dB': nf_hbn,
                    'nf_dsb_quiescent_dB': nf_q})
        print(f'{f0:10.1e} {nf_tn:10.2f} {nf_hbn:9.2f} {nf_q:10.2f}')
    # The same, bin by bin over the Welch grid, for the comparison figure. The
    # lowest bins are left out, they are one resolution step from DC.
    m_c = (f >= 2 * f[1]) & (f <= min(FMAX, f_nf[-1]))
    f_c = f[m_c]
    s_c = np.clip(a_lin[m_c] - np.interp(f_c, ref_f_p, ref_src_p), 0, None)
    nf_curve = {
        'f_Hz': f_c,
        'transient': db(1.0 + s_c / (np.interp(f_c, f_nf, g_sum) * K_B * T0)),
        'hbnoise': np.interp(f_c, f_nf, nf['nf_dsb_dB']),
        'quiescent': np.interp(f_c, f_nf, nf['nf_dsb_quiescent_dB']),
        'f_nf': f_nf,
        'nf_hbnoise_full': np.asarray(nf['nf_dsb_dB']),
        'nf_quiescent_full': np.asarray(nf['nf_dsb_quiescent_dB']),
        'p_lo_W': float(nf['p_lo_avail_W']),
    }
elif pumped:
    print(f'\nNote: {NF_FILE} is missing, no noise figure from the transient. Run the NF '
          'testbench first.')


def band_ylim(ax, arrays):
    """Fit the y range to what is actually inside the plotted x range."""
    band = (f >= f[1]) & (f <= FMAX)
    vals = np.concatenate([np.sqrt(a[band]) for a in arrays])
    vals = vals[np.isfinite(vals) & (vals > 0)]
    if vals.size:
        ax.set_ylim(vals.min() / 3, vals.max() * 3)


# --- plot ----------------------------------------------------------------
fig, (ax_raw, ax_split) = plt.subplots(2, 1, figsize=(8, 9), constrained_layout=True)
fig.suptitle(f'SBD Power Detector {VARIANT} - Transient Noise, LO {"on" if pumped else "off"}, '
             'Linear Term Against the Small-Signal Analyses')

sl = slice(1, None)
for r in runs:
    ax_raw.loglog(f[sl], np.sqrt(r['psd'][sl]) / r['ns'], lw=1, alpha=0.8,
                  label=f'noisescale = {r["ns"]:g}')
if ref_s_p is not None:
    ax_raw.loglog(ref_f_p, np.sqrt(ref_s_p), 'k', lw=2, label='hbnoise, LO on')
if ref_s_q is not None:
    ax_raw.loglog(ref_f_q, np.sqrt(ref_s_q), 'k--', lw=1.5, label='noise, LO off')
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
b_plot = np.where(b_exc > 0, b_exc, np.nan)
ax_split.loglog(f[sl], np.sqrt(b_plot[sl] * xhi ** 2), label=f'excess $\\sqrt{{b x^2}}$ at noisescale = {runs[-1]["ns"]:g}')
ax_split.loglog(f[sl], np.sqrt(S[-1][sl]), color='tab:gray', lw=1, alpha=0.7,
                label=f'total at noisescale = {runs[-1]["ns"]:g}')
if ref_s_p is not None:
    ax_split.loglog(ref_f_p, np.sqrt(ref_s_p), 'k', lw=2, label='hbnoise, LO on')
if ref_s_q is not None:
    ax_split.loglog(ref_f_q, np.sqrt(ref_s_q), 'k--', lw=1.5, label='noise, LO off')
ax_split.set_xlim(f[1], FMAX)
band_ylim(ax_split, [a_lin, b_exc * xhi ** 2, S[-1]])
ax_split.set_xlabel('Frequency (Hz)')
ax_split.set_ylabel('Output noise ASD (V/$\\sqrt{\\mathrm{Hz}}$)')
ax_split.legend(fontsize=8)
ax_split.grid(True, which='both')

os.makedirs(FIG_DIR, exist_ok=True)
fig_file = os.path.join(FIG_DIR, f'sparx_powdet_sbd_tn{SUFFIX}.png')
plt.savefig(fig_file, dpi=150)
print(f'\nWrote {fig_file}')

# --- the noise figure from the three noise estimates, in one figure --------
if nf_rows is not None and 'nf_curve' in globals():
    fig2, axes2 = plt.subplots(1, 2, figsize=(13, 5), constrained_layout=True)
    p_lo_dbm = 10 * np.log10(nf_curve['p_lo_W'] / 1e-3)
    fig2.suptitle(f'SBD Power Detector {VARIANT} - Noise Figure from Three Noise Estimates '
                  f'(LO {p_lo_dbm:.1f} dBm)')
    for ax, lo_x, title in ((axes2[0], 1e3, 'full IF range'),
                            (axes2[1], 1e8, 'where the transient ladder resolves it')):
        ax.semilogx(nf_curve['f_nf'], nf_curve['nf_hbnoise_full'], 'k', lw=2,
                    label='hbnoise, LO on')
        ax.semilogx(nf_curve['f_nf'], nf_curve['nf_quiescent_full'], 'k--', lw=1.5,
                    label='small-signal noise at the operating point, LO off')
        ax.semilogx(nf_curve['f_Hz'], nf_curve['transient'], color='tab:blue', lw=1, alpha=0.7,
                    label='transient noise, linear term of the ladder, LO on')
        ax.semilogx([r['f_Hz'] for r in rows], [r['nf_dsb_transient_dB'] for r in rows], 'o',
                    color='tab:blue', label='transient, band mean at the reported IFs')
        ax.set_xlim(lo_x, FMAX / 4)
        if lo_x > 1e3:
            m = nf_curve['f_nf'] >= lo_x
            ax.set_ylim(nf_curve['nf_quiescent_full'][m].min() - 2,
                        nf_curve['nf_hbnoise_full'][m].max() + 2)
        ax.set_xlabel('IF frequency (Hz)')
        ax.set_ylabel('NF$_{DSB}$ (dB)')
        ax.set_title(title, fontsize=10)
        ax.legend(fontsize=8)
        ax.grid(True, which='both')
    fig2_file = os.path.join(FIG_DIR, f'sparx_powdet_sbd_nf_compare{SUFFIX}.png')
    fig2.savefig(fig2_file, dpi=150)
    print(f'Wrote {fig2_file}')
    csv2 = os.path.join(DATA_DIR, f'sparx_powdet_sbd_nf_compare{SUFFIX}.csv')
    os.makedirs(DATA_DIR, exist_ok=True)
    np.savetxt(csv2, np.column_stack((nf_curve['f_Hz'], nf_curve['transient'],
                                      nf_curve['hbnoise'], nf_curve['quiescent'])),
               delimiter=',', comments='', fmt='%.6e',
               header='f_hz,nf_dsb_transient_db,nf_dsb_hbnoise_db,nf_dsb_quiescent_db')
    print(f'Wrote {csv2}')

os.makedirs(DATA_DIR, exist_ok=True)
out_file = os.path.join(DATA_DIR, f'sparx_powdet_sbd_tn{SUFFIX}.json')
with open(out_file, 'w') as fh:
    json.dump({
        'variant': VARIANT or 'm1',
        'ampl_lo_V': ampl_lo,
        'reference': ref_label,
        'noisescale': [r['ns'] for r in runs],
        'df_Hz': float(f[1]),
        'rows': rows,
        'source': TB,
    }, fh, indent=2)
csv_file = os.path.join(DATA_DIR, f'sparx_powdet_sbd_tn{SUFFIX}.csv')
band = (f >= f[1]) & (f <= FMAX)
np.savetxt(csv_file, np.column_stack((f[band], np.sqrt(a_lin[band]), np.sqrt(S[-1][band]))),
           delimiter=',', comments='', fmt='%.6e',
           header='f_hz,asd_linear_v,asd_top_rung_v')
print(f'Wrote {out_file}\nWrote {csv_file}')

if SHOW_PLOTS:
    plt.show()
