# SPDX-FileCopyrightText: 2026 The SPARX Team
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# Description: Noise figure of the six-port receiver (full-core fit and four detectors) from VACASK noise, hbnoise and pnoise, with hbac and pac conversion.

# NOISE FIGURE OF THE SIX-PORT RECEIVER.
#
# Reads the rawfiles of sparx_top_le_tb_nf_vacask: the order-24 full-core fit
# sparx_core_le with the four detectors, LO on core port 1, RF on port 2, both
# behind 50 Ohm. Six outputs are evaluated:
#
#   out1 .. out4   the differential output vout - vref of one detector, in the
#                  paper's naming V_I-, V_I+, V_Q-, V_Q+
#   i, q           the six-port outputs I = out2 - out1 and Q = out4 - out3,
#                  the pairing of sparx_top_le_tb_rx_vacask, whose two members
#                  sit about 180 degrees apart at the IF
#
# The noise figure is that of plot_sparx_powdet_sbd_tb_nf_vacask.py, referred
# to the RF pad. With g = (V_IF^2 / 2) / P_a the conversion of one sideband
# from hbac,
#
#   F_DSB = 1 + S_int / ((g_U + g_L) k T0)
#
# where S_int is the output noise less the contribution of Rrf, the RF source
# resistor. Rlo and the on-chip termination of core port 7 stay in S_int, they
# belong to the receiver. S_int comes from three analyses: the small-signal
# noise at the dc operating point (LO off), hbnoise around the HB solution of
# the LO, and pnoise around the shooting PSS of the same LO, which shares no
# code with HB and is read only if its rawfiles come from the same run.
#
# The core fit carries the thermal noise of the passive core, kT(I - S S^H) at
# its ports, from the generator snp2le --thermal-noise appends to it: one noisy
# resistor per port, Rnz_e1 to Rnz_e7, while the fit's own resistors stay
# noiseless (noisy=0), since their noise would be meaningless. The script stops
# if any other core element contributes, and reports the core's share and the NF
# it adds. A core made without --thermal-noise contributes nothing and is
# reported as noiseless. The three resistors the receiver has besides, Rrf, Rlo
# and R4, are reported with their share as well.
#
# Two further checks on the result:
#
#   composition   each detector output against the detector NF bench at the
#                 LO drive that detector sees, plus its RF path loss from the
#                 receiver bench, which is how the paper states the receiver NF.
#                 Both detector figures are referred to the power delivered into
#                 the detector, as the path loss is.
#   correlation   S_I against S_out1 + S_out2 (and Q), 1 if the two
#                 detectors of a pair add uncorrelated noise
#
# POWDET_VARIANT selects the detector variant run by the Makefile (m1_pex): the
# rawfiles are read from simulations/<variant>/ and every output carries the
# variant as a suffix.

from rawfile import rawread
import numpy as np
import os
import json
import re
import matplotlib
# Agg by default, a Qt window crashes VACASK's postprocess. SHOW_PLOTS=1 shows the figure.
SHOW_PLOTS = os.environ.get('SHOW_PLOTS', '0') == '1'
if not SHOW_PLOTS:
    matplotlib.use('Agg')
import matplotlib.pyplot as plt

K_B = 1.380649e-23        # [J/K]
T0 = 290.0                # [K], the IEEE noise figure reference temperature
RS = 50.0                 # source resistance at both pads [Ohm]
SMAG = 1.0                # small-signal source amplitude of hbac and pac [V]
P_RF_PAD = 1e-5           # RF power for the plotted IF amplitude, -20 dBm as in the receiver bench [W]
F_IF = 2e9                # IF of the LO sweeps and of the reported numbers
REPORT_F = (1e6, 1e8, 5e8, 1e9, 2e9, 5e9)
TB = 'sparx_top_le_tb_nf_vacask'
OUTS = ('out1', 'out2', 'out3', 'out4', 'i', 'q')
DETS = ('out1', 'out2', 'out3', 'out4')
DIFF = {'i': ('out2', 'out1'), 'q': ('out4', 'out3')}
LABEL = {'out1': 'out1 (V$_{I-}$)', 'out2': 'out2 (V$_{I+}$)', 'out3': 'out3 (V$_{Q-}$)',
         'out4': 'out4 (V$_{Q+}$)', 'i': 'I = out2 - out1', 'q': 'Q = out4 - out3'}
COLOR = {'out1': 'tab:green', 'out2': 'tab:blue', 'out3': 'tab:gray', 'out4': 'tab:red',
         'i': 'k', 'q': 'tab:purple'}
