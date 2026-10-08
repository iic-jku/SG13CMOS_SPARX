# SPDX-FileCopyrightText: 2025-2026 The SPARX Team
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# Description: Noise figure, NEP and MDS of the SBD power detector from VACASK noise, hbnoise and hbac, checked against pac and pnoise.

# NOISE FIGURE OF THE SBD POWER DETECTOR.
#
# A power detector is not a two-port with power gain, so on its own it has no
# noise figure. Driven by the six-port's LO it is a mixer, and a mixer noise
# figure is well defined. Three analyses supply it:
#
#   powdet_nf_noise        small-signal noise at the quiescent operating point,
#                          LO off. Output noise PSD S_q(f) over the video band,
#                          a BASEBAND quantity: the detector's own noise floor,
#                          which NEP and MDS are built on.
#   powdet_nf_hbnoise_usb  periodic small-signal noise (hbnoise) around the
#   powdet_nf_hbnoise_lsb  single-tone HB solution of the LO. Output noise PSD
#                          S_p(f) at the IF with every source modulated by the
#                          pumped operating point and folded from all spurs.
#                          The two runs differ only in the input spur of the
#                          gain they report, upper or lower sideband.
#   powdet_nf_hbac_usb     periodic small-signal (hbac) analysis around the
#   powdet_nf_hbac_lsb     same HB solution. A unit tone at LO + f (upper
#                          sideband) or LO - f (lower sideband) gives the output
#                          phasor at the IF f.
#   powdet_nf_hbac_lo      the same conversion and the same pumped noise at one
#   powdet_nf_hbnoise_lo   IF against the LO amplitude.
#   powdet_nf_pac_usb      the shooting-PSS twins of the HB analyses: pac of
#   powdet_nf_pac_lsb      hbac, pnoise of hbnoise, around the periodic steady
#   powdet_nf_pnoise_usb   state of the LO found by shooting, which shares no
#   powdet_nf_pnoise_lsb   code with harmonic balance. pnoise_lo is the twin of
#   powdet_nf_pnoise_lo    hbnoise_lo, its gain the pac conversion.
#
# The shooting results are the cross-check of the HB ones and are read only
# if their rawfiles come from the same run, so a deck without them (VACASK
# before 1b48553 has neither analysis) is still post-processed.
#
# With an RF source of available power P_a landing in one sideband and giving
# an IF output of peak amplitude V_IF, define the conversion
#
#   g = (V_IF^2 / 2) / P_a            [V^2/W]
#
# so g * k * T0 is the output noise a source at 290 K produces through that
# sideband, and
#
#   F_DSB(f) = 1 + S_int(f) / ((g_U(f) + g_L(f)) * k * T0)
#   F_SSB(f) = 1 + g_L(f) / g_U(f) + S_int(f) / (g_U(f) * k * T0)
#
# S_int is the output noise without the source resistor's own contribution.
# The g_L / g_U term in F_SSB is the source noise that enters through the
# image sideband and is counted as noise, not signal, in the single-sideband
# definition. It is what makes an ideal symmetric mixer read 3 dB SSB and
# 0 dB DSB. On this detector S_int dominates by 35 dB or more, so the term
# is invisible in the result, but the definition is kept exact.
#
# The noise figure is computed twice, with S_int = S_p from hbnoise, which is
# the result, and with S_int = S_q from the quiescent noise analysis, which
# is the estimate the bench had to use before hbnoise existed. The ratio of
# the two says how much the LO changes the noise, and it is what the
# pre-hbnoise numbers have to be corrected by.
#
# Two cross-checks on the conversion. hbnoise reports gain = |V_IF / V_in|^2
# for a unit tone at its input spur, so g = 4 Rs gain must equal the hbac
# value at every IF. And the closed form of a square-law detector,
# V_IF = 2 S'(P_lo) sqrt(P_lo P_rf) with S' the local slope of the transfer
# curve at the LO drive, must land within a fraction of a dB of the hbac level.
#
# Detector figures of merit come from S_q and the responsivity:
#
#   NEP(f) = sqrt(S_q(f)) / |beta(f)|           [W/sqrt(Hz)]
#   MDS    = v_n,rms(video band) / |beta(0)|    [W], SNR = 1
#
# beta(f) is the responsivity at the video frequency f. It rolls off with the
# same baseband network as the conversion, so the hbac shape g_U(f)/g_U(0)
# supplies it. Dividing the noise at 5 GHz by the DC responsivity would
# understate the NEP there by 20 dB.
#
# MODEL CAVEAT. Over the whole video band most of the output noise comes from
# the flicker noise of the parasitic PNP inside the Schottky PCell
# (n(<diode>:q1)), a device that carries picoamperes here and whose flicker
# model (kf * I^0.53) is being evaluated far below any plausible
# characterisation current. The script therefore also reports every figure
# with those contributors removed, labelled as such. Silicon decides.
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

