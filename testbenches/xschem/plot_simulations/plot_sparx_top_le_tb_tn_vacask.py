# SPDX-FileCopyrightText: 2026 The SPARX Team
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# Description: Transient-noise ladder of the six-port receiver against hbnoise, and its noise figure next to hbnoise, pnoise and the noise at the dc operating point.

# TRANSIENT NOISE OF THE SIX-PORT RECEIVER.
#
# The method of plot_sparx_powdet_sbd_tb_tn_vacask.py, applied to the four
# detector outputs of sparx_top_le_tb_tn_vacask and to the I and Q outputs
# formed from them (I = out2 - out1, Q = out4 - out3, sample by sample). The
# bench runs the LO-pumped transient at three values of noisescale, and the
# output PSD of each output is split as
#
#   S_out(f, x) = a(f) * x + b(f) * x^2,     x = noisescale^2
#
# from the two extreme rungs. The linear term a(f) must reproduce hbnoise of
# the NF bench, whose rawfiles this script reads from the same directory. The
# excess b(f) is the numerical artefact the detector bench documents, so the
# ladder stays at noisescale 0.1 and below and the total is never quoted.
#
# The noise figure follows from the linear term with the conversion of the NF
# bench (its JSON), less the source resistor share of hbnoise, so the
# transient joins hbnoise, pnoise and the noise at the dc operating point on
# one denominator.

from rawfile import rawread
import numpy as np
import os
import re
import json
import matplotlib
# Agg by default, a Qt window crashes VACASK's postprocess. SHOW_PLOTS=1 shows the figures.
SHOW_PLOTS = os.environ.get('SHOW_PLOTS', '0') == '1'
if not SHOW_PLOTS:
    matplotlib.use('Agg')
import matplotlib.pyplot as plt

K_B = 1.380649e-23
T0 = 290.0
TB = 'sparx_top_le_tb_tn_vacask'
OUTS = ('out1', 'out2', 'out3', 'out4', 'i', 'q')
DIFF = {'i': ('out2', 'out1'), 'q': ('out4', 'out3')}
LABEL = {'out1': 'out1 (V$_{I-}$)', 'out2': 'out2 (V$_{I+}$)', 'out3': 'out3 (V$_{Q-}$)',
         'out4': 'out4 (V$_{Q+}$)', 'i': 'I = out2 - out1', 'q': 'Q = out4 - out3'}
# One analysis per noisescale, read back out of the netlist.
ANALYSIS_RE = r'analysis\s+(\w+)\s+tran\b[^\n]*?noisescale=([\d.eE+\-]+)'
DISCARD_FRAC = 0.1       # drop this fraction of the record (op to tran settling)
DF_TARGET = 100e6        # Welch frequency resolution, sets the segment length
REPORT_F = (5e8, 1e9, 2e9, 3e9)
VARIANT = os.environ.get('POWDET_VARIANT', '').strip()
SUFFIX = f'_{VARIANT}' if VARIANT else ''
TAG = f' {VARIANT}' if VARIANT else ''


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
NF_FILE = os.path.join(DATA_DIR, f'sparx_top_le_nf{SUFFIX}.json')


def db(x):
    return 10.0 * np.log10(x)


def welch(t, v):
    """One-sided PSD of an unevenly sampled transient, Hann window, numpy only."""
    keep = t >= t[0] + DISCARD_FRAC * (t[-1] - t[0])
    t, v = t[keep], v[keep]
    # The integrator steps adaptively, so resample onto a uniform grid at the same average rate.
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


with open(os.path.join(SIM_DIR, TB + '.spectre')) as fh:
    netlist = fh.read()
analyses = re.findall(ANALYSIS_RE, netlist)
if not analyses:
    raise RuntimeError(f'No transient-noise analyses found in {TB}.spectre.')
_m = re.search(r'noisefmax=([\d.eE+\-]+)([GMKkT]?)', netlist)
FMAX = float(_m.group(1)) * {'': 1, 'k': 1e3, 'K': 1e3, 'M': 1e6, 'G': 1e9, 'T': 1e12}[_m.group(2)]

runs, missing = [], []
for name, ns in analyses:
    path = os.path.join(SIM_DIR, name + '.raw')
    if not os.path.isfile(path) or os.path.getsize(path) == 0:
        missing.append((name, ns))
        continue
    tn = rawread(path).get()
    t = np.real(tn['time'])
    order = np.argsort(t)
    t = t[order]
    v = {o: np.real(tn[o])[order] for o in ('out1', 'out2', 'out3', 'out4')}
    for o, (p, n) in DIFF.items():
        v[o] = v[p] - v[n]
    run = {'ns': float(ns), 'psd': {}}
    for o in OUTS:
        f_o, psd, fs, npts, nseg = welch(t, v[o])
        run['psd'][o] = psd
    run.update({'f': f_o, 'fs': fs, 'npts': npts, 'nseg': nseg})
    runs.append(run)