# Detector instance per output inside sparx_top_le, the core fit and the port 7 termination.
DET_INST = {'out1': 'x1:x1', 'out2': 'x1:x2', 'out3': 'x1:x3', 'out4': 'x1:x9'}
CORE_INST = 'x1:x4'
CORE_SRC = re.compile(r'^n\(x1:x4:Rnz_e\d+\)$')    # the core's noise generator sources
TERMS = {'Rrf': 'Rrf', 'Rlo': 'Rlo', 'R4': 'x1:XR1'}
SRC = 'n(Rrf)'
# The parasitic PNP inside each Schottky PCell, whatever the diode is called in
# the schematic or the extracted view.
PNP_PATTERN = re.compile(r'^n\(x1:x[1239]:[^:,]+:q1\)$')
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
NETLIST = os.path.join(SIM_DIR, TB + '.spectre')


def parse_var(netlist, name):
    m = re.search(rf'var\s+{name}\s*=\s*([\d.eE+\-]+[GMKkTmu]?)', netlist)
    val = m.group(1)
    for suf, exp in (('G', 'e9'), ('M', 'e6'), ('K', 'e3'), ('k', 'e3'),
                     ('T', 'e12'), ('m', 'e-3'), ('u', 'e-6')):
        val = val.replace(suf, exp)
    return float(val)


def dbm(p):
    return 10.0 * np.log10(p / 1e-3)


def db(x):
    return 10.0 * np.log10(x)


def at_f(f, y, f0):
    """y at f0, interpolated linearly in log frequency."""
    return float(np.interp(np.log10(f0), np.log10(f), y))


def raw_path(name):
    return os.path.join(SIM_DIR, name + '.raw')


def load(name, sweeps=0):
    return rawread(raw_path(name)).get(sweeps=sweeps) if sweeps else rawread(raw_path(name)).get()


def phasor(r, o, gi=None):
    """IF phasor of output o in an hbac or pac result, gi selects a sweep point."""
    def v(n):
        return r[n + ';0'] if gi is None else r[gi, n + ';0']
    if o in DIFF:
        p, n = DIFF[o]
        return v(p) - v(n)
    return v(o)


with open(NETLIST) as fh:
    netlist = fh.read()
freq_lo = parse_var(netlist, 'freq_lo')
ampl_lo = parse_var(netlist, 'ampl_lo')
p_lo = ampl_lo ** 2 / (8.0 * RS)             # available LO power at the pad [W]
p_a = SMAG ** 2 / (8.0 * RS)                 # available power of the unit small-signal tone [W]


def inst_sum(r, inst, gi=None):
    """Noise contribution of an instance and everything inside it."""
    names = [n for n in r.names if n.startswith('n(') and ',' not in n
             and (n[2:-1] == inst or n[2:-1].startswith(inst + ':'))]
    return sum(np.real(r[n] if gi is None else r[gi, n]) for n in names)


def noise_split(name):
    """(f, S_out, S_int, S_pnp, rawfile) of a noise, hbnoise or pnoise result."""
    r = load(name)
    f = np.real(r['frequency'])
    s_out = np.real(r['onoise'])
    fit_noise = [n for n in r.names if n.startswith(f'n({CORE_INST}:') and ',' not in n
                 and not CORE_SRC.match(n) and np.max(np.abs(np.real(r[n]))) > 0.0]
    if fit_noise:
        raise RuntimeError(f'{name}: {fit_noise[0]} contributes noise. Only the generator sources '
                           'Rnz_e* may, a vector fit\'s own resistors must be noiseless (noisy=0). '
                           'Regenerate the model with a current snp2le.')
    s_pnp = sum(np.real(r[n]) for n in r.names if PNP_PATTERN.match(n))
    return f, s_out, s_out - np.real(r[SRC]), s_pnp, r


def conversion(name):
    """(f, {output: g}) of an hbac or pac IF sweep, g in V^2/W."""
    r = load(name)
    return np.real(r['frequency']), {o: (np.abs(phasor(r, o)) ** 2 / 2.0) / p_a for o in OUTS}


def noise_figures(s, gu, gl):
    return db(1.0 + s / ((gu + gl) * K_B * T0)), db(1.0 + gl / gu + s / (gu * K_B * T0))


def same_run(name):
    """True if the rawfile exists and is not older than the hbac result of this run."""
    path = raw_path(name)
    return os.path.isfile(path) and os.path.getmtime(path) >= os.path.getmtime(raw_path('rxnf_hbac_usb'))