K_B = 1.380649e-23        # [J/K]
T0 = 290.0                # [K], the IEEE noise figure reference temperature
RS = 50.0                 # source resistance of the testbench [Ohm]
SMAG = 1.0                # small-signal source amplitude of the hbac analyses [V]
NOISE_RAW = 'powdet_nf_noise.raw'
HBNOISE_USB = 'powdet_nf_hbnoise_usb.raw'
HBNOISE_LSB = 'powdet_nf_hbnoise_lsb.raw'
HBNOISE_LO = 'powdet_nf_hbnoise_lo.raw'
HBAC_USB = 'powdet_nf_hbac_usb.raw'
HBAC_LSB = 'powdet_nf_hbac_lsb.raw'
HBAC_LO = 'powdet_nf_hbac_lo.raw'
PAC_USB = 'powdet_nf_pac_usb.raw'
PAC_LSB = 'powdet_nf_pac_lsb.raw'
PNOISE_USB = 'powdet_nf_pnoise_usb.raw'
PNOISE_LSB = 'powdet_nf_pnoise_lsb.raw'
PNOISE_LO = 'powdet_nf_pnoise_lo.raw'
SOURCE_RES = 'Rs'        # instance name of the source resistor in the testbench
# The parasitic PNP inside the Schottky PCell, one per diode instance, whatever
# the instance is called in the schematic or the extracted view.
PNP_PATTERN = re.compile(r'^n\(xdemod1:[^:,]+:q1\)$')
# Reference RF power for the IF amplitude that is plotted: -46.5 dBm, the 3 mV
# source amplitude the earlier two-tone benches used.
P_RF_REF = (3e-3) ** 2 / (8.0 * RS)
# Bands for the integrated RMS output noise and the MDS. The first is the
# DC-coupled worst case, the second what an AC-coupled readout would see.
VIDEO_BANDS = ((1e3, 5e9), (1e6, 5e9))
# The IF at which the noise figure is reported against LO drive. Must be the
# single value of the powdet_nf_hbac_lo and powdet_nf_hbnoise_lo sweeps.
F_IF_LO = 2e9
N_CONTRIB = 4
REPORT_F = (1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 5e8, 1e9, 2e9, 5e9)
TB = 'sparx_powdet_sbd_tb_nf_vacask'
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
BETA_FILE = os.path.join(DATA_DIR, f'sparx_powdet_sbd_beta{SUFFIX}.json')


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


def loginterp(x, xp, fp):
    """Interpolate a positive quantity in log-log."""
    return 10 ** np.interp(np.log10(x), np.log10(xp), np.log10(fp))


def nearest(f, target):
    return int(np.argmin(np.abs(f - target)))


with open(NETLIST) as f:
    netlist = f.read()
freq_lo = parse_var(netlist, 'freq_lo')
ampl_lo = parse_var(netlist, 'ampl_lo')
p_lo = ampl_lo ** 2 / (8.0 * RS)             # available LO power [W]
p_a = SMAG ** 2 / (8.0 * RS)                 # available power of the unit small-signal tone [W]
src_vec = f'n({SOURCE_RES})'


def noise_split(raw):
    """(frequency, S_int, S_pnp, per-source vectors) of a noise or hbnoise rawfile.

    The source resistor's own noise is part of the source, not of the detector,
    so it comes out of S_int. In the hbnoise result it is the thermal noise of
    Rs folded from every spur, about 1/F of the total (1.4e-4 for one cell,
    2.8e-3 for 16 cells), nearly all of it from the two signal sidebands.
    """
    r = rawread(os.path.join(SIM_DIR, raw)).get()
    f = np.real(r['frequency'])
    s_out = np.real(r['onoise'])
    s_src = np.real(r[src_vec]) if src_vec in r.names else np.zeros_like(s_out)
    pnp_vecs = [n for n in r.names if PNP_PATTERN.match(n)]
    if not pnp_vecs:
        raise RuntimeError(f'No n(xdemod1:<diode>:q1) vector in {raw}. The analysis needs '
                           '`save full`, and the diodes must sit inside xdemod1.')
    s_pnp = sum(np.real(r[n]) for n in pnp_vecs)
    return f, s_out - s_src, s_pnp, r


# --- output noise PSD, quiescent (LO off) and pumped (LO on) ------------------
f_n, s_q, s_q_pnp, nz = noise_split(NOISE_RAW)
f_p, s_p, s_p_pnp, hn = noise_split(HBNOISE_USB)
if f_p.size != f_n.size or np.max(np.abs(f_p / f_n - 1.0)) > 1e-6:
    raise RuntimeError('noise and hbnoise must sweep the same frequency grid')
hn_l = rawread(os.path.join(SIM_DIR, HBNOISE_LSB)).get()
if np.max(np.abs(np.real(hn_l['onoise']) / np.real(hn['onoise']) - 1.0)) > 1e-6:
    raise RuntimeError('the usb and lsb hbnoise runs report different onoise, they must '
                       'differ only in inspur')