runs.sort(key=lambda r: r['ns'])
for name, ns in missing:
    print(f'Note: {name}.raw is missing, so noisescale = {ns} is not in the fit. VACASK aborts a '
          'transient-noise run without writing a rawfile and still exits 0, so check the '
          'transcript for "Timestep too small".')
if len(runs) < 2:
    raise RuntimeError(f'Need at least 2 noisescale points, {len(runs)} produced a rawfile.')

# Each realisation takes a slightly different number of timepoints, so the Welch
# grids differ by a fraction of a percent. Put them on the first run's grid.
f = runs[0]['f']
if max(abs(r['f'][-1] / f[-1] - 1.0) for r in runs) > 0.05:
    raise RuntimeError('The runs produced very different sample rates. They must share stop, '
                       'maxstep and noisefmax.')
for r in runs[1:]:
    r['psd'] = {o: np.interp(f, r['f'], p) for o, p in r['psd'].items()}

# --- S(f, x) = a*x + b*x^2 with x = noisescale^2, from the extreme rungs -----
x = np.array([r['ns'] ** 2 for r in runs])
xlo, xhi = x[0], x[-1]
det = xlo * xhi ** 2 - xhi * xlo ** 2
a_lin, b_exc = {}, {}
for o in OUTS:
    s_lo, s_hi = runs[0]['psd'][o], runs[-1]['psd'][o]
    a_lin[o] = np.clip((s_lo * xhi ** 2 - s_hi * xlo ** 2) / det, 0, None)
    b_exc[o] = np.clip((s_hi * xlo - s_lo * xhi) / det, 0, None)


def band_mean(arr, f0, rel=0.2):
    m = (f > (1 - rel) * f0) & (f < (1 + rel) * f0)
    return float(np.mean(arr[m])) if m.any() else float('nan')


# --- references from the NF bench --------------------------------------------
def load_ref(name):
    path = os.path.join(SIM_DIR, name + '.raw')
    if not os.path.isfile(path):
        return None
    r = rawread(path).get()
    return np.real(r['frequency']), np.real(r['onoise']), np.real(r['n(Rrf)'])


ref_p = {o: load_ref(f'rxnf_hbnoise_{o}') for o in OUTS}
ref_q = {o: load_ref(f'rxnf_noise_{o}') for o in OUTS}
if any(v is None for v in ref_p.values()):
    print('Note: hbnoise rawfiles of the NF bench are missing, the linear term cannot be checked. '
          'Run make sim-xschem TB=sparx_top_le_tb_nf_vacask first.')

print(f'Records              : {runs[0]["npts"]} points, fs = {runs[0]["fs"]:.3e} Hz, '
      f'{runs[0]["nseg"]} Welch segments, df = {f[1]:.3e} Hz')
print('noisescale points    : ' + ', '.join(f'{r["ns"]:g}' for r in runs))
print()
print('Linear term of the ladder against hbnoise (LO on) and the noise at the dc operating point')
print('(LO off) of the NF bench, output ASD ratios:')
print(f'{"output":>7} ' + ' '.join(f'{f0/1e9:>5.1f} GHz hbn / dc' for f0 in REPORT_F))
rows = {o: [] for o in OUTS}
for o in OUTS:
    line = f'{o:>7} '
    for f0 in REPORT_F:
        lin = np.sqrt(band_mean(a_lin[o], f0))
        r_p = np.sqrt(np.interp(f0, ref_p[o][0], ref_p[o][1])) if ref_p[o] else float('nan')
        r_q = np.sqrt(np.interp(f0, ref_q[o][0], ref_q[o][1])) if ref_q[o] else float('nan')
        tot = np.sqrt(band_mean(runs[-1]['psd'][o], f0)) / runs[-1]['ns']
        rows[o].append({'f_Hz': f0, 'asd_linear_V': lin, 'asd_hbnoise_V': r_p, 'asd_quiescent_V': r_q,
                        'asd_top_rung_normalised_V': tot})
        line += f'   {lin/r_p:6.3f} / {lin/r_q:5.3f} '
    print(line)
print()
print('Normalised ASD per rung at 1 GHz, sqrt(S)/noisescale. A linear circuit gives one value per output:')
for r in runs:
    print(f'  noisescale {r["ns"]:<7g} ' + ' '.join(f'{o} {np.sqrt(band_mean(r["psd"][o], 1e9))/r["ns"]:.3e}'
                                                for o in ('out1', 'i', 'q')))