# --- conversion and the three noise estimates over the IF -------------------
f, g_u = conversion('rxnf_hbac_usb')
f_l, g_l = conversion('rxnf_hbac_lsb')
res = {}
for o in OUTS:
    fq, sq_out, sq, sq_pnp, nz = noise_split(f'rxnf_noise_{o}')
    fp, sp_out, sp, sp_pnp, hn = noise_split(f'rxnf_hbnoise_{o}')
    for fx in (fq, fp, f_l):
        if fx.size != f.size or np.max(np.abs(fx / f - 1.0)) > 1e-6:
            raise RuntimeError('noise, hbac and hbnoise must sweep the same IF grid')
    nf_dsb, nf_ssb = noise_figures(sp, g_u[o], g_l[o])
    s_core = inst_sum(hn, CORE_INST)
    res[o] = {
        's_q': sq, 's_p': sp, 's_p_out': sp_out, 's_p_pnp': sp_pnp, 'nz': nz, 'hn': hn,
        'nf_dsb': nf_dsb, 'nf_ssb': nf_ssb, 's_p_core': s_core,
        'nf_added_by_core': nf_dsb - noise_figures(sp - s_core, g_u[o], g_l[o])[0],
        'nf_dsb_q': noise_figures(sq, g_u[o], g_l[o])[0],
        'nf_dsb_nopnp': noise_figures(np.clip(sp - sp_pnp, 0, None), g_u[o], g_l[o])[0],
        'gain_check_db': float(np.max(np.abs(db(4.0 * RS * np.real(hn['gain']) / g_u[o])))),
    }

HAVE_SHOOTING = all(same_run(n) for n in ['rxnf_pac_usb', 'rxnf_pac_lsb']
                    + [f'rxnf_pnoise_{o}' for o in OUTS])
if HAVE_SHOOTING:
    _, g_u_pac = conversion('rxnf_pac_usb')
    _, g_l_pac = conversion('rxnf_pac_lsb')
    for o in OUTS:
        fn, s_out, s_int, _, pn = noise_split(f'rxnf_pnoise_{o}')
        if fn.size != f.size or np.max(np.abs(fn / f - 1.0)) > 1e-6:
            raise RuntimeError('pnoise must sweep the IF grid of hbnoise')
        r = res[o]
        r['s_pn'] = s_int
        r['nf_dsb_pn'] = noise_figures(s_int, g_u_pac[o], g_l_pac[o])[0]
        r['pac_vs_hbac_db'] = np.concatenate((db(g_u_pac[o] / g_u[o]), db(g_l_pac[o] / g_l[o])))
        r['pn_vs_hbn_db'] = db(s_out / r['s_p_out'])
        r['pn_gain_check_db'] = float(np.max(np.abs(db(4.0 * RS * np.real(pn['gain']) / g_u_pac[o]))))


# --- against the LO drive at a 2 GHz IF ---------------------------------------
def sweep_points(name, value):
    """(sorted LO amplitudes, value(rawfile, group) in that order) of a swept analysis."""
    h = load(name, sweeps=1)
    grid, vals = [], []
    for gi in range(h.sweepGroups):
        sd = h.sweepData(gi)
        grid.append(float(np.abs(sd[next(iter(sd))])))
        vals.append(value(h, gi))
    order = np.argsort(grid)
    return np.asarray(grid)[order], [vals[i] for i in order]


def lo_noise(h, gi):
    """(S_int, gain) at one LO amplitude of an hbnoise or pnoise sweep."""
    return (float(np.real(h[gi, 'onoise'])[0] - np.real(h[gi, SRC])[0]),
            float(np.real(h[gi, 'gain'])[0]))