asd_q = np.sqrt(s_q)
asd_p = np.sqrt(s_p)
s_q_nopnp = np.clip(s_q - s_q_pnp, 0, None)
s_p_nopnp = np.clip(s_p - s_p_pnp, 0, None)
pump_ratio = s_p / s_q                       # what the LO does to the output noise


def ranked(r, f, lo, hi):
    band = (f >= lo) & (f <= hi)
    return sorted(((float(np.trapezoid(np.real(r[n])[band], f[band])), n)
                   for n in r.names if n.startswith('n(') and ',' not in n and n != src_vec),
                  reverse=True)


# --- conversion from hbac ----------------------------------------------------
def hbac_conversion(raw_name):
    """(f, g) of an hbac sweep: output phasor at the IF for the unit tone."""
    h = rawread(os.path.join(SIM_DIR, raw_name)).get()
    f = np.real(h['frequency'])
    name = next(n for n in h.names if n.startswith('out;'))
    v_if = np.abs(h[name])
    return f, (v_if ** 2 / 2.0) / p_a


f_u, g_u_raw = hbac_conversion(HBAC_USB)
f_l, g_l_raw = hbac_conversion(HBAC_LSB)
g_u = loginterp(f_n, f_u, g_u_raw)
g_l = loginterp(f_n, f_l, g_l_raw)
shape_n = g_u / g_u[0]                       # |H_bb(f)|^2 relative to the low end
imb_db = db(g_l / g_u)

# --- the same conversion out of hbnoise, as a check on the two analyses -----
# gain = |V_IF / V_in|^2 for a unit tone at inspur, so g = 4 Rs gain.
g_u_hbn = 4.0 * RS * np.real(hn['gain'])
g_l_hbn = 4.0 * RS * np.real(hn_l['gain'])
gain_check_db = float(np.max(np.abs(db(g_u_hbn / g_u))))
gain_check_db = max(gain_check_db, float(np.max(np.abs(db(g_l_hbn / g_l)))))


# --- noise figures ---------------------------------------------------------
def noise_figures(s, gu, gl):
    f_dsb = 1.0 + s / ((gu + gl) * K_B * T0)
    f_ssb = 1.0 + gl / gu + s / (gu * K_B * T0)
    return db(f_dsb), db(f_ssb)


nf_dsb, nf_ssb = noise_figures(s_p, g_u, g_l)              # the result, pumped noise
nf_dsb_nopnp, _ = noise_figures(s_p_nopnp, g_u, g_l)
nf_dsb_q, nf_ssb_q = noise_figures(s_q, g_u, g_l)          # the pre-hbnoise estimate
nf_dsb_q_nopnp, _ = noise_figures(s_q_nopnp, g_u, g_l)

# --- noise figure against LO drive, from the two LO sweeps ------------------
def sweep_points(raw_name, value):
    """(sorted a_lo grid, value(group) in that order) of a swept analysis."""
    h = rawread(os.path.join(SIM_DIR, raw_name)).get(sweeps=1)
    grid, vals = [], []
    for gi in range(h.sweepGroups):
        sd = h.sweepData(gi)
        a = float(np.abs(sd[next(iter(sd))]))
        grid.append(a)
        vals.append(value(h, gi))
    order = np.argsort(grid)
    return np.asarray(grid)[order], [vals[i] for i in order]


def lo_noise_point(h, gi):
    """(S_int, S_pnp, gain) at one LO amplitude of an hbnoise or pnoise sweep."""
    s_src = float(np.real(h[gi, src_vec])[0]) if src_vec in h.names else 0.0
    return (float(np.real(h[gi, 'onoise'])[0]) - s_src,
            float(sum(np.real(h[gi, n])[0] for n in h.names if PNP_PATTERN.match(n))),
            float(np.real(h[gi, 'gain'])[0]))


name_lo = next(n for n in rawread(os.path.join(SIM_DIR, HBAC_LO)).get().names if n.startswith('out;'))
a_grid, v_if_lo = sweep_points(HBAC_LO, lambda h, gi: float(np.abs(h[gi, name_lo])[0]))
a_grid_n, s_lo = sweep_points(HBNOISE_LO, lo_noise_point)
if a_grid.size != a_grid_n.size or np.max(np.abs(a_grid_n / a_grid - 1.0)) > 1e-6:
    raise RuntimeError('the hbac and hbnoise LO sweeps must use the same amplitude grid')
plo_grid = a_grid ** 2 / (8.0 * RS)
g_lo_grid = (np.asarray(v_if_lo) ** 2 / 2.0) / p_a
s_lo_int = np.asarray([v[0] for v in s_lo])
s_lo_nopnp = np.clip(s_lo_int - np.asarray([v[1] for v in s_lo]), 0, None)
g_lo_hbn = 4.0 * RS * np.asarray([v[2] for v in s_lo])
gain_check_lo_db = float(np.max(np.abs(db(g_lo_hbn / g_lo_grid))))
j_if = nearest(f_n, F_IF_LO)
# The sweep measures the upper sideband, the lower one follows from the
# imbalance at that IF, well under 0.1 dB here.
imb_if = g_l[j_if] / g_u[j_if]
nf_vs_plo, _ = noise_figures(s_lo_int, g_lo_grid, g_lo_grid * imb_if)
nf_vs_plo_nopnp, _ = noise_figures(s_lo_nopnp, g_lo_grid, g_lo_grid * imb_if)
nf_vs_plo_q, _ = noise_figures(s_q[j_if], g_lo_grid, g_lo_grid * imb_if)
nf_vs_plo_q_nopnp, _ = noise_figures(s_q_nopnp[j_if], g_lo_grid, g_lo_grid * imb_if)
i_best = int(np.argmin(nf_vs_plo))
i_best_q = int(np.argmin(nf_vs_plo_q))


