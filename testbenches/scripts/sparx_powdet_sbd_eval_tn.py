# SPDX-FileCopyrightText: 2025-2026 The SPARX Team
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

# ANALYZE TRANSIENT-NOISE RESULTS for the SBD power detector.
#
# A transient-noise analysis runs an ordinary time-domain transient with the
# device noise sources (thermal, shot, 1/f) injected as stochastic waveforms.
# Post-processing here:
#   1. Read the detector output 'out' vs time.
#   2. Estimate the output-referred noise PSD with Welch's method (numpy only).
#   3. Report the output noise spectral density (V/sqrt(Hz)) and the integrated
#      RMS output noise over a chosen video bandwidth.
#   4. If a detector responsivity is provided (beta = dV_out/dP_in, in V/W,
#      taken from the transfer / V-W sweep), also report:
#         NEP   = v_n_asd / beta              [W/sqrt(Hz)]
#         MDS   = v_n_rms / beta              [W]   (min. detectable signal, SNR=1)
#
# Expected raw: a transient analysis (default name 'powdet_tn1' -> powdet_tn1.raw)
# with vectors 'time' and 'out'. Run the detector with NO RF signal (or a small
# fixed tone) so the output sits at its quiescent point and you measure the
# noise floor.

from rawfile import rawread
import numpy as np
import os, json
import matplotlib
# Default to the non-interactive Agg backend: write the PNG, open no window.
# This is required under a VACASK postprocess, where a Qt window crashes VACASK's
# boost::asio loop ("Bad file descriptor"). To pop up the figure when running the
# script standalone, set the environment variable SHOW_PLOTS=1.
SHOW_PLOTS = os.environ.get('SHOW_PLOTS', '0') == '1'
if not SHOW_PLOTS:
	matplotlib.use('Agg')
import matplotlib.pyplot as plt

# ---- user settings ---------------------------------------------------------
RAW_NAME = 'powdet_tn1.raw'     # named after the transient-noise analysis
# Integration band for the RMS output noise. Lower edge should be >= noisefmin
# of the tran-noise analysis; upper edge ideally the detector's video/output
# passband (using the full sim bandwidth overestimates the in-band RMS noise).
VIDEO_BW = (100e3, 2e9)         # [Hz]
RESPONSIVITY = None             # beta in V/W. None -> auto-load from the transfer
                                # sweep's beta JSON if present; else skip NEP/MDS.
                                # Set a number here to force a manual override.
NPERSEG = None                  # Welch segment length; None -> auto (see N_SEGMENTS)
N_SEGMENTS = 16                 # target number of averages when NPERSEG is auto.
                                # Sets the low-frequency resolution: df ~ N_SEGMENTS/stop
                                # (e.g. 16 / 200us = 80 kHz, ~ matches noisefmin=100k).
DISCARD_FRAC = 0.02             # drop this fraction of the start (op->tran settling)
# ---------------------------------------------------------------------------


def floor_pow2(n):
	return 1 << max(8, int(np.floor(np.log2(max(1, n)))))


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
BETA_FILE = os.path.join(FIG_DIR, 'sparx_powdet_sbd_beta.json')   # written by the transfer eval


def load_beta():
	"""Resolve the detector responsivity beta [V/W] and its source.

	Priority: manual RESPONSIVITY override -> beta JSON from the transfer sweep
	(sparx_powdet_sbd_eval_hb_transfer.py) -> (None, None) if neither is available.
	"""
	if RESPONSIVITY is not None:
		return float(RESPONSIVITY), 'manual override'
	if os.path.isfile(BETA_FILE):
		try:
			with open(BETA_FILE) as f:
				meta = json.load(f)
			return float(meta['beta_V_per_W']), os.path.basename(BETA_FILE)
		except Exception as e:
			print(f'Warning: could not read {BETA_FILE}: {e}')
	return None, None