a_grid, ph_lo = sweep_points('rxnf_hbac_lo', lambda h, gi: {o: complex(phasor(h, o, gi)[0]) for o in OUTS})
plo_grid = a_grid ** 2 / (8.0 * RS)
lo = {}
for o in OUTS:
    a_n, pts = sweep_points(f'rxnf_hbnoise_lo_{o}', lo_noise)
    if a_n.size != a_grid.size or np.max(np.abs(a_n / a_grid - 1.0)) > 1e-6:
        raise RuntimeError('the hbac and hbnoise LO sweeps must use the same amplitude grid')
    g_grid = np.asarray([abs(p[o]) ** 2 / 2.0 / p_a for p in ph_lo])
    # The sweeps measure the upper sideband, the lower one follows from the
    # sideband ratio of the IF sweep at the same IF.
    imb = at_f(f, g_l[o], F_IF) / at_f(f, g_u[o], F_IF)
    s_int = np.asarray([p[0] for p in pts])
    s_q = at_f(f, res[o]['s_q'], F_IF)
    lo[o] = {'g': g_grid, 's_int': s_int,
             'nf': noise_figures(s_int, g_grid, g_grid * imb)[0],
             'nf_q': noise_figures(s_q, g_grid, g_grid * imb)[0],
             'gain_check_db': float(np.max(np.abs(db(4.0 * RS * np.asarray([p[1] for p in pts]) / g_grid))))}
    # pnoise runs on a subset of the HB levels, every other level stays nan.
    pn_name = f'rxnf_pnoise_lo_{o}'
    if HAVE_SHOOTING and same_run(pn_name):
        a_p, pts_p = sweep_points(pn_name, lo_noise)
        idx = [int(np.argmin(np.abs(a_grid / a - 1.0))) for a in a_p]
        if any(abs(a_grid[j] / a - 1.0) > 1e-6 for j, a in zip(idx, a_p)):
            raise RuntimeError(f'{pn_name} sweeps an LO amplitude that the hbac LO sweep does not have')
        g_pn = 4.0 * RS * np.asarray([p[1] for p in pts_p])
        imb_pac = at_f(f, g_l_pac[o], F_IF) / at_f(f, g_u_pac[o], F_IF)
        nf_pn = np.full(a_grid.size, np.nan)
        nf_pn[idx] = noise_figures(np.asarray([p[0] for p in pts_p]), g_pn, g_pn * imb_pac)[0]
        lo[o]['nf_pn'] = nf_pn
        lo[o]['pn_minus_hb_db'] = nf_pn[idx] - lo[o]['nf'][idx]


# --- composition: detector NF bench plus RF path loss -------------------------
# The receiver bench measures its path losses and LO drives as power delivered
# into the detector, the detector bench refers its NF and LO sweep to the power
# available from 50 Ohm. Their sum would count the detector's mismatch loss
# twice (0.04 dB as fabricated, 0.37 dB post-layout), so the composition refers
# the detector figures to delivered power with the input impedance of the PSS bench.
comp = None
pd_file = os.path.join(DATA_DIR, f'sparx_powdet_sbd_nf{SUFFIX}.json')
rx_file = os.path.join(DATA_DIR, f'sparx_top_le_rx{SUFFIX}.json')
beta_file = os.path.join(DATA_DIR, f'sparx_powdet_sbd_beta{SUFFIX}.json')
if all(os.path.isfile(x) for x in (pd_file, rx_file, beta_file)):
    with open(pd_file) as fh:
        pd = json.load(fh)
    with open(rx_file) as fh:
        rx = json.load(fh)
    with open(beta_file) as fh:
        z_det = complex(*json.load(fh)['z_in_small_signal_ohm'])
    mm_db = float(db(1.0 - abs((z_det - RS) / (z_det + RS)) ** 2))   # mismatch loss, negative
    pd_plo = dbm(np.asarray(pd['nf_vs_plo']['p_lo_W']))
    pd_nf = np.asarray(pd['nf_vs_plo']['nf_dsb_dB'])
    comp = {}
    for k, o in enumerate(DETS):
        nf_det = float(np.interp(rx['p_lo_det_dBm'][k] - mm_db, pd_plo, pd_nf)) + mm_db
        comp[o] = {'p_lo_det_dBm': rx['p_lo_det_dBm'][k], 'mismatch_loss_dB': mm_db,
                   'nf_det_delivered_dB': nf_det, 'rf_path_loss_dB': rx['rf_path_loss_dB'][k],
                   'nf_composed_dB': nf_det + rx['rf_path_loss_dB'][k]}

# --- report -----------------------------------------------------------------
i_op = int(np.argmin(np.abs(a_grid - ampl_lo)))
print(f'Variant              : {VARIANT or "as fabricated"}')
print(f'LO                   : {freq_lo/1e9:.0f} GHz at {dbm(p_lo):+.1f} dBm available at the pad')
core_share = {o: at_f(f, res[o]['s_p_core'] / res[o]['s_p_out'], F_IF) for o in OUTS}
core_nf = {o: at_f(f, res[o]['nf_added_by_core'], F_IF) for o in OUTS}
if max(core_share.values()) > 0.0:
    print(f'Core thermal noise   : {min(core_share.values()):.1e} to {max(core_share.values()):.1e} of the '
          f'output noise, {min(core_nf.values()):.5f} to {max(core_nf.values()):.5f} dB of NF_DSB '
          f'at {F_IF/1e9:.0f} GHz (hbnoise), from the Rnz_e* sources only')