# --- noise figure from the four estimates ---------------------------------------
curves = None
if os.path.isfile(NF_FILE) and all(v is not None for v in ref_p.values()):
    with open(NF_FILE) as fh:
        nf = json.load(fh)
    f_nf = np.asarray(nf['f_Hz'])
    m_c = (f >= 2 * f[1]) & (f <= min(FMAX, f_nf[-1]))
    f_c = f[m_c]
    curves = {}
    print()
    print(f'NF_DSB from the four noise estimates, LO {10*np.log10(nf["p_lo_pad_W"]/1e-3):+.0f} dBm at the pad, '
          'all on the hbac conversion of the NF bench:')
    print(f'{"output":>7} {"f_IF [Hz]":>10} {"transient":>10} {"hbnoise":>8} {"pnoise":>7} {"dc op":>7}')
    for o in OUTS:
        d = nf['outputs'][o]
        g_sum = np.asarray(d['g_usb_V2_per_W']) + np.asarray(d['g_lsb_V2_per_W'])
        s_src = np.asarray(d['s_src_hbnoise_V2_per_Hz'])
        has_pn = d['s_int_pnoise_V2_per_Hz'] is not None
        nf_pn = db(1.0 + np.asarray(d['s_int_pnoise_V2_per_Hz']) / (g_sum * K_B * T0)) if has_pn else None
        s_tn = np.clip(a_lin[o][m_c] - np.interp(f_c, f_nf, s_src), 0, None)
        curves[o] = {'f_Hz': f_c,
                     'transient': db(1.0 + s_tn / (np.interp(f_c, f_nf, g_sum) * K_B * T0)),
                     'hbnoise': np.interp(f_c, f_nf, d['nf_dsb_dB']),
                     'quiescent': np.interp(f_c, f_nf, d['nf_dsb_quiescent_dB']),
                     'pnoise': np.interp(f_c, f_nf, nf_pn) if has_pn else None,
                     'f_nf': f_nf, 'nf_hbnoise_full': np.asarray(d['nf_dsb_dB']),
                     'nf_quiescent_full': np.asarray(d['nf_dsb_quiescent_dB']), 'nf_pnoise_full': nf_pn}
        for row in rows[o]:
            f0 = row['f_Hz']
            g = float(np.interp(f0, f_nf, g_sum))
            s = max(row['asd_linear_V'] ** 2 - float(np.interp(f0, f_nf, s_src)), 0.0)
            row.update({'nf_dsb_transient_dB': float(db(1.0 + s / (g * K_B * T0))),
                        'nf_dsb_hbnoise_dB': float(np.interp(f0, f_nf, d['nf_dsb_dB'])),
                        'nf_dsb_quiescent_dB': float(np.interp(f0, f_nf, d['nf_dsb_quiescent_dB']))})
            if has_pn:
                row['nf_dsb_pnoise_dB'] = float(np.interp(f0, f_nf, nf_pn))
            print(f'{o:>7} {f0:10.1e} {row["nf_dsb_transient_dB"]:10.2f} {row["nf_dsb_hbnoise_dB"]:8.2f} '
                  + (f'{row["nf_dsb_pnoise_dB"]:7.2f} ' if has_pn else f'{"-":>7} ')
                  + f'{row["nf_dsb_quiescent_dB"]:7.2f}')
    for o in OUTS:
        dev = [r['nf_dsb_transient_dB'] - r['nf_dsb_hbnoise_dB'] for r in rows[o]]
        print(f'  {o}: transient - hbnoise {min(dev):+.2f} .. {max(dev):+.2f} dB at the reported IFs')
else:
    print(f'\nNote: {NF_FILE} or the NF bench rawfiles are missing, no noise figure from the transient.')

# --- plots ------------------------------------------------------------------
sl = slice(1, None)
fig, axes = plt.subplots(2, 3, figsize=(15, 8), constrained_layout=True, sharex=True)
fig.suptitle(f'Six-Port Receiver{TAG} - Transient Noise, Linear Term of the Ladder Against hbnoise')
for ax, o in zip(axes.flat, OUTS):
    for r, gray in zip(runs, ('0.75', '0.55', '0.35')):
        ax.loglog(f[sl], np.sqrt(r['psd'][o][sl]) / r['ns'], color=gray, lw=0.8, label=f'noisescale = {r["ns"]:g}')
    ax.loglog(f[sl], np.sqrt(a_lin[o][sl]), color='tab:blue', lw=1.5, label='linear term')
    if ref_p[o]:
        ax.loglog(ref_p[o][0], np.sqrt(ref_p[o][1]), 'k', lw=2, label='hbnoise, LO on')
    if ref_q[o]:
        ax.loglog(ref_q[o][0], np.sqrt(ref_q[o][1]), 'k--', lw=1.2, label='noise at the dc op, LO off')
    ax.set_xlim(f[1], FMAX)
    band = (f >= f[1]) & (f <= FMAX)
    vals = np.sqrt(np.concatenate([r['psd'][o][band] / r['ns'] ** 2 for r in runs]))
    vals = vals[np.isfinite(vals) & (vals > 0)]
    if vals.size:
        ax.set_ylim(vals.min() / 3, vals.max() * 3)
    ax.set_title(LABEL[o], fontsize=10)
    ax.grid(True, which='both')
