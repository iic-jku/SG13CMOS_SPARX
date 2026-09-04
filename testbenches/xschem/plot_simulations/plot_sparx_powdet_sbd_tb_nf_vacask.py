# SPDX-FileCopyrightText: 2025-2026 The SPARX Team
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# Description: Noise figure, NEP and MDS of the SBD power detector from VACASK noise + hbac.

# NOISE FIGURE OF THE SBD POWER DETECTOR.
#
# A power detector is not a two-port with power gain, so on its own it has no
# noise figure. Driven by the six-port's LO it is a mixer, and a mixer noise
# figure is well defined. Two analyses supply it:
#
#   powdet_nf_noise      small-signal noise. Output noise PSD S_int(f) over
#                        the video band, a BASEBAND quantity, so no RF
#                        transfer function is involved.
#   powdet_nf_hbac_usb   periodic small-signal (hbac) analysis around the
#   powdet_nf_hbac_lsb   single-tone HB operating point of the LO. A unit
#                        small-signal tone at LO + f (upper sideband) or LO - f
#                        (lower sideband) gives the output phasor at the IF f.
#   powdet_nf_hbac_lo    the same at one IF against the LO amplitude.
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
# The g_L / g_U term in F_SSB is the source noise that enters through the
# image sideband and is counted as noise, not signal, in the single-sideband
# definition. It is what makes an ideal symmetric mixer read 3 dB SSB and
# 0 dB DSB. On this detector S_int dominates by 35 dB or more, so the term
# is invisible in the result, but the definition is kept exact.
#
# The closed form of a square-law detector, V_IF = 2 S'(P_lo) sqrt(P_lo P_rf)
# with S' the local slope of the transfer curve at the LO drive, is kept as a
# check on the hbac level: when hbac was introduced the two agreed to 0.13 dB
# at low IF and 0.5 dB at 5 GHz, and two-tone HB sat 0.13 dB from hbac at
# 2 GHz. The ngspice two-tone bench is the independent cross-simulator check.
#
# Detector figures of merit come from the same S_int and the responsivity:
#
#   NEP(f) = sqrt(S_int(f)) / |beta(f)|         [W/sqrt(Hz)]
#   MDS    = v_n,rms(video band) / |beta(0)|    [W], SNR = 1
#
# beta(f) is the responsivity at the video frequency f. It rolls off with the
# same baseband network as the conversion, so the hbac shape g_U(f)/g_U(0)
# supplies it. Dividing the noise at 5 GHz by the DC responsivity would
# understate the NEP there by 20 dB.
#
# LIMITATION. VACASK a9d8860 has hbac but no pnoise, so there is no noise
# analysis around the pumped operating point. S_int is taken at the DC
# operating point and carries neither the LO-induced bias shift nor noise
# folding from the LO harmonics. The conversion in the denominator IS the
# large-signal one.
#
# MODEL CAVEAT. Over the whole video band more than 90 % of S_int comes from
# the flicker noise of the parasitic PNP inside the Schottky PCell
# (n(<diode>:q1)), a device that carries about 10 pA here and whose flicker
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
HBAC_USB = 'powdet_nf_hbac_usb.raw'
HBAC_LSB = 'powdet_nf_hbac_lsb.raw'
HBAC_LO = 'powdet_nf_hbac_lo.raw'
SOURCE_RES = 'Rs'         # instance name of the source resistor in the testbench
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
# single value of the powdet_nf_hbac_lo sweep in the testbench.
F_IF_LO = 2e9
N_CONTRIB = 4
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


with open(NETLIST) as f:
    netlist = f.read()
freq_lo = parse_var(netlist, 'freq_lo')
ampl_lo = parse_var(netlist, 'ampl_lo')
p_lo = ampl_lo ** 2 / (8.0 * RS)             # available LO power [W]
p_a = SMAG ** 2 / (8.0 * RS)                 # available power of the unit small-signal tone [W]

# --- output noise PSD -----------------------------------------------------
nz = rawread(os.path.join(SIM_DIR, NOISE_RAW)).get()
f_n = np.real(nz['frequency'])
s_out = np.real(nz['onoise'])                # [V^2/Hz], everything in the deck
# The source resistor's own baseband noise is part of the source, not of the
# detector, so it comes out of S_int. It is blocked by the input coupling
# capacitor and amounts to well under 0.1 % of the power here.
src_vec = f'n({SOURCE_RES})'
s_src = np.real(nz[src_vec]) if src_vec in nz.names else np.zeros_like(s_out)
s_int = s_out - s_src
asd = np.sqrt(s_int)