# --- shooting cross-check: pac against hbac, pnoise against hbnoise ---------
def same_run(raw_name):
    """True if the rawfile exists and is not older than the hbac result of this run."""
    path = os.path.join(SIM_DIR, raw_name)
    return (os.path.isfile(path)
            and os.path.getmtime(path) >= os.path.getmtime(os.path.join(SIM_DIR, HBAC_USB)))


HAVE_SHOOTING = all(same_run(n) for n in (PAC_USB, PAC_LSB, PNOISE_USB, PNOISE_LSB, PNOISE_LO))
if HAVE_SHOOTING:
    f_pu, g_u_pac_raw = hbac_conversion(PAC_USB)
    f_pl, g_l_pac_raw = hbac_conversion(PAC_LSB)
    g_u_pac = loginterp(f_n, f_pu, g_u_pac_raw)
    g_l_pac = loginterp(f_n, f_pl, g_l_pac_raw)
    pac_vs_hbac_db = np.concatenate((db(g_u_pac / g_u), db(g_l_pac / g_l)))
    f_pn, s_pn, _, pn = noise_split(PNOISE_USB)
    if f_pn.size != f_n.size or np.max(np.abs(f_pn / f_n - 1.0)) > 1e-6:
        raise RuntimeError('noise and pnoise must sweep the same frequency grid')
    pn_l = rawread(os.path.join(SIM_DIR, PNOISE_LSB)).get()
    if np.max(np.abs(np.real(pn_l['onoise']) / np.real(pn['onoise']) - 1.0)) > 1e-6:
        raise RuntimeError('the usb and lsb pnoise runs report different onoise, they must '
                           'differ only in inharm')
    pn_vs_hbn_db = db(s_pn / s_p)
    # pnoise and pac linearise at the same stored PSS, so 4 Rs gain is the pac conversion.
    pn_gain_check_db = max(float(np.max(np.abs(db(4.0 * RS * np.real(pn['gain']) / g_u_pac)))),
                           float(np.max(np.abs(db(4.0 * RS * np.real(pn_l['gain']) / g_l_pac)))))
    nf_dsb_pn, _ = noise_figures(s_pn, g_u_pac, g_l_pac)
    a_grid_p, s_lo_p = sweep_points(PNOISE_LO, lo_noise_point)
    if a_grid_p.size != a_grid.size or np.max(np.abs(a_grid_p / a_grid - 1.0)) > 1e-6:
        raise RuntimeError('the pnoise and hbac LO sweeps must use the same amplitude grid')
    s_lo_int_pn = np.asarray([v[0] for v in s_lo_p])
    g_lo_pn = 4.0 * RS * np.asarray([v[2] for v in s_lo_p])
    nf_vs_plo_pn, _ = noise_figures(s_lo_int_pn, g_lo_pn, g_lo_pn * (g_l_pac[j_if] / g_u_pac[j_if]))
    lo_gain_pn_db = db(g_lo_pn / g_lo_grid)
    lo_nf_pn_db = nf_vs_plo_pn - nf_vs_plo
    i_best_pn = int(np.argmin(nf_vs_plo_pn))

# --- responsivity, NEP, MDS --------------------------------------------------
if not os.path.isfile(BETA_FILE):
    raise RuntimeError(f'{BETA_FILE} is missing. Run the PSS testbench first: '
                       'make sim-xschem TB=sparx_powdet_sbd_tb_pss_vacask'
                       + (f' VARIANT={VARIANT}' if VARIANT else ''))
with open(BETA_FILE) as f:
    pss = json.load(f)
beta = abs(float(pss['beta_V_per_W']))
beta_f = beta * np.sqrt(shape_n)             # responsivity at the video frequency
nep = asd_q / beta_f
nep_nopnp = np.sqrt(s_q_nopnp) / beta_f
mds = {}
for lo, hi in VIDEO_BANDS:
    band = (f_n >= lo) & (f_n <= hi)
    v_rms = float(np.sqrt(np.trapezoid(s_q[band], f_n[band])))
    v_rms_np = float(np.sqrt(np.trapezoid(s_q_nopnp[band], f_n[band])))
    mds[(lo, hi)] = (v_rms, v_rms / beta, v_rms_np / beta)

