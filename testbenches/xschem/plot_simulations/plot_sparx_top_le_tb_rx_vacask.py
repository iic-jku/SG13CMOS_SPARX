# SPDX-FileCopyrightText: 2026 The SPARX Team
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# Description: Receiver-level results of the six-port: IF outputs of the four detectors from HBAC and transient.

# RECEIVER-LEVEL RESULTS OF THE SIX-PORT (full-core fit plus four detectors).
#
# Reads the rawfiles of sparx_top_le_tb_rx_vacask:
#
#   rx_hb.raw        single-tone HB at the LO: the LO amplitude that reaches each
#                    detector input (x1:net1..4), so the pad-to-detector loss of
#                    the LO path is a number and not an estimate
#   rx_hbac_if.raw   IF response of the four detectors, out1..4 at spur 0, for a
#                    unit RF spur, against the IF from 1 MHz to 5 GHz
#   rx_hbac_lo.raw   the same at 2 GHz against the LO amplitude (sweep a_lo)
#   rx_hb2.raw       two-tone HB at the transient's levels (optional cross-check)
#   rx_tran.raw      transient, the last nanosecond of the four differential outputs
#
# The RF level for the IF outputs is P_RF_PAD, the available power at the RF
# pad. hbac drives a unit spur (1 V behind 50 Ohm, 2.5 mW available), and the
# conversion is linear in the RF, so the IF amplitude at P_RF_PAD is the hbac
# output scaled by sqrt(P_RF_PAD / P_SPUR).
#
# Six-port reading of the four outputs: the IF phasors at the four detectors
# fall into two pairs that are 180 degrees apart. Each pair's difference is one
# baseband component, I and Q, and the angle between the two differences is the
# quadrature error of the receiver.
#
# Writes figures/sparx_top_le_rx<suffix>.png, data/sparx_top_le_rx<suffix>.json and
# three CSVs for pgfplots: data/sparx_top_le_rx_tran<suffix>.csv (t_ns, out1_mv..
# out4_mv), data/sparx_top_le_rx_lo<suffix>.csv (plo_dbm, vif1_dbv..vif4_dbv,
# ph1_deg..ph4_deg) and data/sparx_top_le_rx_if<suffix>.csv (f_hz, vif1_dbv..
# vif4_dbv).
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
SHOW_PLOTS = os.environ.get('SHOW_PLOTS', '0') == '1'
if not SHOW_PLOTS:
    matplotlib.use('Agg')
import matplotlib.pyplot as plt

TB = 'sparx_top_le_tb_rx_vacask'
RS = 50.0                     # source resistance at both pads [Ohm]
P_SPUR = 1.0 ** 2 / (8 * RS)  # available power of the unit hbac spur [W]
P_RF_PAD = 1e-5               # -20 dBm at the RF pad [W]
F_IF = 2e9
VARIANT = os.environ.get('POWDET_VARIANT', '').strip()
SUFFIX = f'_{VARIANT}' if VARIANT else ''
# Detector input impedance at 161 GHz, for the power a detector takes from the
# voltage the HB spectrum shows at its input. Read from the PSS bench of the
# same variant when it has run, the schematic value otherwise.
Z_DET_DEFAULT = complex(51.0, -10.0)


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
OUTS = ['out1', 'out2', 'out3', 'out4']
DETS = ['x1:net1', 'x1:net2', 'x1:net3', 'x1:net4']


def parse_var(netlist, name):
    m = re.search(rf'var\s+{name}\s*=\s*([\d.eE+\-]+[GMKkTmu]?)', netlist)
    val = m.group(1)
    for suf, exp in (('G', 'e9'), ('M', 'e6'), ('K', 'e3'), ('k', 'e3'), ('T', 'e12'), ('m', 'e-3'), ('u', 'e-6')):
        val = val.replace(suf, exp)
    return float(val)


def dbm(p):
    return 10.0 * np.log10(p / 1e-3)


def dbv(v):
    return 20.0 * np.log10(v)


def avail_dbm(a):
    return dbm(a * a / (8 * RS))


def vec(raw, name):
    """Find a vector by name, tolerant to the `;0` spur suffix and to v(...) wrappers."""
    for n in raw.names:
        base = n.split(';')[0]
        if base == name or base == f'v({name})':
            return raw[n]
    raise KeyError(f'{name} not among {list(raw.names)}')


