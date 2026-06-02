# SPDX-FileCopyrightText: 2025-2026 The SPARX Team
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

# ANALYZE HB SINGLE-TONE TRANSFER CURVE for the SBD power detector.
#
# The canonical power-detector characterization: drive a single RF tone,
# sweep its amplitude, and read the DC (rectified) component of the detector
# output 'out'. This gives the detector transfer curve and responsivity.
#
#   x-axis: RF input power  P_rf  [W]   (log scale)
#   y-axis: DC output voltage      [V]  (log scale)
#
# Square-law region: V_dc ~ P_rf, i.e. slope 1 (decade/decade) on this
# log-log plot. The responsivity beta = V_dc / P_rf [V/W] is flat there and
# rolls off as the detector compresses (upper end of the dynamic range).
#
# Expected raw: a single-tone HB sweep over the RF amplitude
#   (analysis name 'powdet_hbst1' -> powdet_hbst1.raw), one sweep level.
# Suggested netlist control block:
#   sweep ampl_rf instance="vin3" parameter="ampl" from=10u to=300m mode="dec" points=11
#     analysis powdet_hbst1 hb freq=[freq_rf] truncate="diamond" nharm=[11]
# (single tone -> no LO source; read the DC / 0-Hz bin of 'out')

from rawfile import rawread
import numpy as np
import matplotlib.pyplot as plt
import re, glob, os

# Reference impedance for the voltage -> power conversion [Ohm]
Z0 = 50.0
# Set False if the HB spectral magnitudes are already RMS (then P = V^2 / Z0)
AMPL_IS_PEAK = True
RAW_NAME = 'powdet_hbst1.raw'   # named after the single-tone HB analysis


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
RAW_FILE = os.path.join(SIM_DIR, RAW_NAME)


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


# Parse RF frequency from the spectre netlist
spectre_file = glob.glob(os.path.join(SIM_DIR, '*.spectre'))[0]
with open(spectre_file) as f:
	netlist = f.read()
freq_rf = parse_freq(netlist, 'freq_rf')

hb = rawread(RAW_FILE).get(sweeps=1)

# Collect one (P_rf, V_dc) point per RF amplitude
a_rf_list, v_dc_list = [], []
for g in range(hb.sweepGroups):
	sd = hb.sweepData(g)
	a_rf = np.abs(sd['ampl_rf'])

	freq = np.real(hb[g, 'frequency'])
	out = hb[g, 'out']

	# DC (rectified) component = bin closest to 0 Hz
	idx_dc = np.argmin(np.abs(freq))
	v_dc = np.real(out[idx_dc])      # DC output is real; sign = output polarity

	a_rf_list.append(a_rf)
	v_dc_list.append(v_dc)

a_rf = np.array(a_rf_list)
v_dc = np.array(v_dc_list)
order = np.argsort(a_rf)
a_rf, v_dc = a_rf[order], v_dc[order]

p_rf = ampl_to_power(a_rf)           # [W]
v_abs = np.abs(v_dc)                 # magnitude for the log-log plot
beta = v_abs / (p_rf + 1e-30)        # responsivity [V/W]

# Slope-1 reference (square law: V_dc ~ P_rf), anchored at lowest-power point
idx0 = np.argmin(p_rf)
c_off = np.log10(v_abs[idx0] + 1e-30) - np.log10(p_rf[idx0] + 1e-30)
v_ref = 10 ** (np.log10(p_rf + 1e-30) + c_off)

# --- plot transfer curve ---
fig, ax = plt.subplots(figsize=(8, 5), constrained_layout=True)
fig.suptitle(f'Power Detector SBD — Transfer Curve (RF {freq_rf/1e9:.0f} GHz)')
ax.loglog(p_rf, v_abs, 'o-', label='DC output')
ax.loglog(p_rf, v_ref, 'k--', alpha=0.5, label='slope 1 (square law)')
ax.set_xlabel(f'RF Input Power at {freq_rf/1e9:.0f} GHz (W, ref. {Z0:.0f} Ω)')
ax.set_ylabel('DC Output Voltage (V)')
ax.legend()
ax.grid(True, which='both')

os.makedirs(FIG_DIR, exist_ok=True)
plt.savefig(os.path.join(FIG_DIR, 'sparx_powdet_sbd_hb_transfer.png'), dpi=150)

# --- export CSV (transfer curve, reference, responsivity) ---
basename = 'sparx_powdet_sbd_hb_transfer'
csv_dir = os.path.join(FIG_DIR, f'{basename}_csv')
os.makedirs(csv_dir, exist_ok=True)

# transfer: columns x (input power [W]), v (output voltage [V])
np.savetxt(
	os.path.join(csv_dir, f'{basename}.csv'),
	np.column_stack((p_rf, v_abs)),
	delimiter=',', header='x,v', comments='', fmt='%.6e',
)
# reference slope-1
np.savetxt(
	os.path.join(csv_dir, f'{basename}_ref.csv'),
	np.column_stack((p_rf, v_ref)),
	delimiter=',', header='x,v', comments='', fmt='%.6e',
)
# responsivity: columns x (input power [W]), beta (V/W)
np.savetxt(
	os.path.join(csv_dir, f'{basename}_responsivity.csv'),
	np.column_stack((p_rf, beta)),
	delimiter=',', header='x,beta', comments='', fmt='%.6e',
)
print(f'Wrote CSVs to {csv_dir}')
print(f'Low-power responsivity (beta) : {beta[idx0]:.3e} V/W')

plt.show()