# --- closed-form check on the hbac level ----------------------------------
p_curve = np.asarray(pss['p_avail_W'])
v_curve = np.abs(np.asarray(pss['v_detected_V']))
p_floor = float(pss.get('p_floor_W', p_curve[0]))
ok = (v_curve > 0) & (p_curve >= p_floor)
lp, lv = np.log10(p_curve[ok]), np.log10(v_curve[ok])
s_prime_curve = np.gradient(lv, lp) * (10 ** lv) / (10 ** lp)      # dV/dP [V/W]
if p_curve[ok].min() <= p_lo <= p_curve[ok].max():
    s_prime = float(np.interp(np.log10(p_lo), lp, s_prime_curve))
    g_closed = 2.0 * s_prime ** 2 * p_lo
    closed_delta_db = float(db(g_u[0] / g_closed))
else:
    s_prime, g_closed, closed_delta_db = float('nan'), float('nan'), float('nan')

# --- IF output amplitude at the reference RF power, for the plot -----------
v_if_ref = np.sqrt(2.0 * g_u * P_RF_REF)     # [V peak]

# --- report ---------------------------------------------------------------
lo_b, hi_b = VIDEO_BANDS[-1]
band = (f_n >= lo_b) & (f_n <= hi_b)
contrib_p = ranked(hn, f_n, lo_b, hi_b)
contrib_q = ranked(nz, f_n, lo_b, hi_b)
tot_p = float(np.trapezoid(s_p[band], f_n[band]))

print(f'Variant               : {VARIANT or "as fabricated"}')
print(f'LO                    : {freq_lo/1e9:.1f} GHz at {dbm(p_lo):.1f} dBm available')
print(f'Responsivity beta     : {beta:.4g} V/W  (small signal, from the PSS testbench)')
print(f'Conversion g at LO    : {g_u[0]:.4g} V^2/W at low IF from hbac, closed form '
      f'2 S\'^2 P_lo = {g_closed:.4g} V^2/W (S\' = {abs(s_prime):.4g} V/W), '
      f'hbac - closed form = {closed_delta_db:+.2f} dB')
print(f'hbnoise gain vs hbac  : within {gain_check_db:.4f} dB over the IF sweep, '
      f'{gain_check_lo_db:.4f} dB over the LO sweep')
print(f'IF output at {dbm(P_RF_REF):.1f} dBm RF: {v_if_ref[0]*1e6:.1f} uV at low IF, '
      f'{loginterp(2e9, f_n, v_if_ref)*1e6:.1f} uV at 2 GHz')
print(f'Video bandwidth       : {f_n[np.where(shape_n < 0.5)[0][0]]/1e9:.2f} GHz (-3 dB of the conversion)'
      if np.any(shape_n < 0.5) else 'Video bandwidth       : above the swept range')
print(f'Sideband imbalance    : g_L/g_U = {imb_db[j_if]:+.2f} dB at {F_IF_LO/1e9:.0f} GHz')
for (lo, hi), (v_rms, m, m_np) in mds.items():
    print(f'Video band {lo:.0e} .. {hi:.0e} Hz : {v_rms*1e6:7.1f} uV RMS, '
          f'MDS {dbm(m):6.1f} dBm  (without PCell PNP: {dbm(m_np):6.1f} dBm)')
print()
print('Output noise, pumped (hbnoise, LO on) against the small-signal noise at the dc operating')
print('point (noise, LO off), and the noise figure from each. The pumped column is the result,')
print('the other one is what the bench reported before hbnoise existed.')
print(f'{"f_IF":>10} {"ASD pumped":>11} {"ASD quiesc":>11} {"p/q":>6} {"NF_DSB":>8} {"NF_DSB q":>9} '
      f'{"NF_SSB":>8} {"NF no PNP":>9} {"beta(f)":>9} {"NEP":>11} {"NEP no PNP":>11}')
print(f'{"[Hz]":>10} {"[V/rtHz]":>11} {"[V/rtHz]":>11} {"":>6} {"[dB]":>8} {"[dB]":>9} '
      f'{"[dB]":>8} {"[dB]":>9} {"[V/W]":>9} {"[W/rtHz]":>11} {"[W/rtHz]":>11}')
for target in REPORT_F:
    j = nearest(f_n, target)
    if abs(f_n[j] / target - 1.0) > 0.05:
        continue
    print(f'{f_n[j]:10.3e} {asd_p[j]:11.3e} {asd_q[j]:11.3e} {pump_ratio[j]:6.2f} {nf_dsb[j]:8.2f} '
          f'{nf_dsb_q[j]:9.2f} {nf_ssb[j]:8.2f} {nf_dsb_nopnp[j]:9.2f} {beta_f[j]:9.3g} '
          f'{nep[j]:11.3e} {nep_nopnp[j]:11.3e}')
print()
print(f'Noise figure against LO drive at {F_IF_LO/1e9:.0f} GHz IF:')
print(f'  pumped noise   : best {nf_vs_plo[i_best]:.1f} dB at {dbm(plo_grid[i_best]):.1f} dBm LO, '
      f'{float(np.interp(np.log10(p_lo), np.log10(plo_grid), nf_vs_plo)):.1f} dB at the {dbm(p_lo):.1f} dBm used here')