with open(NETLIST) as f:
    netlist = f.read()
freq_lo = parse_var(netlist, 'freq_lo')
freq_rf = parse_var(netlist, 'freq_rf')
ampl_lo = parse_var(netlist, 'ampl_lo')
ampl_rf = parse_var(netlist, 'ampl_rf')

summary = {'variant': VARIANT or 'm1', 'freq_lo_Hz': freq_lo, 'freq_rf_Hz': freq_rf,
           'p_lo_pad_dBm': avail_dbm(ampl_lo), 'p_rf_pad_dBm': dbm(P_RF_PAD)}

z_det = Z_DET_DEFAULT
beta_file = os.path.join(DATA_DIR, f'sparx_powdet_sbd_beta{SUFFIX}.json')
if os.path.isfile(beta_file):
    with open(beta_file) as f:
        re_z, im_z = json.load(f)['z_in_small_signal_ohm']
    z_det = complex(re_z, im_z)
g_det = (1.0 / z_det).real
print(f'Variant             : {VARIANT or "as fabricated"}')
print(f'Detector Z_in       : {z_det.real:.1f} {z_det.imag:+.1f}j Ohm at 161 GHz ({"PSS bench" if os.path.isfile(beta_file) else "default"})')

# --- (0) RF reaching each detector, from the HB spectrum at freq_rf, RF alone ----
p_rf_pad_hb = ampl_rf ** 2 / (8 * RS)
hbr = rawread(os.path.join(SIM_DIR, 'rx_hb_rf.raw')).get()
fr = np.real(hbr['frequency'])
i_rf = int(np.argmin(np.abs(fr - freq_rf)))
rf_loss = []
print(f'RF at the pad       : {dbm(p_rf_pad_hb):+.1f} dBm available ({ampl_rf*1e3:.1f} mV behind {RS:.0f} Ohm), {freq_rf/1e9:.0f} GHz, LO off')
print('RF at the detectors (HB fundamental at the detector input):')
for k, n in enumerate(DETS):
    v = abs(vec(hbr, n)[i_rf])
    p = 0.5 * v * v * g_det
    rf_loss.append(dbm(p_rf_pad_hb) - dbm(p))
    print(f'   detector {k+1}: {v*1e3:7.2f} mV, {dbm(p):+6.1f} dBm, loss from the pad {rf_loss[-1]:5.1f} dB')
summary['rf_path_loss_dB'] = rf_loss

# --- (1) LO reaching each detector, from the HB spectrum at freq_lo -------------
hb = rawread(os.path.join(SIM_DIR, 'rx_hb.raw')).get()
fq = np.real(hb['frequency'])
i_lo = int(np.argmin(np.abs(fq - freq_lo)))
p_lo_det = []
lo_loss = []
print(f'LO at the pad       : {avail_dbm(ampl_lo):+.1f} dBm available ({ampl_lo:.3g} V behind {RS:.0f} Ohm), {freq_lo/1e9:.0f} GHz')
print('LO at the detectors (HB fundamental at the detector input):')
for k, n in enumerate(DETS):
    v = abs(vec(hb, n)[i_lo])
    p = 0.5 * v * v * g_det
    p_lo_det.append(p)
    lo_loss.append(avail_dbm(ampl_lo) - dbm(p))
    print(f'   detector {k+1}: {v*1e3:7.1f} mV, {dbm(p):+6.1f} dBm, loss from the pad {lo_loss[-1]:5.1f} dB')
summary['p_lo_det_dBm'] = [dbm(p) for p in p_lo_det]
summary['lo_path_loss_dB'] = lo_loss

# --- (2) IF response of the four detectors -------------------------------------
hif = rawread(os.path.join(SIM_DIR, 'rx_hbac_if.raw')).get()
f_if = np.real(hif['frequency'])
scale = np.sqrt(P_RF_PAD / P_SPUR)
vif_f = np.array([np.abs(vec(hif, o)) * scale for o in OUTS])       # [4, nf] IF amplitude at P_RF_PAD
i2g = int(np.argmin(np.abs(f_if - F_IF)))
i_lo_f = int(np.argmin(np.abs(f_if - 1e6)))
print(f'RF at the pad       : {dbm(P_RF_PAD):+.1f} dBm available, IF {F_IF/1e9:.0f} GHz')
print('IF output of the four detectors at that RF:')
for k, o in enumerate(OUTS):
    bw = f_if[np.where(vif_f[k] >= vif_f[k][i_lo_f] / np.sqrt(2))[0][-1]]
    print(f'   {o}: {vif_f[k][i_lo_f]*1e6:8.1f} uV at 1 MHz, {vif_f[k][i2g]*1e6:8.1f} uV at {F_IF/1e9:.0f} GHz, -3 dB at {bw/1e9:.2f} GHz')