for ax in axes[1]:
    ax.set_xlabel('Frequency (Hz)')
for ax in axes[:, 0]:
    ax.set_ylabel('Output ASD / noisescale (V/$\\sqrt{\\mathrm{Hz}}$)')
axes[0, 0].legend(fontsize=7)
os.makedirs(FIG_DIR, exist_ok=True)
fig_file = os.path.join(FIG_DIR, f'sparx_top_le_tn{SUFFIX}.png')
fig.savefig(fig_file, dpi=150)
print(f'\nWrote {fig_file}')

if curves:
    fig2, axes2 = plt.subplots(2, 3, figsize=(15, 8), constrained_layout=True, sharex=True)
    fig2.suptitle(f'Six-Port Receiver{TAG} - Noise Figure from Four Noise Estimates '
                  f'(LO {10*np.log10(nf["p_lo_pad_W"]/1e-3):+.0f} dBm at the pad)')
    lo_x = 1e8
    for ax, o in zip(axes2.flat, OUTS):
        c = curves[o]
        ax.semilogx(c['f_nf'], c['nf_hbnoise_full'], 'k', lw=2, label='hbnoise, LO on')
        ax.semilogx(c['f_nf'], c['nf_quiescent_full'], 'k--', lw=1.2, label='noise at the dc op, LO off')
        if c['nf_pnoise_full'] is not None:
            ax.semilogx(c['f_nf'], c['nf_pnoise_full'], 'o', color='k', mfc='none', ms=4,
                        label='pnoise, LO on')
        ax.semilogx(c['f_Hz'], c['transient'], color='tab:blue', lw=1, alpha=0.7,
                    label='transient noise, linear term, LO on')
        ax.semilogx([r['f_Hz'] for r in rows[o]], [r['nf_dsb_transient_dB'] for r in rows[o]], 'o',
                    color='tab:blue', label='transient, band mean')
        ax.set_xlim(lo_x, FMAX / 4)
        m = c['f_nf'] >= lo_x
        ax.set_ylim(c['nf_quiescent_full'][m].min() - 2, c['nf_hbnoise_full'][m].max() + 2)
        ax.set_title(LABEL[o], fontsize=10)
        ax.grid(True, which='both')
    for ax in axes2[1]:
        ax.set_xlabel('IF frequency (Hz)')
    for ax in axes2[:, 0]:
        ax.set_ylabel('NF$_{DSB}$ (dB)')
    axes2[0, 0].legend(fontsize=7)
    fig2_file = os.path.join(FIG_DIR, f'sparx_top_le_nf_compare{SUFFIX}.png')
    fig2.savefig(fig2_file, dpi=150)
    print(f'Wrote {fig2_file}')
    cols, head = [curves['i']['f_Hz']], ['f_hz']
    for o in OUTS:
        c = curves[o]
        cols += [c['transient'], c['hbnoise'], c['quiescent']]
        head += [f'nf_dsb_transient_{o}_db', f'nf_dsb_hbnoise_{o}_db', f'nf_dsb_quiescent_{o}_db']
        if c['pnoise'] is not None:
            cols.append(c['pnoise'])
            head.append(f'nf_dsb_pnoise_{o}_db')
    os.makedirs(DATA_DIR, exist_ok=True)
    csv2 = os.path.join(DATA_DIR, f'sparx_top_le_nf_compare{SUFFIX}.csv')
    np.savetxt(csv2, np.column_stack(cols), delimiter=',', comments='', fmt='%.6e', header=','.join(head))
    print(f'Wrote {csv2}')

os.makedirs(DATA_DIR, exist_ok=True)
out_file = os.path.join(DATA_DIR, f'sparx_top_le_tn{SUFFIX}.json')
with open(out_file, 'w') as fh:
    json.dump({'variant': VARIANT or 'm1', 'noisescale': [r['ns'] for r in runs], 'df_Hz': float(f[1]),
               'rows': rows, 'source': TB}, fh, indent=2)
band = (f >= f[1]) & (f <= FMAX)
csv_file = os.path.join(DATA_DIR, f'sparx_top_le_tn{SUFFIX}.csv')
np.savetxt(csv_file, np.column_stack([f[band]] + [np.sqrt(a_lin[o][band]) for o in OUTS]),
           delimiter=',', comments='', fmt='%.6e',
           header='f_hz,' + ','.join(f'asd_linear_{o}_v' for o in OUTS))
print(f'Wrote {out_file}\nWrote {csv_file}')

if SHOW_PLOTS:
    plt.show()