print(f'  dc op. noise   : best {nf_vs_plo_q[i_best_q]:.1f} dB at {dbm(plo_grid[i_best_q]):.1f} dBm LO, '
      f'{float(np.interp(np.log10(p_lo), np.log10(plo_grid), nf_vs_plo_q)):.1f} dB at the {dbm(p_lo):.1f} dBm used here')
print(f'{"P_LO [dBm]":>11} {"S_int pumped":>13} {"pumped/quiesc":>14} {"NF_DSB":>8} {"NF_DSB q":>9}')
for i in range(plo_grid.size):
    print(f'{dbm(plo_grid[i]):11.1f} {s_lo_int[i]:13.3e} {s_lo_int[i]/s_q[j_if]:14.2f} '
          f'{nf_vs_plo[i]:8.2f} {nf_vs_plo_q[i]:9.2f}')
print()
if HAVE_SHOOTING:
    print('Shooting cross-check, pac against hbac and pnoise against hbnoise:')
    print(f'  pac - hbac conversion  : {pac_vs_hbac_db.min():+.4f} .. {pac_vs_hbac_db.max():+.4f} dB, '
          'both sidebands over the IF sweep')
    print(f'  pnoise - hbnoise noise : {pn_vs_hbn_db.min():+.3f} .. {pn_vs_hbn_db.max():+.3f} dB over the IF sweep, '
          f'{pn_vs_hbn_db[j_if]:+.3f} dB at {F_IF_LO/1e9:.0f} GHz')
    print(f'  pnoise gain vs pac     : within {pn_gain_check_db:.1e} dB')
    print(f'  NF_DSB at {F_IF_LO/1e9:.0f} GHz        : {nf_dsb_pn[j_if]:.2f} dB from pnoise, {nf_dsb[j_if]:.2f} dB from hbnoise')
    print(f'  against LO drive       : pnoise - HB conversion {lo_gain_pn_db.min():+.3f} .. {lo_gain_pn_db.max():+.3f} dB, '
          f'NF {lo_nf_pn_db.min():+.3f} .. {lo_nf_pn_db.max():+.3f} dB, best NF {nf_vs_plo_pn[i_best_pn]:.1f} dB '
          f'at {dbm(plo_grid[i_best_pn]):.1f} dBm')
else:
    print('Shooting cross-check skipped: no pac and pnoise rawfiles from this run '
          '(VACASK before 1b48553 has neither analysis).')
print()
print(f'Top output-noise contributors over {lo_b:.0e} .. {hi_b:.0e} Hz, pumped, and their '
      'pumped-over-quiescent ratio:')
for _, name in contrib_p[:N_CONTRIB + 2]:
    inband = float(np.trapezoid(np.real(hn[name])[band], f_n[band]))
    inband_q = float(np.trapezoid(np.real(nz[name])[band], f_n[band])) if name in nz.names else float('nan')
    print(f'  {name:48s} {100*inband/tot_p:6.2f} %   x{inband/inband_q:.2f}')

# --- plot -----------------------------------------------------------------
fig, axes = plt.subplots(2, 2, figsize=(13, 9), constrained_layout=True)
fig.suptitle(f'SBD Power Detector {VARIANT} - Noise Figure (LO {freq_lo/1e9:.0f} GHz '
             f'at {dbm(p_lo):.1f} dBm, RF {freq_lo/1e9:.0f} GHz + IF)')

ax = axes[0, 0]
ax.loglog(f_n, asd_p, 'k', lw=2, label='output noise, LO on (hbnoise)')
ax.loglog(f_n, asd_q, 'k--', lw=1.5, label='output noise, LO off (noise)')
if HAVE_SHOOTING:
    ax.loglog(f_n[::2], np.sqrt(s_pn[::2]), 'o', color='k', mfc='none', ms=4, label='output noise, LO on (pnoise)')
for _, name in contrib_p[:N_CONTRIB]:
    ax.loglog(f_n, np.sqrt(np.real(hn[name])), lw=1, alpha=0.8, label=name)
ax.axvspan(lo_b, hi_b, color='tab:orange', alpha=0.10, label='video band')
ax.set_xlabel('Video frequency (Hz)')
ax.set_ylabel('Output noise ASD (V/$\\sqrt{\\mathrm{Hz}}$)')
ax.legend(fontsize=7)
ax.grid(True, which='both')

ax = axes[0, 1]
ax.semilogx(f_n, 20 * np.log10(v_if_ref), label=f'upper sideband, RF {dbm(P_RF_REF):.1f} dBm')
ax.semilogx(f_n, 20 * np.log10(np.sqrt(2.0 * g_l * P_RF_REF)), '--', alpha=0.7, label='lower sideband')
if HAVE_SHOOTING:
    ax.semilogx(f_n[::2], 20 * np.log10(np.sqrt(2.0 * g_u_pac[::2] * P_RF_REF)), 'o', color='tab:blue',
                mfc='none', ms=4, label='upper sideband, pac')
