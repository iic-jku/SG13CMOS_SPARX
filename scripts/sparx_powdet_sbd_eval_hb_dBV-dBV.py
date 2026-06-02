# SPDX-FileCopyrightText: 2025-2026 The SPARX Team
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

# ANALYZE HB TWO-TONE SWEEP for the SBD power detector (dBV vs dBV).
#
# Method: difference-frequency (two-tone) detector characterization.
#   Two tones (LO at freq_lo, RF at freq_rf) are summed into the detector
#   input. A square-law detector produces a beat at the IF = |f_rf - f_lo|.
#   For a fixed LO amplitude the IF amplitude is proportional to the RF
#   amplitude (1 dB/dB), which is the signature plotted here.
#
#   Outer sweep: ampl_lo (LO tone amplitude)
#   Inner sweep: ampl_rf (RF tone amplitude)
#   Extracted node: 'out' (differential detector output), IF spectral line.

from rawfile import rawread
import numpy as np
import matplotlib
matplotlib.use('Agg')   # non-interactive backend: no GUI window when run as a
                        # VACASK postprocess (a Qt window there crashes VACASK's
                        # boost::asio loop with "Bad file descriptor"). Open the
                        # saved PNG to view the result.
import matplotlib.pyplot as plt
import re, glob, os


# ---------------------------------------------------------------------------
# Robust path resolution: works whether the script is run as a VACASK
# postprocess (cwd = testbenches/simulations) or standalone from anywhere.
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

# Collect curves (x = RF input in dBV, y = IF output in dBV), one per LO amplitude
curves = []
for a_lo in sorted(data.keys()):
	d = data[a_lo]
	a_rf = np.array(d['a_rf'])
	mag_if = np.array(d['mag_if'])

	order = np.argsort(a_rf)
	a_rf = a_rf[order]
	mag_if = mag_if[order]

	a_rf_db = 20 * np.log10(a_rf + 1e-30)
	mag_if_db = 20 * np.log10(mag_if + 1e-30)
	label = f'A(LO {freq_lo/1e9:.0f} GHz) = {a_lo*1e3:.0f} mV'
	# slug used for the per-curve CSV filename
	slug = f'alo_{a_lo*1e3:.0f}mV'
	curves.append({'label': label, 'slug': slug, 'x': a_rf_db, 'y': mag_if_db})

# Build 1 dB/dB reference slope curve (signature of the square-law beat term)
a_rf_all = []
for a_lo in sorted(data.keys()):
	d = data[a_lo]
	a_rf_all.extend(d['a_rf'])
a_rf_ref = np.array(sorted(set(a_rf_all)))
a_rf_ref_db = 20 * np.log10(a_rf_ref + 1e-30)
first_key = sorted(data.keys())[0]
d0 = data[first_key]
a0 = np.array(d0['a_rf'])
m0 = np.array(d0['mag_if'])
idx0 = np.argmin(a0)
ref_offset = 20 * np.log10(m0[idx0] + 1e-30) - 20 * np.log10(a0[idx0] + 1e-30)
ref_db = a_rf_ref_db + ref_offset
curves.append({'label': '1 dB/dB slope', 'slug': 'ref', 'x': a_rf_ref_db, 'y': ref_db})

# Plot
fig, ax = plt.subplots(figsize=(8, 5), constrained_layout=True)
fig.suptitle(f'Power Detector SBD — IF at {freq_if/1e9:.1f} GHz')

for c in curves[:-1]:
	ax.plot(c['x'], c['y'], 'o-', label=c['label'])
ref = curves[-1]
ax.plot(ref['x'], ref['y'], 'k--', alpha=0.5, label=ref['label'])

ax.set_xlabel(f'RF Input Amplitude at {freq_rf/1e9:.0f} GHz (dBV)')
ax.set_ylabel(f'IF Output at {freq_if/1e9:.1f} GHz (dBV)')
ax.legend()
ax.grid(True)

os.makedirs(FIG_DIR, exist_ok=True)
plt.savefig(os.path.join(FIG_DIR, 'sparx_powdet_sbd_hb_sweep.png'), dpi=150)

# ----------------------------------------------------------------------------
# Export plotting data as CSV files (one per curve) for use in PGFPlots
# ----------------------------------------------------------------------------
basename = 'sparx_powdet_sbd_hb_sweep'
csv_dir = os.path.join(FIG_DIR, f'{basename}_csv')
os.makedirs(csv_dir, exist_ok=True)

# One CSV per curve, columns: x (RF input dBV), mag_db (IF output dBV)
for c in curves:
	csv_path = os.path.join(csv_dir, f'{basename}_{c["slug"]}.csv')
	np.savetxt(
		csv_path,
		np.column_stack((c['x'], c['y'])),
		delimiter=',',
		header='x,mag_db',
		comments='',
		fmt='%.6f',
	)
	print(f'Wrote {csv_path}')