pnp_vecs = [n for n in nz.names if PNP_PATTERN.match(n)]
if not pnp_vecs:
    raise RuntimeError(f'No n(xdemod1:<diode>:q1) vector in {NOISE_RAW}. The noise analysis '
                       'needs `save full`, and the diodes must sit inside xdemod1.')
s_pnp = sum(np.real(nz[n]) for n in pnp_vecs)
s_nopnp = np.clip(s_int - s_pnp, 0, None)

contrib = sorted(((float(np.trapezoid(np.real(nz[n]), f_n)), n)
                  for n in nz.names if n.startswith('n(') and ',' not in n and n != src_vec),
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

# --- noise figures ---------------------------------------------------------
def noise_figures(s, gu, gl):
    f_dsb = 1.0 + s / ((gu + gl) * K_B * T0)
    f_ssb = 1.0 + gl / gu + s / (gu * K_B * T0)
    return db(f_dsb), db(f_ssb)


nf_dsb, nf_ssb = noise_figures(s_int, g_u, g_l)
nf_dsb_nopnp, _ = noise_figures(s_nopnp, g_u, g_l)

# --- noise figure against LO drive, from the hbac LO sweep -----------------
h = rawread(os.path.join(SIM_DIR, HBAC_LO)).get(sweeps=1)
name_lo = next(n for n in h.names if n.startswith('out;'))
plo_grid, g_lo_grid = [], []
for gi in range(h.sweepGroups):
    a = float(np.abs(h.sweepData(gi)['a_lo']))
    v_if = float(np.abs(h[gi, name_lo])[0])
    plo_grid.append(a * a / (8.0 * RS))
    g_lo_grid.append((v_if ** 2 / 2.0) / p_a)
order = np.argsort(plo_grid)
plo_grid = np.asarray(plo_grid)[order]
g_lo_grid = np.asarray(g_lo_grid)[order]
j_if = int(np.argmin(np.abs(f_n - F_IF_LO)))
# The sweep measures the upper sideband, the lower one follows from the
# imbalance at that IF, 0.1 dB here.
nf_vs_plo, _ = noise_figures(s_int[j_if], g_lo_grid, g_lo_grid * (g_l[j_if] / g_u[j_if]))
nf_vs_plo_nopnp, _ = noise_figures(s_nopnp[j_if], g_lo_grid, g_lo_grid * (g_l[j_if] / g_u[j_if]))
i_best = int(np.argmin(nf_vs_plo))

# --- responsivity, NEP, MDS --------------------------------------------------
if not os.path.isfile(BETA_FILE):
    raise RuntimeError(f'{BETA_FILE} is missing. Run the PSS testbench first: '
                       'make sim-xschem TB=sparx_powdet_sbd_tb_pss_vacask'
                       + (f' VARIANT={VARIANT}' if VARIANT else ''))
with open(BETA_FILE) as f:
    pss = json.load(f)
beta = abs(float(pss['beta_V_per_W']))
beta_f = beta * np.sqrt(shape_n)             # responsivity at the video frequency
nep = asd / beta_f
nep_nopnp = np.sqrt(s_nopnp) / beta_f
mds = {}
for lo, hi in VIDEO_BANDS:
    band = (f_n >= lo) & (f_n <= hi)
    v_rms = float(np.sqrt(np.trapezoid(s_int[band], f_n[band])))
    v_rms_np = float(np.sqrt(np.trapezoid(s_nopnp[band], f_n[band])))
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
print(f'Variant               : {VARIANT or "as fabricated"}')
print(f'LO                    : {freq_lo/1e9:.1f} GHz at {dbm(p_lo):.1f} dBm available')
print(f'Responsivity beta     : {beta:.4g} V/W  (small signal, from the PSS testbench)')
print(f'Conversion g at LO    : {g_u[0]:.4g} V^2/W at low IF from hbac, closed form '
      f'2 S\'^2 P_lo = {g_closed:.4g} V^2/W (S\' = {abs(s_prime):.4g} V/W), '
      f'hbac - closed form = {closed_delta_db:+.2f} dB')
print(f'IF output at {dbm(P_RF_REF):.1f} dBm RF: {v_if_ref[0]*1e6:.1f} uV at low IF, '
      f'{loginterp(2e9, f_n, v_if_ref)*1e6:.1f} uV at 2 GHz')
print(f'Video bandwidth       : {f_n[np.where(shape_n < 0.5)[0][0]]/1e9:.2f} GHz (-3 dB of the conversion)'
      if np.any(shape_n < 0.5) else 'Video bandwidth       : above the swept range')
print(f'Sideband imbalance    : g_L/g_U = {imb_db[j_if]:+.2f} dB at {F_IF_LO/1e9:.0f} GHz')
for (lo, hi), (v_rms, m, m_np) in mds.items():
    print(f'Video band {lo:.0e} .. {hi:.0e} Hz : {v_rms*1e6:7.1f} uV RMS, '
          f'MDS {dbm(m):6.1f} dBm  (without PCell PNP: {dbm(m_np):6.1f} dBm)')
print()
print(f'{"f_IF":>10} {"S_int ASD":>11} {"beta(f)":>9} {"NF_DSB":>8} {"NF_SSB":>8} '
      f'{"NEP":>11} {"NF_DSB":>8} {"NEP":>11}')
print(f'{"[Hz]":>10} {"[V/rtHz]":>11} {"[V/W]":>9} {"[dB]":>8} {"[dB]":>8} '
      f'{"[W/rtHz]":>11} {"no PNP":>8} {"no PNP":>11}')
for target in (1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 5e8, 1e9, 2e9, 5e9):
    if target < f_n[0] or target > f_n[-1]:
        continue
    j = int(np.argmin(np.abs(f_n - target)))
    print(f'{f_n[j]:10.3e} {asd[j]:11.3e} {beta_f[j]:9.3g} {nf_dsb[j]:8.2f} '
          f'{nf_ssb[j]:8.2f} {nep[j]:11.3e} {nf_dsb_nopnp[j]:8.2f} {nep_nopnp[j]:11.3e}')
print()
print(f'Noise figure against LO drive at {F_IF_LO/1e9:.0f} GHz IF, from the hbac LO sweep:')
print(f'  best {nf_vs_plo[i_best]:.1f} dB at {dbm(plo_grid[i_best]):.1f} dBm LO, '
      f'{float(np.interp(np.log10(p_lo), np.log10(plo_grid), nf_vs_plo)):.1f} dB at the {dbm(p_lo):.1f} dBm used here')
print()
lo, hi = VIDEO_BANDS[-1]
band = (f_n >= lo) & (f_n <= hi)
tot = float(np.trapezoid(s_int[band], f_n[band]))
print(f'Top output-noise contributors over {lo:.0e} .. {hi:.0e} Hz:')
for _, name in contrib[:N_CONTRIB + 2]:
    inband = float(np.trapezoid(np.real(nz[name])[band], f_n[band]))
    print(f'  {name:48s} {100*inband/tot:6.2f} %')

# --- plot -----------------------------------------------------------------
fig, axes = plt.subplots(2, 2, figsize=(13, 9), constrained_layout=True)
fig.suptitle(f'SBD Power Detector {VARIANT} - Noise Figure (LO {freq_lo/1e9:.0f} GHz '
             f'at {dbm(p_lo):.1f} dBm, RF {freq_lo/1e9:.0f} GHz + IF)')

ax = axes[0, 0]
ax.loglog(f_n, asd, 'k', lw=2, label='detector output noise')
for _, name in contrib[:N_CONTRIB]:
    ax.loglog(f_n, np.sqrt(np.real(nz[name])), lw=1, alpha=0.8, label=name)
ax.axvspan(lo, hi, color='tab:orange', alpha=0.10, label='video band')
ax.set_xlabel('Video frequency (Hz)')
ax.set_ylabel('Output noise ASD (V/$\\sqrt{\\mathrm{Hz}}$)')
ax.legend(fontsize=7)
ax.grid(True, which='both')

ax = axes[0, 1]
ax.semilogx(f_n, 20 * np.log10(v_if_ref), label=f'upper sideband, RF {dbm(P_RF_REF):.1f} dBm')
ax.semilogx(f_n, 20 * np.log10(np.sqrt(2.0 * g_l * P_RF_REF)), '--', alpha=0.7, label='lower sideband')
ax.set_xlabel('IF frequency (Hz)')
ax.set_ylabel('IF output amplitude (dBV), hbac')
ax.legend(fontsize=8)
ax.grid(True, which='both')

ax = axes[1, 0]
ax.loglog(f_n, nep, label='NEP')
ax.loglog(f_n, nep_nopnp, ':', color='tab:gray', label='NEP without PCell PNP flicker')
ax.set_xlabel('Video (modulation) frequency (Hz)')
ax.set_ylabel('NEP (W/$\\sqrt{\\mathrm{Hz}}$)')
ax.legend(fontsize=8)
ax.grid(True, which='both')

ax = axes[1, 1]
ax.semilogx(plo_grid, nf_vs_plo, label=f'NF$_{{DSB}}$ at IF = {F_IF_LO/1e9:g} GHz')
ax.semilogx(plo_grid, nf_vs_plo_nopnp, ':', color='tab:gray', label='without PCell PNP flicker')
ax.axvline(p_lo, color='tab:red', ls=':', label=f'LO used here, {dbm(p_lo):.1f} dBm')
p1db = pss.get('p_1db_W')
if p1db:
    ax.axvline(p1db, color='k', ls='--', alpha=0.4, label=f'P(1 dB) = {dbm(p1db):.1f} dBm')
ax.set_xlabel('Available LO power (W)')
ax.set_ylabel('NF$_{DSB}$ (dB), hbac')
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
        'sideband_imbalance_gL_over_gU_dB': float(imb_db[j_if]),
        'mds': {f'{lo:.0e}-{hi:.0e}': {'v_rms_V': v, 'mds_W': m, 'mds_no_pnp_W': mn}
                for (lo, hi), (v, m, mn) in mds.items()},
        'nf_dsb_best_dB': float(nf_vs_plo[i_best]),
        'p_lo_best_W': float(plo_grid[i_best]),
        'f_Hz': f_n.tolist(),
        'nf_dsb_dB': nf_dsb.tolist(),
        'nf_ssb_dB': nf_ssb.tolist(),
        'nf_dsb_no_pnp_dB': nf_dsb_nopnp.tolist(),
        'beta_f_V_per_W': beta_f.tolist(),
        'nep_W_per_rtHz': nep.tolist(),
        'nep_no_pnp_W_per_rtHz': nep_nopnp.tolist(),
        'g_usb_V2_per_W': g_u.tolist(),
        'g_lsb_V2_per_W': g_l.tolist(),
        'nf_vs_plo': {'p_lo_W': plo_grid.tolist(), 'nf_dsb_dB': nf_vs_plo.tolist(),
                      'nf_dsb_no_pnp_dB': nf_vs_plo_nopnp.tolist()},
        'source': TB,
    }, f, indent=2)