else:
    print('Core thermal noise   : none, the core fit was made without --thermal-noise')
print()
print(f'At {F_IF/1e9:.0f} GHz IF, NF_DSB referred to the RF pad:')
print(f'{"output":>16} {"g_U":>8} {"hbnoise":>8} {"pnoise":>7} {"dc op":>7} {"no PNP":>7} '
      f'{"LO on/off":>9} {"Rrf":>8} {"Rlo":>8} {"R4":>8}')
print(f'{"":>16} {"[dBV2/W]":>8} {"[dB]":>8} {"[dB]":>7} {"[dB]":>7} {"[dB]":>7} {"":>9} '
      f'{"share":>8} {"share":>8} {"share":>8}')
summary_out = {}
for o in OUTS:
    r = res[o]
    hn = r['hn']
    shares = {t: at_f(f, inst_sum(hn, v) / r['s_p_out'], F_IF) for t, v in TERMS.items()}
    row = {'g_usb_V2_per_W': at_f(f, g_u[o], F_IF), 'g_lsb_V2_per_W': at_f(f, g_l[o], F_IF),
           'nf_dsb_hbnoise_dB': at_f(f, r['nf_dsb'], F_IF),
           'nf_dsb_quiescent_dB': at_f(f, r['nf_dsb_q'], F_IF),
           'nf_dsb_no_pnp_dB': at_f(f, r['nf_dsb_nopnp'], F_IF),
           'pumped_over_quiescent': at_f(f, r['s_p'] / r['s_q'], F_IF),
           'termination_share_hbnoise': shares,
           'core_share_hbnoise': core_share[o],
           'nf_dsb_added_by_core_dB': core_nf[o],
           'hbnoise_gain_vs_hbac_max_dB': r['gain_check_db'],
           'hbnoise_gain_vs_hbac_lo_sweep_max_dB': lo[o]['gain_check_db']}
    if HAVE_SHOOTING:
        row.update({'nf_dsb_pnoise_dB': at_f(f, r['nf_dsb_pn'], F_IF),
                    'pac_minus_hbac_dB': [float(r['pac_vs_hbac_db'].min()), float(r['pac_vs_hbac_db'].max())],
                    'pnoise_minus_hbnoise_dB': [float(r['pn_vs_hbn_db'].min()), float(r['pn_vs_hbn_db'].max())],
                    'pnoise_gain_vs_pac_max_dB': r['pn_gain_check_db']})
    summary_out[o] = row
    pn_txt = f'{row["nf_dsb_pnoise_dB"]:7.2f}' if HAVE_SHOOTING else f'{"-":>7}'
    print(f'{o:>16} {db(row["g_usb_V2_per_W"]):8.2f} {row["nf_dsb_hbnoise_dB"]:8.2f} {pn_txt} '
          f'{row["nf_dsb_quiescent_dB"]:7.2f} {row["nf_dsb_no_pnp_dB"]:7.2f} '
          f'{row["pumped_over_quiescent"]:9.2f} {shares["Rrf"]:8.1e} {shares["Rlo"]:8.1e} {shares["R4"]:8.1e}')
print()
print(f'{"f_IF [Hz]":>10} ' + ' '.join(f'{o + " hbn":>9} {o + " dc":>8}' for o in ('i', 'q')))
for f0 in REPORT_F:
    print(f'{f0:10.1e} ' + ' '.join(f'{at_f(f, res[o]["nf_dsb"], f0):9.2f} {at_f(f, res[o]["nf_dsb_q"], f0):8.2f}'
                                    for o in ('i', 'q')))
print()
if HAVE_SHOOTING:
    print('Shooting cross-check, pac against hbac and pnoise against hbnoise, over the IF sweep:')
    for o in OUTS:
        r = res[o]
        print(f'  {o:>5}: pac - hbac {r["pac_vs_hbac_db"].min():+.3f} .. {r["pac_vs_hbac_db"].max():+.3f} dB, '
              f'pnoise - hbnoise {r["pn_vs_hbn_db"].min():+.3f} .. {r["pn_vs_hbn_db"].max():+.3f} dB, '
              f'pnoise gain vs pac {r["pn_gain_check_db"]:.1e} dB')