summary['vif_1MHz_V'] = vif_f[:, i_lo_f].tolist()
summary['vif_2GHz_V'] = vif_f[:, i2g].tolist()

# --- (3) IF against LO power at the pad, with the six-port phases --------------
hlo = rawread(os.path.join(SIM_DIR, 'rx_hbac_lo.raw')).get(sweeps=1)
plo, vif_lo, ph_lo = [], [], []
for g in range(hlo.sweepGroups):
    a = float(np.abs(hlo.sweepData(g)['a_lo']))
    fr = np.real(hlo[g, 'frequency'])
    i = int(np.argmin(np.abs(fr - F_IF)))
    row = np.array([vec_g[i] for vec_g in (hlo[g, n] for n in [nm for nm in hlo.names if nm.split(';')[0] in OUTS])])
    # keep the order out1..out4
    names = [nm for nm in hlo.names if nm.split(';')[0] in OUTS]
    order = [names.index(next(nm for nm in names if nm.split(';')[0] == o)) for o in OUTS]
    row = row[order] * scale
    plo.append(avail_dbm(a))
    vif_lo.append(np.abs(row))
    ph_lo.append(np.degrees(np.angle(row)))
order = np.argsort(plo)
plo = np.asarray(plo)[order]
vif_lo = np.asarray(vif_lo)[order]
ph_lo = np.asarray(ph_lo)[order]

# six-port pairing at the operating point: the two outputs 180 degrees from out1 and from
# the other one form the pairs, I = pair 1 difference, Q = pair 2 difference
i_op = int(np.argmin(np.abs(plo - avail_dbm(ampl_lo))))
ph = ph_lo[i_op]
amp = vif_lo[i_op]
rel = (ph - ph[0] + 180) % 360 - 180
partner = int(np.argmin(np.abs(np.abs(rel[1:]) - 180))) + 1       # the output opposite to out1
others = [k for k in range(1, 4) if k != partner]
ph_c = np.radians(ph)
i_ph = amp[0] * np.exp(1j * ph_c[0]) - amp[partner] * np.exp(1j * ph_c[partner])
q_ph = amp[others[0]] * np.exp(1j * ph_c[others[0]]) - amp[others[1]] * np.exp(1j * ph_c[others[1]])
iq_ratio_db = 20 * np.log10(abs(i_ph) / abs(q_ph))
iq_angle = (np.degrees(np.angle(q_ph / i_ph)) + 180) % 360 - 180
print(f'Six-port at {plo[i_op]:+.1f} dBm LO, {F_IF/1e9:.0f} GHz IF: phases relative to out1 '
      + ', '.join(f'{o} {r:+.0f} deg' for o, r in zip(OUTS, rel))
      + f'; pairs (out1, out{partner+1}) and (out{others[0]+1}, out{others[1]+1}); '
      f'I/Q amplitude ratio {iq_ratio_db:+.1f} dB, angle between I and Q {iq_angle:+.1f} deg')
# exactly at the two LO levels the text quotes, interpolated in dB on the sweep grid
vif_at = {}
for target in (3.0, 12.0):
    v = np.array([10 ** (np.interp(target, plo, 20 * np.log10(vif_lo[:, k])) / 20) for k in range(4)])
    vif_at[target] = v
    print(f'   at {target:+.1f} dBm LO at the pad: IF ' + ', '.join(f'{x*1e6:.0f} uV' for x in v))
summary.update({'plo_pad_dBm': plo.tolist(), 'vif_2GHz_vs_plo_V': vif_lo.tolist(), 'phase_deg_vs_plo': ph_lo.tolist(),
                'pairs': [[0, partner], others], 'iq_amplitude_ratio_dB': float(iq_ratio_db), 'iq_angle_deg': float(iq_angle),
                'vif_2GHz_at_3dBm_V': vif_at[3.0].tolist(), 'vif_2GHz_at_12dBm_V': vif_at[12.0].tolist()})