print(f'\nWrote {out_file}')

# --- CSV for pgfplots -------------------------------------------------------
csv_f = os.path.join(DATA_DIR, f'sparx_powdet_sbd_nf{SUFFIX}.csv')
np.savetxt(csv_f,
           np.column_stack((f_n, asd, beta_f, nep, nep_nopnp, g_u, g_l,
                            20 * np.log10(v_if_ref), nf_dsb, nf_ssb, nf_dsb_nopnp)),
           delimiter=',', comments='', fmt='%.6e',
           header='f_hz,asd_v,beta_f_vw,nep_w,nep_nopnp_w,g_usb,g_lsb,vif_dbv,nf_dsb_db,nf_ssb_db,nf_dsb_nopnp_db')
csv_lo = os.path.join(DATA_DIR, f'sparx_powdet_sbd_nf_lo{SUFFIX}.csv')
np.savetxt(csv_lo, np.column_stack((dbm(plo_grid), nf_vs_plo, nf_vs_plo_nopnp, g_lo_grid)),
           delimiter=',', comments='', fmt='%.6e', header='plo_dbm,nf_dsb_db,nf_dsb_nopnp_db,g_usb')
print(f'Wrote {csv_f}\nWrote {csv_lo}')

if SHOW_PLOTS:
    plt.show()
