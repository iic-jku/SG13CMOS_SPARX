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
import matplotlib.pyplot as plt
import os

# ---- user settings ---------------------------------------------------------
RAW_NAME = 'powdet_tn1.raw'     # named after the transient-noise analysis
VIDEO_BW = (1e3, 1e7)           # [Hz] integration band for RMS output noise
RESPONSIVITY = None             # beta in V/W from the transfer sweep; None -> skip NEP/MDS
NPERSEG = 4096                  # Welch segment length (samples)
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
RAW_FILE = os.path.join(SIM_DIR, RAW_NAME)


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


# --- read and resample to a uniform time grid (transient steps are non-uniform) ---
t, v = read_tran(RAW_FILE)
order = np.argsort(t)
t, v = t[order], v[order]
n_uni = len(t)
t_uni = np.linspace(t[0], t[-1], n_uni)
v_uni = np.interp(t_uni, t, v)
fs = (n_uni - 1) / (t_uni[-1] - t_uni[0])

# --- output noise PSD / ASD ---
freqs, psd = welch_psd(v_uni, fs, NPERSEG)
asd = np.sqrt(psd)                                # V/sqrt(Hz)

# --- integrated RMS output noise over the video band ---
f_lo, f_hi = VIDEO_BW
band = (freqs >= f_lo) & (freqs <= f_hi)
v_n_rms = np.sqrt(np.trapz(psd[band], freqs[band])) if hasattr(np, 'trapz') else \
	np.sqrt(np.trapezoid(psd[band], freqs[band]))

print(f'Sample rate          : {fs:.3e} Hz')
print(f'Video bandwidth      : {f_lo:.2e} .. {f_hi:.2e} Hz')
print(f'RMS output noise     : {v_n_rms:.3e} V')
if RESPONSIVITY:
	nep = asd / RESPONSIVITY                     # W/sqrt(Hz)
	mds = v_n_rms / RESPONSIVITY                 # W
	print(f'Responsivity (beta)  : {RESPONSIVITY:.3e} V/W')
	print(f'Min. detectable sig. : {mds:.3e} W  ({10*np.log10(mds/1e-3):.1f} dBm)')

# --- plot output-noise ASD ---
fig, ax = plt.subplots(figsize=(8, 5), constrained_layout=True)
fig.suptitle('Power Detector SBD — Output Noise (transient noise)')
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

plt.show()