ax.set_xlabel('IF frequency (Hz)')
ax.set_ylabel('IF output amplitude (dBV), hbac' + (' and pac' if HAVE_SHOOTING else ''))
ax.legend(fontsize=8)
ax.grid(True, which='both')

ax = axes[1, 0]
ax.semilogx(f_n, nf_dsb, 'k', lw=2, label='NF$_{DSB}$, hbnoise')
ax.semilogx(f_n, nf_dsb_q, 'k--', lw=1.5, label='NF$_{DSB}$, small-signal noise at the dc operating point')
ax.semilogx(f_n, nf_dsb_nopnp, ':', color='tab:gray', label='hbnoise, without PCell PNP flicker')
if HAVE_SHOOTING:
    ax.semilogx(f_n[::2], nf_dsb_pn[::2], 'o', color='k', mfc='none', ms=4, label='NF$_{DSB}$, pnoise and pac')
ax.set_xlabel('IF frequency (Hz)')
ax.set_ylabel('NF$_{DSB}$ (dB)')
ax.legend(fontsize=8)
ax.grid(True, which='both')

ax = axes[1, 1]
ax.semilogx(plo_grid, nf_vs_plo, 'k', lw=2, label=f'NF$_{{DSB}}$ at IF = {F_IF_LO/1e9:g} GHz, hbnoise')
ax.semilogx(plo_grid, nf_vs_plo_q, 'k--', lw=1.5, label='small-signal noise at the dc operating point')
ax.semilogx(plo_grid, nf_vs_plo_nopnp, ':', color='tab:gray', label='hbnoise, without PCell PNP flicker')
if HAVE_SHOOTING:
    ax.semilogx(plo_grid, nf_vs_plo_pn, 'o', color='k', mfc='none', ms=4, label='pnoise')
ax.axvline(p_lo, color='tab:red', ls=':', label=f'LO used here, {dbm(p_lo):.1f} dBm')
p1db = pss.get('p_1db_W')
if p1db:
    ax.axvline(p1db, color='k', ls='--', alpha=0.4, label=f'P(1 dB) = {dbm(p1db):.1f} dBm')
ax.set_xlabel('Available LO power (W)')
ax.set_ylabel('NF$_{DSB}$ (dB)')
ax.legend(fontsize=8)
ax.grid(True, which='both')

os.makedirs(FIG_DIR, exist_ok=True)
plt.savefig(os.path.join(FIG_DIR, f'sparx_powdet_sbd_nf{SUFFIX}.png'), dpi=150)

