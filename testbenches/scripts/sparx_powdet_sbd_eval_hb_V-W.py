# SPDX-FileCopyrightText: 2025-2026 The SPARX Team
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

# ANALYZE HB TWO-TONE SWEEP for the SBD power detector (V vs W).
#
# Same data as sparx_powdet_sbd_eval_hb_dBV-dBV.py, but plotted in the
# units a power-detector publication expects:
#   x-axis: RF input power  P_rf  [W]   (log scale)
#   y-axis: IF output voltage      [V]  (log scale, this IS a voltage)
#
# Power conversion: the testbench drives the input with an ideal voltage
# source, so power must be referred to a reference impedance Z0. We report
# the equivalent input power referred to Z0:
#       P_rf = Vrms^2 / Z0 = (a_rf / sqrt(2))^2 / Z0 = a_rf^2 / (2 * Z0)
# (Set Z0 to your system/port impedance. If your HB phasor magnitudes are
#  already RMS rather than peak, drop the 1/2 factor below.)
#
# Reference slope: for the two-tone difference method the IF amplitude is
#   V_if ~ a_lo * a_rf ~ sqrt(P_rf), i.e. a slope of 1/2 (decade/decade) on
#   this log-log V-vs-P plot. (A true single-tone detector output V_dc ~ P_rf
#   would instead have slope 1.)
#
#   Outer sweep: ampl_lo (LO tone amplitude)
#   Inner sweep: ampl_rf (RF tone amplitude)

from rawfile import rawread
import numpy as np
import os
import matplotlib
# Default to the non-interactive Agg backend: write the PNG, open no window.
# This is required under a VACASK postprocess, where a Qt window crashes VACASK's
# boost::asio loop ("Bad file descriptor"). To pop up the figure when running the
# script standalone, set the environment variable SHOW_PLOTS=1.
SHOW_PLOTS = os.environ.get('SHOW_PLOTS', '0') == '1'
if not SHOW_PLOTS:
    matplotlib.use('Agg')
import matplotlib.pyplot as plt
import re, glob

# Reference impedance for the voltage -> power conversion [Ohm]
Z0 = 50.0
# Set False if the HB spectral magnitudes are already RMS (then P = V^2 / Z0)
AMPL_IS_PEAK = True


# ---------------------------------------------------------------------------
# Robust path resolution (VACASK postprocess cwd=testbenches/simulations,
# or standalone from anywhere).
# ---------------------------------------------------------------------------
def find_design_root():
    cands = [os.getcwd()]
    try:
        cands.append(os.path.dirname(os.path.abspath(__file__)))
    except NameError:
        pass
    for start in cands:
        d = start
        while True:
            if os.path.isdir(os.path.join(d, 'testbenches', 'simulations')):
                return d
            parent = os.path.dirname(d)
            if parent == d:
                break
            d = parent
    raise RuntimeError('Could not locate design root (need testbenches/simulations)')


DESIGN_ROOT = find_design_root()
SIM_DIR = os.path.join(DESIGN_ROOT, 'testbenches', 'simulations')
FIG_DIR = os.path.join(DESIGN_ROOT, 'doc', 'fig', 'sparx_sim')
RAW_FILE = os.path.join(SIM_DIR, 'powdet_hb1.raw')   # named after the HB analysis 'powdet_hb1'


def parse_freq(netlist, name):
    m = re.search(rf'var\s+{name}\s*=\s*([\d.eE+\-]+[GMKkT]?)', netlist)
    val = m.group(1)
    for suf, exp in (('G', 'e9'), ('M', 'e6'), ('K', 'e3'), ('k', 'e3'), ('T', 'e12')):
        val = val.replace(suf, exp)
    return float(val)


def ampl_to_power(a):
    """Equivalent input power [W] referred to Z0."""
    if AMPL_IS_PEAK:
        return a ** 2 / (2.0 * Z0)
    return a ** 2 / Z0


# Parse LO and RF frequencies from the spectre netlist
spectre_file = glob.glob(os.path.join(SIM_DIR, '*.spectre'))[0]
with open(spectre_file) as f:
    netlist = f.read()
freq_lo = parse_freq(netlist, 'freq_lo')
freq_rf = parse_freq(netlist, 'freq_rf')
freq_if = abs(freq_rf - freq_lo)