else:
    print('Shooting cross-check skipped: no pac and pnoise rawfiles from this run.')
print(f'hbnoise gain vs hbac : within {max(res[o]["gain_check_db"] for o in OUTS):.1e} dB over the IF sweep, '
      f'{max(lo[o]["gain_check_db"] for o in OUTS):.1e} dB over the LO sweep')
print()
corr, lo_rej = {}, {}
for o, (p, n) in DIFF.items():
    corr[o] = at_f(f, res[o]['s_p_out'] / (res[p]['s_p_out'] + res[n]['s_p_out']), F_IF)
    # The LO source noise reaches both detectors of a pair through the same LO
    # path and largely cancels in their difference.
    s_lo = {x: at_f(f, inst_sum(res[x]['hn'], TERMS['Rlo']), F_IF) for x in (o, p, n)}
    lo_rej[o] = float(db((s_lo[p] + s_lo[n]) / s_lo[o]))
print('Correlation          : S_I / (S_out1 + S_out2) = '
      f'{corr["i"]:.4f}, S_Q / (S_out3 + S_out4) = {corr["q"]:.4f} at {F_IF/1e9:.0f} GHz (hbnoise)')
print(f'LO source noise      : {lo_rej["i"]:.1f} dB below the sum of its two detectors in I, '
      f'{lo_rej["q"]:.1f} dB in Q')
if comp:
    print(f'Composition at {F_IF/1e9:.0f} GHz  : detector NF bench at the LO each detector sees, both referred to '
          f'delivered power ({mm_db:+.2f} dB of mismatch), plus its RF path loss')
    for o in DETS:
        c = comp[o]
        c['nf_receiver_dB'] = summary_out[o]['nf_dsb_hbnoise_dB']
        print(f'  {o}: {c["nf_det_delivered_dB"]:.2f} dB at {c["p_lo_det_dBm"]:+.1f} dBm LO + {c["rf_path_loss_dB"]:.2f} dB '
              f'= {c["nf_composed_dB"]:.2f} dB, receiver {c["nf_receiver_dB"]:.2f} dB, '
              f'difference {c["nf_receiver_dB"] - c["nf_composed_dB"]:+.2f} dB')
else:
    print('Composition skipped: run the PSS and NF benches of the detector and the receiver bench of the '
          'same variant first, their JSON files are missing.')
print()
print(f'NF_DSB at {F_IF/1e9:.0f} GHz against the LO power at the pad (hbnoise, pnoise where run):')
print(f'{"P_LO [dBm]":>10} ' + ' '.join(f'{o:>7}' for o in OUTS) + '  ' +
      ' '.join(f'{o + " pn":>7}' for o in OUTS if 'nf_pn' in lo[o]))
for j in range(a_grid.size):
    print(f'{dbm(plo_grid[j]):10.1f} ' + ' '.join(f'{lo[o]["nf"][j]:7.2f}' for o in OUTS) + '  ' +
          ' '.join(f'{lo[o]["nf_pn"][j]:7.2f}' if np.isfinite(lo[o]['nf_pn'][j]) else f'{"-":>7}'
                   for o in OUTS if 'nf_pn' in lo[o]))
best = {o: (float(lo[o]['nf'][int(np.argmin(lo[o]['nf']))]), float(dbm(plo_grid[int(np.argmin(lo[o]['nf']))])))
        for o in OUTS}
print('Best NF_DSB          : ' + ', '.join(f'{o} {b[0]:.1f} dB at {b[1]:+.0f} dBm' for o, b in best.items()))
for o in OUTS:
    if 'pn_minus_hb_db' in lo[o]:
        d = lo[o]['pn_minus_hb_db']
        summary_out[o]['lo_sweep_nf_pnoise_minus_hbnoise_dB'] = [float(d.min()), float(d.max())]
        print(f'pnoise - hbnoise, {o}  : {d.min():+.3f} .. {d.max():+.3f} dB in NF over the LO levels pnoise ran at')
print()
print(f'Largest output-noise contributors of the I output at {F_IF/1e9:.0f} GHz, pumped:')
hn_i = res['i']['hn']
rank = sorted(((at_f(f, np.real(hn_i[n]), F_IF), n) for n in hn_i.names
               if n.startswith('n(') and ',' not in n), reverse=True)
s_i = at_f(f, res['i']['s_p_out'], F_IF)
for v, n in rank[:8]:
    print(f'  {n:40s} {100 * v / s_i:6.2f} %')