os.makedirs(DATA_DIR, exist_ok=True)
out_file = os.path.join(DATA_DIR, f'sparx_powdet_sbd_nf{SUFFIX}.json')
with open(out_file, 'w') as f:
    json.dump({
        'variant': VARIANT or 'm1',
        'freq_lo_Hz': freq_lo,
        'p_lo_avail_W': p_lo,
        'p_rf_ref_W': P_RF_REF,
        'rs_ohm': RS,
        't0_K': T0,
        'beta_V_per_W': beta,
        'slope_at_lo_V_per_W': float(s_prime),
        'g_at_lo_V2_per_W': float(g_u[0]),
        'g_closed_form_V2_per_W': float(g_closed),
        'hbac_minus_closed_form_dB': closed_delta_db,
        'hbnoise_gain_vs_hbac_max_dB': gain_check_db,
        'hbnoise_gain_vs_hbac_lo_sweep_max_dB': gain_check_lo_db,
        'sideband_imbalance_gL_over_gU_dB': float(imb_db[j_if]),
        'mds': {f'{lo:.0e}-{hi:.0e}': {'v_rms_V': v, 'mds_W': m, 'mds_no_pnp_W': mn}
                for (lo, hi), (v, m, mn) in mds.items()},
        'nf_dsb_best_dB': float(nf_vs_plo[i_best]),
        'p_lo_best_W': float(plo_grid[i_best]),
        'nf_dsb_quiescent_best_dB': float(nf_vs_plo_q[i_best_q]),
        'p_lo_quiescent_best_W': float(plo_grid[i_best_q]),
        'f_Hz': f_n.tolist(),
        's_out_pumped_V2_per_Hz': s_p.tolist(),
        's_out_quiescent_V2_per_Hz': s_q.tolist(),
        'pumped_over_quiescent': pump_ratio.tolist(),
        'nf_dsb_dB': nf_dsb.tolist(),
        'nf_ssb_dB': nf_ssb.tolist(),
        'nf_dsb_no_pnp_dB': nf_dsb_nopnp.tolist(),
        'nf_dsb_quiescent_dB': nf_dsb_q.tolist(),
        'nf_ssb_quiescent_dB': nf_ssb_q.tolist(),
        'nf_dsb_quiescent_no_pnp_dB': nf_dsb_q_nopnp.tolist(),
        'beta_f_V_per_W': beta_f.tolist(),
        'nep_W_per_rtHz': nep.tolist(),
        'nep_no_pnp_W_per_rtHz': nep_nopnp.tolist(),
        'g_usb_V2_per_W': g_u.tolist(),
        'g_lsb_V2_per_W': g_l.tolist(),
        'nf_vs_plo': {'p_lo_W': plo_grid.tolist(),
                      's_out_pumped_V2_per_Hz': s_lo_int.tolist(),
                      'nf_dsb_dB': nf_vs_plo.tolist(),
                      'nf_dsb_no_pnp_dB': nf_vs_plo_nopnp.tolist(),
                      'nf_dsb_quiescent_dB': nf_vs_plo_q.tolist(),
                      'nf_dsb_quiescent_no_pnp_dB': nf_vs_plo_q_nopnp.tolist()},
        # None when the run had no pac and pnoise analyses.
        'shooting_check': {
            'pac_minus_hbac_dB': [float(pac_vs_hbac_db.min()), float(pac_vs_hbac_db.max())],
            'pnoise_minus_hbnoise_dB': [float(pn_vs_hbn_db.min()), float(pn_vs_hbn_db.max())],
            'pnoise_minus_hbnoise_at_f_if_lo_dB': float(pn_vs_hbn_db[j_if]),
            'pnoise_gain_vs_pac_max_dB': pn_gain_check_db,
            'lo_sweep_conversion_pnoise_minus_hbac_dB': [float(lo_gain_pn_db.min()), float(lo_gain_pn_db.max())],
            'lo_sweep_nf_pnoise_minus_hb_dB': [float(lo_nf_pn_db.min()), float(lo_nf_pn_db.max())],
            'nf_dsb_pnoise_best_dB': float(nf_vs_plo_pn[i_best_pn]),
            'p_lo_pnoise_best_W': float(plo_grid[i_best_pn]),
            'nf_dsb_pnoise_dB': nf_dsb_pn.tolist(),
            's_out_pnoise_V2_per_Hz': s_pn.tolist(),
            'g_usb_pac_V2_per_W': g_u_pac.tolist(),
            'g_lsb_pac_V2_per_W': g_l_pac.tolist(),
            'nf_vs_plo_nf_dsb_pnoise_dB': nf_vs_plo_pn.tolist(),
            'nf_vs_plo_g_usb_pnoise_V2_per_W': g_lo_pn.tolist(),
        } if HAVE_SHOOTING else None,
        'source': TB,
    }, f, indent=2)
print(f'\nWrote {out_file}')

# --- CSV for pgfplots -------------------------------------------------------
# nf_dsb_db and nf_ssb_db carry the hbnoise result. The pre-hbnoise estimate is
# kept as nf_dsb_quiescent_db so a figure built on it can still be reproduced.
# The pac and pnoise columns are appended, so existing column names keep their place.
cols = [f_n, asd_q, beta_f, nep, nep_nopnp, g_u, g_l, 20 * np.log10(v_if_ref), nf_dsb, nf_ssb,
        nf_dsb_nopnp, asd_p, nf_dsb_q, nf_ssb_q, nf_dsb_q_nopnp]
header = ('f_hz,asd_v,beta_f_vw,nep_w,nep_nopnp_w,g_usb,g_lsb,vif_dbv,nf_dsb_db,nf_ssb_db,'
          'nf_dsb_nopnp_db,asd_pumped_v,nf_dsb_quiescent_db,nf_ssb_quiescent_db,'
          'nf_dsb_quiescent_nopnp_db')
cols_lo = [dbm(plo_grid), nf_vs_plo, nf_vs_plo_nopnp, g_lo_grid, s_lo_int, nf_vs_plo_q, nf_vs_plo_q_nopnp]
header_lo = 'plo_dbm,nf_dsb_db,nf_dsb_nopnp_db,g_usb,s_out_pumped,nf_dsb_quiescent_db,nf_dsb_quiescent_nopnp_db'
if HAVE_SHOOTING:
    cols += [g_u_pac, g_l_pac, np.sqrt(s_pn), nf_dsb_pn]
    header += ',g_usb_pac,g_lsb_pac,asd_pnoise_v,nf_dsb_pnoise_db'
    cols_lo += [g_lo_pn, s_lo_int_pn, nf_vs_plo_pn]
    header_lo += ',g_usb_pnoise,s_out_pnoise,nf_dsb_pnoise_db'
csv_f = os.path.join(DATA_DIR, f'sparx_powdet_sbd_nf{SUFFIX}.csv')
np.savetxt(csv_f, np.column_stack(cols), delimiter=',', comments='', fmt='%.6e', header=header)
csv_lo = os.path.join(DATA_DIR, f'sparx_powdet_sbd_nf_lo{SUFFIX}.csv')
np.savetxt(csv_lo, np.column_stack(cols_lo), delimiter=',', comments='', fmt='%.6e', header=header_lo)
print(f'Wrote {csv_f}\nWrote {csv_lo}')

if SHOW_PLOTS:
    plt.show()