# --- (4) two-tone HB cross-check (optional) -------------------------------------
hb2_path = os.path.join(SIM_DIR, 'rx_hb2.raw')
if os.path.isfile(hb2_path) and os.path.getsize(hb2_path) > 0:
    try:
        hb2 = rawread(hb2_path).get(sweeps=1)
        g = hb2.sweepGroups - 1
        fr = np.real(hb2[g, 'frequency'])
        i = int(np.argmin(np.abs(fr - F_IF)))
        a2 = float(np.abs(hb2.sweepData(g)['a_lo2']))
        v2 = np.array([abs(hb2[g, o][i]) for o in OUTS])
        # the transient's RF is ampl_rf, the hbac numbers above are at P_RF_PAD
        p_rf_tran = ampl_rf ** 2 / (8 * RS)
        ref = vif_lo[int(np.argmin(np.abs(plo - avail_dbm(a2))))] * np.sqrt(p_rf_tran / P_RF_PAD)
        print(f'Two-tone HB at {avail_dbm(a2):+.1f} dBm LO, {dbm(p_rf_tran):+.1f} dBm RF: IF '
              + ', '.join(f'{v*1e6:.0f} uV' for v in v2) + '; against hbac '
              + ', '.join(f'{20*np.log10(v/r):+.2f} dB' for v, r in zip(v2, ref)))
        summary['two_tone_vs_hbac_dB'] = [float(20 * np.log10(v / r)) for v, r in zip(v2, ref)]
    except Exception as e:                                     # a failed sweep leaves a partial rawfile
        print(f'Note: two-tone HB rawfile unusable ({e}), the cross-check is skipped.')
else:
    print('Note: rx_hb2.raw is missing, the two-tone cross-check is skipped.')

# --- (5) transient: the last nanosecond of the four differential outputs --------
tr = rawread(os.path.join(SIM_DIR, 'rx_tran.raw')).get()
t = np.real(tr['time'])
o = np.argsort(t)
t = t[o]
win = t >= t[-1] - 1e-9
outs_t = np.array([np.real(vec(tr, n))[o] for n in OUTS])
dc = outs_t[:, win].mean(axis=1)
ac = (outs_t[:, win] - dc[:, None]) * 1e3                   # [mV]
t_ns = (t[win] - t[win][0]) * 1e9
# The IF amplitude is the 2 GHz fundamental, fitted by least squares over the
# window. Half the peak-to-peak would include the carrier ripple that rides on
# the outputs and read up to 1.4 dB high.
tw = t[win]
# The constant and linear columns absorb the residual dc and settling drift: over an
# integer number of IF periods t*sin correlates with the basis, so without them a
# drift of d uV/ns biases the fundamental by up to d/2 uV.
basis = np.column_stack([np.cos(2 * np.pi * F_IF * tw), np.sin(2 * np.pi * F_IF * tw),
                         np.ones_like(tw), tw - tw[0]])
fund = []
for a in ac:
    coef, *_ = np.linalg.lstsq(basis, a * 1e-3, rcond=None)
    fund.append(float(np.hypot(coef[0], coef[1])))
fund = np.array(fund)
i_hb = int(np.argmin(np.abs(plo - avail_dbm(ampl_lo))))
ref_tr = vif_lo[i_hb] * np.sqrt(ampl_rf ** 2 / (8 * RS) / P_RF_PAD)
print('Transient, last nanosecond: 2 GHz fundamental of the four differential outputs '
      + ', '.join(f'{v*1e6:.0f} uV' for v in fund)
      + '; against hbac ' + ', '.join(f'{20*np.log10(v/r):+.2f} dB' for v, r in zip(fund, ref_tr))
      + f' (dc {", ".join(f"{d*1e3:.2f} mV" for d in dc)})')
summary['tran_if_amplitude_V'] = fund.tolist()
summary['tran_vs_hbac_dB'] = [float(20 * np.log10(v / r)) for v, r in zip(fund, ref_tr)]