# --- plot -----------------------------------------------------------------
fig, axes = plt.subplots(2, 2, figsize=(13, 9), constrained_layout=True)
fig.suptitle(f'Six-Port Receiver{TAG} - Noise Figure (LO {freq_lo/1e9:.0f} GHz at {dbm(p_lo):+.0f} dBm '
             f'at the pad, RF {freq_lo/1e9:.0f} GHz + IF)')

ax = axes[0, 0]
for o in ('i', 'q'):
    r = res[o]
    ax.semilogx(f, r['nf_dsb'], color=COLOR[o], lw=2, label=f'{LABEL[o]}, hbnoise')
    ax.semilogx(f, r['nf_dsb_q'], '--', color=COLOR[o], lw=1.2, label=f'{LABEL[o]}, noise at the dc op')
    if HAVE_SHOOTING:
        ax.semilogx(f[::2], r['nf_dsb_pn'][::2], 'o', color=COLOR[o], mfc='none', ms=4,
                    label=f'{LABEL[o]}, pnoise')
ax.set_xlabel('IF frequency (Hz)')
ax.set_ylabel('NF$_{DSB}$ (dB)')
ax.set_title('I and Q outputs', fontsize=10)
ax.legend(fontsize=7)
ax.grid(True, which='both')

ax = axes[0, 1]
for o in DETS:
    r = res[o]
    ax.semilogx(f, r['nf_dsb'], color=COLOR[o], lw=1.5, label=f'{LABEL[o]}, hbnoise')
    if HAVE_SHOOTING:
        ax.semilogx(f[::2], r['nf_dsb_pn'][::2], 'o', color=COLOR[o], mfc='none', ms=4)
    if comp:
        ax.plot(F_IF, comp[o]['nf_composed_dB'], 'x', color=COLOR[o], ms=8, mew=2)
ax.plot([], [], 'ko', mfc='none', ms=4, label='pnoise')
if comp:
    ax.plot([], [], 'kx', ms=8, mew=2, label='detector NF bench + RF path loss')
ax.set_xlabel('IF frequency (Hz)')
ax.set_ylabel('NF$_{DSB}$ (dB)')
ax.set_title('single detector outputs', fontsize=10)
ax.legend(fontsize=7)
ax.grid(True, which='both')

ax = axes[1, 0]
for o in OUTS:
    ax.semilogx(f, 10 * np.log10(2.0 * g_u[o] * P_RF_PAD), color=COLOR[o], label=LABEL[o])
    if HAVE_SHOOTING:
        ax.semilogx(f[::2], 10 * np.log10(2.0 * g_u_pac[o][::2] * P_RF_PAD), 'o', color=COLOR[o], mfc='none', ms=4)
ax.set_xlabel('IF frequency (Hz)')
ax.set_ylabel(f'IF output amplitude (dBV) at {dbm(P_RF_PAD):+.0f} dBm RF')
ax.set_title('upper sideband, hbac' + (' (lines) and pac (circles)' if HAVE_SHOOTING else ''), fontsize=10)
ax.legend(fontsize=7, ncol=2)
ax.grid(True, which='both')

ax = axes[1, 1]
for o in OUTS:
    ax.plot(dbm(plo_grid), lo[o]['nf'], color=COLOR[o], lw=2 if o in DIFF else 1.2, label=f'{LABEL[o]}, hbnoise')
    if 'nf_pn' in lo[o]:
        ax.plot(dbm(plo_grid), lo[o]['nf_pn'], 'o', color=COLOR[o], mfc='none', ms=5)
for o in ('i', 'q'):
    ax.plot(dbm(plo_grid), lo[o]['nf_q'], '--', color=COLOR[o], lw=1, label=f'{LABEL[o]}, noise at the dc op')
ax.plot([], [], 'ko', mfc='none', ms=5, label='pnoise')
ax.axvline(dbm(p_lo), color='tab:red', ls=':', label=f'LO used above, {dbm(p_lo):+.0f} dBm')
ax.set_xlabel('LO power at the pad (dBm)')
ax.set_ylabel(f'NF$_{{DSB}}$ at {F_IF/1e9:.0f} GHz IF (dB)')
ax.legend(fontsize=7)
ax.grid(True)

os.makedirs(FIG_DIR, exist_ok=True)
fig_file = os.path.join(FIG_DIR, f'sparx_top_le_nf{SUFFIX}.png')
plt.savefig(fig_file, dpi=150)