def welch_psd(x, fs, nperseg, noverlap=None):
	"""One-sided power spectral density via Welch's method (Hann window).

	Returns (freqs [Hz], psd [V^2/Hz]). Pure numpy, no scipy dependency.
	"""
	x = np.asarray(x, dtype=float)
	n = x.size
	nperseg = int(min(nperseg, n))
	if noverlap is None:
		noverlap = nperseg // 2
	step = nperseg - noverlap
	win = np.hanning(nperseg)
	win_norm = np.sum(win ** 2)        # window power for PSD normalization
	segs = range(0, n - nperseg + 1, step)
	psd_acc = np.zeros(nperseg // 2 + 1)
	count = 0
	for start in segs:
		seg = x[start:start + nperseg]
		seg = seg - seg.mean()         # detrend (remove DC per segment)
		sp = np.fft.rfft(seg * win)
		psd_acc += (np.abs(sp) ** 2)
		count += 1
	if count == 0:                     # signal shorter than one segment
		seg = x - x.mean()
		win = np.hanning(n)
		win_norm = np.sum(win ** 2)
		sp = np.fft.rfft(seg * win)
		psd_acc = np.abs(sp) ** 2
		count = 1
		nperseg = n
	psd = psd_acc / count
	psd /= (fs * win_norm)             # -> V^2/Hz
	psd[1:-1] *= 2.0                   # one-sided (don't double DC / Nyquist)
	freqs = np.fft.rfftfreq(nperseg, d=1.0 / fs)
	return freqs, psd


def read_tran(raw_file):
	"""Read (time, out) from a transient raw, tolerant of swept/un-swept rawfile API."""
	raw = rawread(raw_file)
	obj = raw.get(sweeps=0) if hasattr(raw, 'get') else raw
	# Single-group transient: try grouped access first, then flat access.
	try:
		t = np.real(obj[0, 'time'])
		v = np.real(obj[0, 'out'])
	except Exception:
		t = np.real(obj['time'])
		v = np.real(obj['out'])
	return np.asarray(t, dtype=float), np.asarray(v, dtype=float)


# --- read, discard initial settling, resample to a uniform time grid ---
t, v = read_tran(RAW_FILE)
order = np.argsort(t)
t, v = t[order], v[order]
# drop op->tran settling at the start so it doesn't corrupt the PSD
t0 = t[0] + DISCARD_FRAC * (t[-1] - t[0])
keep = t >= t0
t, v = t[keep], v[keep]
n_uni = len(t)
t_uni = np.linspace(t[0], t[-1], n_uni)
v_uni = np.interp(t_uni, t, v)
fs = (n_uni - 1) / (t_uni[-1] - t_uni[0])

# --- output noise PSD / ASD ---
# Auto segment length: long enough to resolve the low-frequency end (df ~ N_SEGMENTS/T)
nperseg = NPERSEG if NPERSEG else floor_pow2(n_uni // N_SEGMENTS)
freqs, psd = welch_psd(v_uni, fs, nperseg)
asd = np.sqrt(psd)                                # V/sqrt(Hz)
print(f'Samples used         : {n_uni}  (nperseg={nperseg}, df={fs/nperseg:.2e} Hz)')

# --- integrated RMS output noise over the video band ---
f_lo, f_hi = VIDEO_BW
band = (freqs >= f_lo) & (freqs <= f_hi)
v_n_rms = np.sqrt(np.trapz(psd[band], freqs[band])) if hasattr(np, 'trapz') else \
	np.sqrt(np.trapezoid(psd[band], freqs[band]))

print(f'Sample rate          : {fs:.3e} Hz')
print(f'Video bandwidth      : {f_lo:.2e} .. {f_hi:.2e} Hz')
print(f'RMS output noise     : {v_n_rms:.3e} V')

# --- responsivity -> NEP / minimum detectable signal (beta auto-loaded) ---
beta, beta_src = load_beta()
nep = None
if beta:
	nep = asd / beta                             # W/sqrt(Hz)
	mds = v_n_rms / beta                         # W (SNR=1)
	nep_inband = np.median(nep[band]) if np.any(band) else float('nan')
	print(f'Responsivity (beta)  : {beta:.3e} V/W  (from {beta_src})')
	print(f'In-band median NEP   : {nep_inband:.3e} W/sqrt(Hz)')
	print(f'Min. detectable sig. : {mds:.3e} W  ({10*np.log10(mds/1e-3):.1f} dBm)')
else:
	print('Responsivity (beta)  : not available -> run '
	      'sparx_powdet_sbd_eval_hb_transfer.py first (or set RESPONSIVITY). '
	      'Skipping NEP/MDS.')

# --- plot output-noise ASD ---
fig, ax = plt.subplots(figsize=(8, 5), constrained_layout=True)
fig.suptitle('Power Detector SBD - Output Noise (transient noise)')
ax.loglog(freqs[1:], asd[1:])
ax.axvspan(f_lo, f_hi, color='tab:orange', alpha=0.15, label='video band')
ax.set_xlabel('Frequency (Hz)')
ax.set_ylabel('Output noise ASD (V/$\\sqrt{\\mathrm{Hz}}$)')
ax.legend()
ax.grid(True, which='both')

os.makedirs(FIG_DIR, exist_ok=True)
plt.savefig(os.path.join(FIG_DIR, 'sparx_powdet_sbd_tn.png'), dpi=150)

# --- export PSD/ASD as CSV for PGFPlots ---
basename = 'sparx_powdet_sbd_tn'
csv_dir = os.path.join(FIG_DIR, f'{basename}_csv')
os.makedirs(csv_dir, exist_ok=True)
csv_path = os.path.join(csv_dir, f'{basename}_asd.csv')
np.savetxt(
	csv_path,
	np.column_stack((freqs[1:], asd[1:])),
	delimiter=',',
	header='x,asd',
	comments='',
	fmt='%.6e',
)
print(f'Wrote {csv_path}')

# NEP spectrum (only if a responsivity was available)
if nep is not None:
	nep_path = os.path.join(csv_dir, f'{basename}_nep.csv')
	np.savetxt(
		nep_path,
		np.column_stack((freqs[1:], nep[1:])),
		delimiter=',',
		header='x,nep',
		comments='',
		fmt='%.6e',
	)
	print(f'Wrote {nep_path}')

if SHOW_PLOTS:
	plt.show()