# --- files ------------------------------------------------------------------------
os.makedirs(DATA_DIR, exist_ok=True)
os.makedirs(FIG_DIR, exist_ok=True)
# The CSV holds the outputs averaged over one LO period, which takes out the
# carrier ripple that rides on them (the feed-through the off-chip capacitor
# leaves), and resampled onto a 1 ps grid: the 50 fs integrator grid is 20000
# rows per trace, more than pgfplots can hold. The PNG above keeps the raw
# outputs, the fundamental fit is not affected by either step.
dt = float(np.median(np.diff(t[win])))
n_avg = max(1, int(round(1.0 / freq_lo / dt)))
box = np.ones(n_avg) / n_avg
# Edge-extend before the convolution: a plain mode='same' pads with zeros and pulls
# the first and last half window (about 3 ps) of the trace toward zero.
pad = n_avg // 2
ac_avg = np.array([np.convolve(np.pad(a, pad, mode='edge'), box, mode='same')[pad:-pad]
                   for a in ac])
t_grid = np.arange(0.0, 1.0 + 0.5e-3, 1e-3)
np.savetxt(os.path.join(DATA_DIR, f'sparx_top_le_rx_tran{SUFFIX}.csv'),
           np.column_stack([t_grid] + [np.interp(t_grid, t_ns, ac_avg[k]) for k in range(4)]),
           delimiter=',', comments='', fmt='%.6e', header='t_ns,out1_mv,out2_mv,out3_mv,out4_mv')
np.savetxt(os.path.join(DATA_DIR, f'sparx_top_le_rx_lo{SUFFIX}.csv'),
           np.column_stack([plo] + [dbv(vif_lo[:, k]) for k in range(4)] + [ph_lo[:, k] for k in range(4)]),
           delimiter=',', comments='', fmt='%.6e',
           header='plo_dbm,vif1_dbv,vif2_dbv,vif3_dbv,vif4_dbv,ph1_deg,ph2_deg,ph3_deg,ph4_deg')
np.savetxt(os.path.join(DATA_DIR, f'sparx_top_le_rx_if{SUFFIX}.csv'),
           np.column_stack([f_if] + [dbv(vif_f[k]) for k in range(4)]), delimiter=',', comments='', fmt='%.6e',
           header='f_hz,vif1_dbv,vif2_dbv,vif3_dbv,vif4_dbv')
with open(os.path.join(DATA_DIR, f'sparx_top_le_rx{SUFFIX}.json'), 'w') as f:
    json.dump(summary, f, indent=2)

fig, (ax_t, ax_lo, ax_if) = plt.subplots(3, 1, figsize=(8, 11), constrained_layout=True)
fig.suptitle(f'Six-port receiver {VARIANT}: full-core fit and four detectors, LO {freq_lo/1e9:.0f} GHz, RF {freq_rf/1e9:.0f} GHz')
for k in range(4):
    ax_t.plot(t_ns, ac[k], label=OUTS[k])
ax_t.set_xlabel('time (ns)')
ax_t.set_ylabel('differential output (mV)')
ax_t.set_title(f'transient, LO {avail_dbm(ampl_lo):+.0f} dBm, RF {avail_dbm(ampl_rf):+.0f} dBm at the pads')
ax_t.legend(ncol=4)
ax_t.grid(True)
for k in range(4):
    ax_lo.plot(plo, dbv(vif_lo[:, k]), label=OUTS[k])
ax_lo.set_xlabel('LO power at the pad (dBm)')
ax_lo.set_ylabel(f'IF output at {F_IF/1e9:.0f} GHz (dBV)')
ax_lo.set_title(f'hbac, RF {dbm(P_RF_PAD):+.0f} dBm at the pad')
ax_lo.legend(ncol=4)
ax_lo.grid(True)
for k in range(4):
    ax_if.semilogx(f_if, dbv(vif_f[k]), label=OUTS[k])
ax_if.set_xlabel('IF (Hz)')
ax_if.set_ylabel('IF output (dBV)')
ax_if.set_title(f'hbac, LO {avail_dbm(ampl_lo):+.0f} dBm, RF {dbm(P_RF_PAD):+.0f} dBm at the pads')
ax_if.legend(ncol=4)
ax_if.grid(True, which='both')
plt.savefig(os.path.join(FIG_DIR, f'sparx_top_le_rx{SUFFIX}.png'), dpi=150)
print(f'Wrote {os.path.join(FIG_DIR, f"sparx_top_le_rx{SUFFIX}.png")} and the CSV/JSON files in {DATA_DIR}')
if SHOW_PLOTS:
    plt.show()