# --- files ------------------------------------------------------------------
os.makedirs(DATA_DIR, exist_ok=True)
out_json = os.path.join(DATA_DIR, f'sparx_top_le_nf{SUFFIX}.json')
with open(out_json, 'w') as fh:
    json.dump({
        'variant': VARIANT or 'm1',
        'freq_lo_Hz': freq_lo,
        'p_lo_pad_W': p_lo,
        'f_if_report_Hz': F_IF,
        'rs_ohm': RS,
        't0_K': T0,
        'at_f_if': summary_out,
        'correlation_pair_over_sum': corr,
        'lo_source_noise_rejection_dB': lo_rej,
        'composition': comp,
        'best_nf_vs_plo': {o: {'nf_dsb_dB': b[0], 'p_lo_pad_dBm': b[1]} for o, b in best.items()},
        'f_Hz': f.tolist(),
        # Per output over the IF: conversion, the three noise estimates without
        # the source resistor, and the noise figures built on them.
        'outputs': {o: {
            'g_usb_V2_per_W': g_u[o].tolist(),
            'g_lsb_V2_per_W': g_l[o].tolist(),
            's_int_hbnoise_V2_per_Hz': res[o]['s_p'].tolist(),
            's_int_quiescent_V2_per_Hz': res[o]['s_q'].tolist(),
            's_src_hbnoise_V2_per_Hz': (res[o]['s_p_out'] - res[o]['s_p']).tolist(),
            'nf_dsb_dB': res[o]['nf_dsb'].tolist(),
            'nf_ssb_dB': res[o]['nf_ssb'].tolist(),
            'nf_dsb_quiescent_dB': res[o]['nf_dsb_q'].tolist(),
            'nf_dsb_no_pnp_dB': res[o]['nf_dsb_nopnp'].tolist(),
            's_int_pnoise_V2_per_Hz': res[o]['s_pn'].tolist() if HAVE_SHOOTING else None,
            'nf_dsb_pnoise_dB': res[o]['nf_dsb_pn'].tolist() if HAVE_SHOOTING else None,
        } for o in OUTS},
        'nf_vs_plo': {'p_lo_pad_dBm': dbm(plo_grid).tolist(),
                      **{o: {'g_usb_V2_per_W': lo[o]['g'].tolist(),
                             'nf_dsb_dB': lo[o]['nf'].tolist(),
                             'nf_dsb_quiescent_dB': lo[o]['nf_q'].tolist(),
                             # null where pnoise did not run
                             'nf_dsb_pnoise_dB': [None if np.isnan(v) else float(v) for v in lo[o]['nf_pn']]
                             if 'nf_pn' in lo[o] else None}
                         for o in OUTS}},
        'source': TB,
    }, fh, indent=2)

cols, head = [f], ['f_hz']
for o in OUTS:
    cols += [g_u[o], g_l[o], np.sqrt(res[o]['s_p_out']), res[o]['nf_dsb'], res[o]['nf_dsb_q']]
    head += [f'g_usb_{o}', f'g_lsb_{o}', f'asd_pumped_{o}_v', f'nf_dsb_{o}_db', f'nf_dsb_quiescent_{o}_db']
    if HAVE_SHOOTING:
        cols.append(res[o]['nf_dsb_pn'])
        head.append(f'nf_dsb_pnoise_{o}_db')
csv_f = os.path.join(DATA_DIR, f'sparx_top_le_nf{SUFFIX}.csv')
np.savetxt(csv_f, np.column_stack(cols), delimiter=',', comments='', fmt='%.6e', header=','.join(head))
cols, head = [dbm(plo_grid)], ['plo_pad_dbm']
for o in OUTS:
    cols += [lo[o]['g'], lo[o]['nf'], lo[o]['nf_q']]
    head += [f'g_usb_{o}', f'nf_dsb_{o}_db', f'nf_dsb_quiescent_{o}_db']
    if 'nf_pn' in lo[o]:
        cols.append(lo[o]['nf_pn'])
        head.append(f'nf_dsb_pnoise_{o}_db')
csv_lo = os.path.join(DATA_DIR, f'sparx_top_le_nf_lo{SUFFIX}.csv')
np.savetxt(csv_lo, np.column_stack(cols), delimiter=',', comments='', fmt='%.6e', header=','.join(head))
print(f'\nWrote {fig_file}\nWrote {out_json}\nWrote {csv_f}\nWrote {csv_lo}')

if SHOW_PLOTS:
    plt.show()