hb = rawread(RAW_FILE).get(sweeps=2)

# Collect data grouped by LO amplitude
data = {}
for g in range(hb.sweepGroups):
    sd = hb.sweepData(g)
    a_lo = np.abs(sd['ampl_lo'])
    a_rf = np.abs(sd['ampl_rf'])

    freq = np.real(hb[g, 'frequency'])
    out = hb[g, 'out']

    # Find IF bin at |f_rf - f_lo|
    idx_if = np.argmin(np.abs(freq - freq_if))

    if a_lo not in data:
        data[a_lo] = {'a_rf': [], 'mag_if': []}

    data[a_lo]['a_rf'].append(a_rf)
    data[a_lo]['mag_if'].append(np.abs(out[idx_if]))

# Collect curves (x = RF input power [W], y = IF output voltage [V])
curves = []
for a_lo in sorted(data.keys()):
    d = data[a_lo]
    a_rf = np.array(d['a_rf'])
    mag_if = np.array(d['mag_if'])

    order = np.argsort(a_rf)
    a_rf = a_rf[order]
    mag_if = mag_if[order]

    p_rf = ampl_to_power(a_rf)            # [W]
    v_if = mag_if                         # [V]
    label = f'A(LO {freq_lo/1e9:.0f} GHz) = {a_lo*1e3:.0f} mV'
    slug = f'alo_{a_lo*1e3:.0f}mV'
    curves.append({'label': label, 'slug': slug, 'x': p_rf, 'y': v_if})

# Build 1/2-slope reference curve (V ~ sqrt(P) for the two-tone difference method)
p_all = []
for a_lo in sorted(data.keys()):
    p_all.extend(ampl_to_power(np.array(data[a_lo]['a_rf'])))
p_ref = np.array(sorted(set(p_all)))
first_key = sorted(data.keys())[0]
d0 = data[first_key]
p0 = ampl_to_power(np.array(d0['a_rf']))
v0 = np.array(d0['mag_if'])
idx0 = np.argmin(p0)
# log10(V) = 0.5*log10(P) + c, anchored at the lowest-power point of curve 0
c_off = np.log10(v0[idx0] + 1e-30) - 0.5 * np.log10(p0[idx0] + 1e-30)
v_ref = 10 ** (0.5 * np.log10(p_ref + 1e-30) + c_off)
curves.append({'label': '1/2 slope (V ∝ √P)', 'slug': 'ref', 'x': p_ref, 'y': v_ref})

# Plot (log-log)
fig, ax = plt.subplots(figsize=(8, 5), constrained_layout=True)
fig.suptitle(f'Power Detector SBD - IF at {freq_if/1e9:.1f} GHz')

for c in curves[:-1]:
    ax.plot(c['x'], c['y'], 'o-', label=c['label'])
ref = curves[-1]
ax.plot(ref['x'], ref['y'], 'k--', alpha=0.5, label=ref['label'])

ax.set_xscale('log')
ax.set_yscale('log')
ax.set_xlabel(f'RF Input Power at {freq_rf/1e9:.0f} GHz (W, ref. {Z0:.0f} Ω)')
ax.set_ylabel(f'IF Output Voltage at {freq_if/1e9:.1f} GHz (V)')
ax.legend()
ax.grid(True, which='both')

os.makedirs(FIG_DIR, exist_ok=True)
plt.savefig(os.path.join(FIG_DIR, 'sparx_powdet_sbd_hb_sweep_V-W.png'), dpi=150)

# ----------------------------------------------------------------------------
# Export plotting data as CSV files (one per curve) for use in PGFPlots
# ----------------------------------------------------------------------------
basename = 'sparx_powdet_sbd_hb_sweep_V-W'
csv_dir = os.path.join(FIG_DIR, f'{basename}_csv')
os.makedirs(csv_dir, exist_ok=True)

# One CSV per curve, columns: x (input power [W]), v (output voltage [V])
for c in curves:
    csv_path = os.path.join(csv_dir, f'{basename}_{c["slug"]}.csv')
    np.savetxt(
        csv_path,
        np.column_stack((c['x'], c['y'])),
        delimiter=',',
        header='x,v',
        comments='',
        fmt='%.6e',
    )
    print(f'Wrote {csv_path}')

if SHOW_PLOTS:
    plt.show()
