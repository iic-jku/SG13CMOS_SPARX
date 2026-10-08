# SBD Power Detector: Results and Derivations

This document accompanies Section IV, "SBD-Based Power Detector", of the paper S. Dorrer, D. Kellerer-Pirklbauer, G. Zachl, and H. Pretl, "SPARX: An Open-Source, Automated, Programmatically Generated, Frequency-Scalable Six-Port Receiver in 130-nm CMOS," IEEE Nordic Circuits and Systems Conference (NorCAS), 2026. Most numbers in that section are computed from the simulation data rather than read off a plot. Here each one is traced to the testbench that produces it and to the data file and field it is read from, and every equation the section uses is derived, the noise figure of Eq. (3) included.

The testbenches, their analysis settings and their limits are documented in [README.md](README.md), section 3. This document does not repeat them and concentrates on the numbers.

1. [Sources and conventions](#1-sources-and-conventions)
2. [Circuit and dc operating point](#2-circuit-and-dc-operating-point)
3. [Transfer curve, responsivity and compression](#3-transfer-curve-responsivity-and-compression)
4. [Coupling efficiency](#4-coupling-efficiency)
5. [The 16-cell and the post-layout versions](#5-the-16-cell-and-the-post-layout-versions)
6. [Video bandwidth and noise-equivalent power](#6-video-bandwidth-and-noise-equivalent-power)
7. [Noise figure and Eq. (3)](#7-noise-figure-and-eq-3)
8. [Minimum detectable power](#8-minimum-detectable-power)
9. [Paper values against the data](#9-paper-values-against-the-data)
10. [Reproducing the numbers](#10-reproducing-the-numbers)
11. [References](#11-references)

## 1. Sources and conventions

Three versions of the detector run through the same testbenches. `scripts/powdet_variant.py` rewrites the emitted netlist for the two that differ from the schematic, see [Design variants](README.md#design-variants-and-why-no-symbol-is-swapped).

| version | name in the paper | suffix of the data files |
|---|---|---|
| fabricated, one Schottky unit cell per diode | $m = 1$ | none |
| the fabricated layout after Magic RC extraction | post-layout | `_m1_pex` |
| revised, 16 parallel unit cells per diode | $m = 16$ | `_m16` |

All results are at the typical corner and 27 °C (300.15 K), with the detector input driven from a 50 Ohm source, simulated with VACASK `1b48553`. The transfer curve uses one tone at 161 GHz. The noise-figure analyses put the LO at 159 GHz, so the RF at 161 GHz lands at a 2 GHz IF.

Four testbenches supply Section IV. Their post-processing scripts in `plot_simulations/` write to `plot_simulations/data/`:

| testbench | post-processing script | data files | what Section IV takes from it |
|---|---|---|---|
| `sparx_powdet_sbd_tb_pss_vacask` | `plot_sparx_powdet_sbd_tb_pss_vacask.py` | `sparx_powdet_sbd_beta<suffix>.json`, `sparx_powdet_sbd_pss<suffix>.csv`, `sparx_powdet_sbd_pss_check<suffix>.csv` | transfer curve, responsivity, compression, input impedance, HB against shooting PSS |
| `sparx_powdet_sbd_tb_nf_vacask` | `plot_sparx_powdet_sbd_tb_nf_vacask.py` | `sparx_powdet_sbd_nf<suffix>.json`, `sparx_powdet_sbd_nf<suffix>.csv`, `sparx_powdet_sbd_nf_lo<suffix>.csv` | video response, NEP, noise contributors, conversion gain, noise figure against IF and against LO power, minimum detectable power |
| `sparx_powdet_sbd_tb_tn_lo_vacask` | `plot_sparx_powdet_sbd_tb_tn_lo_vacask.py` | `sparx_powdet_sbd_tn_lo.json`, `sparx_powdet_sbd_tn_lo.csv` | the transient-noise points of Fig. 7(b) |
| `sparx_powdet_sbd_tb_hb_vacask` | `plot_sparx_powdet_sbd_tb_hb_V-W_vacask.py`, `plot_sparx_powdet_sbd_tb_hb_dBV-dBV_vacask.py` | figures only | the two-tone check of square-law detection available at tapeout |

Fig. 7 of the paper plots these data files unchanged, as of commit `147c455`:

| panel | curve | file | x column | y column |
|---|---|---|---|---|
| (a) | detected voltage, three versions | `sparx_powdet_sbd_pss<suffix>.csv` | `pin_dbm` | `dv_v` |
| (a) | square-law line, $m = 1$ | `sparx_powdet_sbd_pss.csv` | `pin_dbm` | `squarelaw_v` |
| (a) | shooting PSS crosses, $m = 1$, from -66 dBm | `sparx_powdet_sbd_pss_check.csv` | `pin_dbm` | `dv_pss_v` |
| (b) | `hbnoise`, three versions | `sparx_powdet_sbd_nf_lo<suffix>.csv` | `plo_dbm` | `nf_dsb_db` |
| (b) | `pnoise`, $m = 1$, every second point | `sparx_powdet_sbd_nf_lo.csv` | `plo_dbm` | `nf_dsb_pnoise_db` |
| (b) | transient noise, $m = 1$ | `sparx_powdet_sbd_tn_lo.csv` | `plo_dbm` | `nf_dsb_transient_db` |
| (b) | small-signal noise at the dc operating point, $m = 1$ | `sparx_powdet_sbd_nf_lo.csv` | `plo_dbm` | `nf_dsb_quiescent_db` |

The dc operating point (Section 2) and the power and current budget (Section 4.4) are read from the rawfiles that the same `make` targets write to `simulations/`, which is not committed. VACASK's `python/rawfile.py` reads them.

Constants and device parameters used below:

| symbol | value | source |
|---|---|---|
| $k$ | 1.380649e-23 J/K | Boltzmann constant, 1.381e-23 J/K in the paper |
| $T$ | 300.15 K | simulation temperature, 27 °C |
| $V_\mathrm{T} = kT/q$ | 25.865 mV | thermal voltage at $T$ |
| $T_0$ | 290 K | IEEE noise reference temperature |
| $kT_0$ | 4.004e-21 W/Hz, that is -174.0 dBm/Hz | |
| $R_\mathrm{src}$ | 50 Ohm | source resistance `Rs` of the testbenches |
| $n$ | 1.057 | ideality factor of `dmain_mod` in the PDK model `sg13g2_dschottky_nbl1_mod.lib` |
| $R_\mathrm{s}$ | 1360 Ohm per cell | diode series resistance, `rsmain` of the same model, divided by the cell count |
| $C_{j0}$ | 0.24 fF per cell | `cj` = 0.8 fF/um² times the 0.3 um² junction of one cell |
| $C_\mathrm{stray}$ | 0.874 fF per cell | `cstray`, from anode to cathode across the whole cell |

## 2. Circuit and dc operating point

Fig. 1(b) of the paper shows the detector. The table maps its symbols to the instances in `schematic/xschem/sparx_powdet_sbd.sch`, with the resistances as the operating point below measures them.

| paper | instance | device | value |
|---|---|---|---|
| $D_1$ | `XD1` (detector), `XD2` (replica) | `schottky_nbl1` | `nx=1 ny=1`, or `nx=4 ny=4` for $m = 16$ |
| $C_1$ | `XC1` | `cap_cmim`, 10 um by 10 um | 150 fF |
| $R_1$ | `XR1` (detector), `XR5` (replica) | `rsil`, 0.5 um by 2.5 um | 52.3 Ohm |
| $R_2$ | `XR2` (detector), `XR4` (replica) | `rppd`, 0.5 um by 1.5 um | 910.8 Ohm |
| $R_3$ | `XR3` | `rhigh`, 0.5 um by 2 um | 6.23 kOhm |
| $10M_1$, $10M_2$ | `XM3`, `XM4` | NMOS 50 um / 0.13 um, PMOS 100 um / 0.13 um | inverter of the detector TIA |
| $M_1$, $M_2$ | `XM1`, `XM2` | NMOS 5 um / 0.13 um, PMOS 10 um / 0.13 um | inverter of the replica TIA |
| $C_2$ | testbench `C1`, `C2` | ideal | 5 pF off-chip on `ref` and `out_cm` |

The RF input reaches the anode node `rfin_int` through $C_1$. $R_1$ connects that node to the bias node `bias1`, which on-chip MIM capacitors hold at RF ground, so $R_1$ is the 52 Ohm termination at RF and the bias feed at dc. $R_3$ feeds `bias1` from $V_\mathrm{DD}$ and sets the bias current of both diodes. The cathode of $D_1$ is the input `bb_int` of a shunt-feedback TIA, an inverter with $R_2$ from output to input. The replica repeats diode and TIA at a tenth of the TIA current and receives no RF. The testbench reads the difference $V_\mathrm{out} - V_\mathrm{ref}$ with an ideal voltage-controlled source (`E2`), so every detected voltage below is differential.

The dc operating point of the fabricated design, from the `op` analysis of `sparx_powdet_sbd_tb_pss_vacask`:

| quantity | simulated | in Fig. 1(b) or the text |
|---|---|---|
| $V_\mathrm{bias}$ | 1.1346 V | 1.13 V |
| $V_\mathrm{ref}$ | 0.7354 V | 0.74 V |
| $V_\mathrm{out}$ | 0.7284 V | |
| $V_\mathrm{out} - V_\mathrm{ref}$ with no RF | -7.03 mV | |
| diode bias current $I_0$ of $D_1$ | 30.39 uA | 30 uA |
| replica diode current | 28.24 uA | |
| current in $R_3$ | 58.63 uA | |
| TIA current, detector | 3.96 mA | 4 mA ($10 I_\mathrm{q}$) |
| TIA current, replica | 0.41 mA | 400 uA ($I_\mathrm{q}$) |
| supply current | 4.36 mA | |
| $g_\mathrm{m}/I_\mathrm{D}$, NMOS and PMOS of the detector TIA | 6.10 S/A and 5.55 S/A | about 6 S/A |
| $g_\mathrm{m}/I_\mathrm{D}$, NMOS and PMOS of the replica TIA | 6.01 S/A and 5.63 S/A | |
| overdrive $\lvert V_\mathrm{GS}\rvert - \lvert V_\mathrm{th}\rvert$, NMOS and PMOS | 0.31 V and 0.34 V | strong inversion |
| $R_1$, voltage across it over $I_0$ | 52.31 Ohm | 52 Ohm |
| $R_2$, voltage across it over $I_0$ | 910.8 Ohm | 911 Ohm |
| $R_\mathrm{s}$, voltage across `rsmain` over $I_0$ | 1360.0 Ohm | 1.36 kOhm |
| junction voltage | 0.3356 V | |

The junction resistance follows from the diode equation:

$$
I_\mathrm{D} = I_\mathrm{S}\left(e^{V/(n V_\mathrm{T})} - 1\right)
\quad\Rightarrow\quad
r_\mathrm{d} = \left(\frac{\mathrm{d}I_\mathrm{D}}{\mathrm{d}V}\right)^{-1} = \frac{n V_\mathrm{T}}{I_0 + I_\mathrm{S}} \approx \frac{n V_\mathrm{T}}{I_0} = \frac{1.057 \cdot 25.865\ \mathrm{mV}}{30.39\ \mu\mathrm{A}} = 899.7\ \Omega ,
$$

which is the "junction resistance of 0.9 kOhm at its 30 uA bias" in the text. $I_\mathrm{S}$ is more than five orders of magnitude below $I_0$, so the approximation costs nothing.

The detector output is negative. The diode current flows from the anode into the TIA input and through $R_2$ to the TIA output, so $V_\mathrm{out} = V_\mathrm{bb} - R_2 I_\mathrm{D}$. RF drive raises the average diode current, and $V_\mathrm{out}$ falls. The data files keep the sign (`beta_V_per_W` is -41.2 V/W), the paper quotes magnitudes.

## 3. Transfer curve, responsivity and compression

Source: `sparx_powdet_sbd_tb_pss_vacask`, a single-tone harmonic-balance sweep at 161 GHz with 15 harmonics, followed by nine shooting PSS analyses as the check. The HB block runs at `reltol=1e-8`, because the detected voltage at the bottom of the sweep is about 1 nV on the -7 mV offset.

### 3.1 Available power

A sinusoidal source of amplitude $a$ behind $R_\mathrm{src} = 50\ \Omega$ delivers its largest power into a matched load, which sees half the source voltage:

$$
P_\mathrm{in} = \frac{(a/2)^2}{2 R_\mathrm{src}} = \frac{a^2}{8 R_\mathrm{src}} .
$$

The sweep runs $a$ from 100 uV to 1.4 V at 8 points per decade, which is -76.0 dBm to +6.9 dBm. All powers in Section IV are this available power, so the input mismatch is part of the detector.

### 3.2 Why the output follows the input power

Expand the diode current around the bias point $V_0$ for a small junction voltage $v(t)$:

$$
i(V_0 + v) = I_0 + I'(V_0)\, v + \tfrac{1}{2} I''(V_0)\, v^2 + \dots
$$

Averaged over the carrier period, the linear term vanishes and the quadratic term leaves a dc shift $\Delta I = \tfrac{1}{2} I''(V_0) \langle v^2 \rangle$. At small drive $v$ is proportional to the source voltage, so $\langle v^2 \rangle$ and the rectified current are proportional to $P_\mathrm{in}$. That is the square-law region, where $\Delta V_\mathrm{out} = \beta P_\mathrm{in}$ with a constant responsivity $\beta$.

With two tones, $v = V_\mathrm{LO}\cos\omega_\mathrm{LO}t + V_\mathrm{RF}\cos\omega_\mathrm{RF}t$, the square contains the beat $V_\mathrm{LO} V_\mathrm{RF} \cos(\omega_\mathrm{LO} - \omega_\mathrm{RF})t$, so the IF output is proportional to $V_\mathrm{RF} V_\mathrm{LO}$. The two-tone HB testbench `sparx_powdet_sbd_tb_hb_vacask` confirmed this at tapeout ([README, 3.1](README.md#31-two-tone-verification-as-at-tapeout)), and Section 7.4 turns it into a closed form for the conversion gain.

### 3.3 Offset and responsivity

The paper defines the detected voltage against its zero-drive value:

$$
\Delta V_\mathrm{out} = (V_\mathrm{out} - V_\mathrm{ref}) - (V_\mathrm{out} - V_\mathrm{ref})\big|_{P_\mathrm{in} = 0} .
$$

The zero-drive value is not taken from the `op` analysis, which runs before the tight HB tolerances are set and lies 0.5 uV off, nor from the lowest sweep point, which carries its own detected term. The script fits it instead, together with $\beta$, on the square-law line $V_\mathrm{dc}(P) = V_\mathrm{off} + \beta P$. The fit uses the points where the local log-log slope $\mathrm{d}\ln\lvert\Delta V\rvert / \mathrm{d}\ln P$ is within 0.1 of 1, weighted by $1/\lvert\Delta V\rvert$ so that every decade counts the same, in two passes. Result for the fabricated design (`sparx_powdet_sbd_beta.json`):

| field | value |
|---|---|
| `v_offset_V` | -7.0327 mV |
| `beta_V_per_W` | -41.216 V/W |
| `p_fit_lo_W`, `p_fit_hi_W` | -71.1 dBm to -7.7 dBm |

The fit region is the "flat from -71 dBm to -8 dBm" of the text. Inside it the local responsivity $\Delta V / P$ (`beta_vw` in the CSV) stays within -0.6 % and +3.2 % of $\beta$, with the +3.2 % at -10.2 dBm, where the curve expands slightly before it compresses.

### 3.4 1 dB compression

$P_\mathrm{1dB}$ is the power where the detected voltage falls 1 dB below the square-law line,

$$
20 \log_{10} \frac{\lvert\Delta V_\mathrm{out}\rvert}{\lvert\beta\rvert P_\mathrm{in}} = -1\ \mathrm{dB},
$$

interpolated linearly in $\log P$ between the two sweep points that bracket it. The criterion applies $20 \log_{10}$ to the detected voltage, so it marks the point where that voltage is 10.9 % below the line. Result (`p_1db_W`): -2.74 dBm for $m = 1$.

### 3.5 Input impedance

From the HB fundamental at 161 GHz, with the current taken from the drop across the known source resistance:

$$
Z_\mathrm{in} = \frac{V_\mathrm{rfin}}{I}, \qquad I = \frac{V_\mathrm{src} - V_\mathrm{rfin}}{R_\mathrm{src}} .
$$

For $m = 1$ it is 50.94 - j9.80 Ohm at -76 dBm (`z_in_small_signal_ohm`) and 51.14 - j9.99 Ohm at $P_\mathrm{1dB}$ (columns `zin_re`, `zin_im`), the "(51 - j10) Ohm up to compression" of the text. $R_1$ sets the real part, and the 150 fF of $C_1$ contribute -j6.6 Ohm of the reactance. The mismatch against 50 Ohm costs 0.9 % of the available power.

### 3.6 Harmonic balance against shooting PSS

Each of the nine PSS analyses solves the periodic steady state by shooting, a method that shares no code with harmonic balance. The script compares the period average of the PSS output with the HB curve at the same amplitude, interpolated in log-log (`sparx_powdet_sbd_pss_check.csv`):

| $P_\mathrm{in}$ | HB | PSS | PSS / HB - 1 |
|---|---|---|---|
| -76.0 dBm | 1.0673 nV | 1.0550 nV | -1.16 % |
| -66.0 dBm | 10.271 nV | 10.265 nV | -0.05 % |
| -56.0 dBm | 102.44 nV | 102.40 nV | -0.04 % |
| -46.0 dBm | 1.0240 uV | 1.0236 uV | -0.04 % |
| -36.0 dBm | 10.243 uV | 10.239 uV | -0.04 % |
| -26.0 dBm | 102.59 uV | 102.55 uV | -0.04 % |
| -16.0 dBm | 1.0416 mV | 1.0411 mV | -0.05 % |
| -6.0 dBm | 10.254 mV | 10.292 mV | +0.37 % |
| +4.0 dBm | 52.157 mV | 52.456 mV | +0.57 % |

The "within 0.6 %" of the text is the largest deviation over the eight points from -66 dBm, which Fig. 7(a) draws. The -76 dBm point, 1 nV of detected voltage where both solvers reach their floor, is left out of the figure. The post-layout netlist gives the same numbers, and for $m = 16$ the agreement is 1.0 % at -66 dBm and 0.5 % above.

![Transfer curve, responsivity and input impedance of the fabricated detector](plot_simulations/figures/sparx_powdet_sbd_pss_sweep.png)

## 4. Coupling efficiency

### 4.1 Current responsivity of an ideal junction

Let a junction biased at $I_0$ carry a small RF voltage $v = \hat{V}\cos\omega t$, with its dc voltage held fixed. It absorbs the power

$$
P_\mathrm{j} = \langle v \cdot I'(V_0)\, v \rangle = \frac{\hat{V}^2}{2 r_\mathrm{d}}
$$

and, from Section 3.2, rectifies the dc current

$$
\Delta I = \tfrac{1}{2} I''(V_0) \langle v^2 \rangle = \tfrac{1}{4} I''(V_0)\, \hat{V}^2 .
$$

Their ratio is the current responsivity of the junction [1], [2]:

$$
\beta_I = \frac{\Delta I}{P_\mathrm{j}} = \frac{I''(V_0)}{2\, I'(V_0)} .
$$

For the exponential diode, $I' = (I_0 + I_\mathrm{S})/(n V_\mathrm{T})$ and $I'' = (I_0 + I_\mathrm{S})/(n V_\mathrm{T})^2$, so the bias current cancels:

$$
\beta_{I,\mathrm{max}} = \frac{1}{2 n V_\mathrm{T}} = \frac{1}{2 \cdot 1.057 \cdot 25.865\ \mathrm{mV}} = 18.29\ \mathrm{A/W} .
$$

This is the current per watt absorbed in the junction conductance itself, and the upper bound for any detector built on this junction. Every loss in front of the junction and every current that does not reach the readout lowers the current the circuit delivers per watt of available power.

### 4.2 Definition of the coupling efficiency

The TIA turns the diode current into the output voltage with its feedback resistor, so $\beta / R_2$ is the delivered current responsivity referred to the available power. The paper compares it with the junction limit:

$$
\eta = \frac{\beta / R_2}{\beta_{I,\mathrm{max}}} = \frac{\beta}{R_2} \cdot 2 n V_\mathrm{T} .
$$

| version | $\beta$ | $\eta$ with $R_2$ = 911 Ohm |
|---|---|---|
| $m = 1$ | 41.216 V/W | 0.247 % |
| post-layout | 38.779 V/W | 0.233 % |
| $m = 16$ | 250.785 V/W | 1.505 % |

$\eta$ is the fraction of the available power an ideal junction read with $R_2$ would have to absorb to produce the simulated $\beta$. It is a figure of merit normalized to $R_2$, and Section 4.4 shows that the real readout gives more than $R_2$ per ampere.

### 4.3 The "about 2 %" into the diode branch

The paper states that $R_1$ passes only about 2 % of the input power into the diode branch. The first-order estimate treats the branch at low frequency as $R_\mathrm{s} + r_\mathrm{d}$ in parallel with $R_1$, both driven by the same node voltage, so the power divides like the conductances:

$$
\frac{P_\mathrm{branch}}{P_\mathrm{node}} = \frac{1/(R_\mathrm{s} + r_\mathrm{d})}{1/R_1 + 1/(R_\mathrm{s} + r_\mathrm{d})} = \frac{R_1}{R_1 + R_\mathrm{s} + r_\mathrm{d}} = \frac{52}{52 + 1360 + 911} = 2.24\ \% ,
$$

with $r_\mathrm{d}$ = 911 Ohm for the rounded 30 uA. The simulated 52.31 Ohm and 899.7 Ohm give 2.26 %.

At 161 GHz the HB solution gives the split directly. The rawfile `powdet_pss1.raw` holds the phasors of the fundamental at the pad (`src`, `rfin`), at the anode node (`xdemod1:rfin_int`, $V_A$), at the internal node behind `rsmain` (`xdemod1:XD1:1`, $V_1$), at the cathode (`xdemod1:bb_int`, $V_C$) and at the bias node. With the peak phasors HB reports and $I_\mathrm{s} = (V_A - V_1)/R_\mathrm{s}$, the current through `rsmain`:

$$
P_\mathrm{branch} = \tfrac{1}{2}\mathrm{Re}\{(V_A - V_C)\, I_\mathrm{s}^*\}, \qquad
P_{R_\mathrm{s}} = \tfrac{1}{2}\lvert I_\mathrm{s}\rvert^2 R_\mathrm{s}, \qquad
P_\mathrm{j} = \tfrac{1}{2}\mathrm{Re}\{(V_1 - V_C)\, I_\mathrm{s}^*\} .
$$

`cstray` sits across the whole cell, from anode to cathode. It is lossless and parallel to this path, so it moves $Z_\mathrm{in}$ but takes no power. At -37 dBm, in the square-law region, for $m = 1$:

| power | share |
|---|---|
| delivered into the input, of $P_\mathrm{in}$ | 99.06 % |
| into $R_1$, of the delivered power | 97.57 % |
| into the diode branch, of the delivered power | 2.32 % |
| into $R_\mathrm{s}$, of the branch power | 64.2 % |
| into the junction, of the branch power | 35.8 % |

The branch takes 2.32 %, the "about 2 %" of the text. At dc the junction would take $r_\mathrm{d}/(R_\mathrm{s} + r_\mathrm{d})$ = 39.8 % of the branch power. At 161 GHz the junction capacitance shunts part of the junction current and lowers that to 35.8 %, and $R_\mathrm{s}$ takes the other 64.2 %. That is the "most of which the cell's series resistance and junction capacitance take at 161 GHz" of the text. The junction absorbs $P_\mathrm{j}/P_\mathrm{in}$ = 0.82 % of the available power.

### 4.4 The complete budget

0.82 % is 3.3 times the $\eta$ of 0.25 %. The rest of the gap lies behind the junction, on the dc side.

At dc, a junction driven at RF behaves like its own I-V curve with a current source $i_\mathrm{sc} = \beta_{I,\mathrm{max}} P_\mathrm{j}$ in parallel, the short-circuit rectified current of Section 4.1. Only part of it reaches the TIA. The rest circulates through $r_\mathrm{d}$, which lies in parallel with the external dc loop: $R_\mathrm{s}$, $R_1$, the bias node, and the TIA input resistance $R_\mathrm{in}$ in series. The bias node sees $R_3$ to $V_\mathrm{DD}$ in parallel with the replica branch $R_\mathrm{rep}$:

$$
\Delta I_\mathrm{TIA} = i_\mathrm{sc} \, \frac{r_\mathrm{d}}{r_\mathrm{d} + R_\mathrm{ext}}, \qquad R_\mathrm{ext} = R_\mathrm{s} + R_1 + (R_3 \parallel R_\mathrm{rep}) + R_\mathrm{in} .
$$

The loop closes through the bias node. 30 % of the returning current comes from $V_\mathrm{DD}$ through $R_3$, and 70 % comes through the replica branch, against the forward current of the replica diode. That lowers the replica diode current, so $V_\mathrm{ref}$ rises while $V_\mathrm{out}$ falls, and both changes add in $V_\mathrm{out} - V_\mathrm{ref}$. The replica therefore cancels the offset and adds to the signal.

The TIA numbers follow from the operating point. With $g_\mathrm{m}$ and $g_\mathrm{ds}$ the sums over the NMOS and the PMOS of one inverter, the voltage gain, the input resistance and the transimpedance of the shunt-feedback stage are

$$
A = \frac{g_\mathrm{m} - 1/R_2}{g_\mathrm{ds} + 1/R_2}, \qquad R_\mathrm{in} = \frac{R_2}{1 + A}, \qquad Z_\mathrm{T} = \frac{A\, R_2}{1 + A} .
$$

The detector TIA has $A$ = 11.9, $R_\mathrm{in}$ = 70.6 Ohm and $Z_\mathrm{T}$ = 840.1 Ohm. The replica TIA has $A$ = 2.57, $R_\mathrm{in}$ = 255 Ohm and $Z_\mathrm{T}$ = 655.4 Ohm. The replica branch is $R_5$, its diode and its TIA input in series, with 968 Ohm the $r_\mathrm{d}$ of the replica diode at 28.24 uA:

$$
R_\mathrm{rep} = 52 + 1360 + 968 + 255 = 2636\ \Omega, \qquad
R_\mathrm{ext} = 1360 + 52 + (6233 \parallel 2636) + 71 = 3335\ \Omega .
$$

This predicts that $899.7/(899.7 + 3335)$ = 21.2 % of $i_\mathrm{sc}$ reaches the TIA, and that $6233/(6233 + 2636)$ = 70.3 % of the return current passes the replica.

The HB sweep measures both. The dc bins of the branch currents of $R_1$, $R_2$, $R_4$ and $R_5$ and of the output nodes, taken against the lowest sweep point, give for the same -37 dBm point:

| quantity | $m = 1$ | $m = 16$ |
|---|---|---|
| $i_\mathrm{sc} = \beta_{I,\mathrm{max}} P_\mathrm{j}$ | 30.06 nA | 102.98 nA |
| $\Delta I_\mathrm{TIA}$, the change of the current in $R_2$ | 6.29 nA | 36.37 nA |
| $\Delta I_\mathrm{TIA} / i_\mathrm{sc}$ | 20.9 % | 35.3 % |
| change of the replica diode current over $\Delta I_\mathrm{TIA}$ | -70.1 % | -83.9 % |
| $\Delta V_\mathrm{out} / \Delta I_\mathrm{TIA}$ | 840.1 Ohm | 840.4 Ohm |
| $\Delta V_\mathrm{ref} / \Delta I_\mathrm{replica}$ | 655.4 Ohm | 655.6 Ohm |
| $\Delta(V_\mathrm{out} - V_\mathrm{ref}) / \Delta I_\mathrm{TIA}$ | 1299.8 Ohm | 1390.6 Ohm |

The hand calculation lands within 2 % of each simulated ratio. The chain from available power to output voltage then splits into five measured factors:

| factor | $m = 1$ | in dB | $m = 16$ | in dB |
|---|---|---|---|---|
| delivered into the input, of $P_\mathrm{in}$ | 99.1 % | -0.04 | 81.2 % | -0.91 |
| into the diode branch | 2.32 % | -16.34 | 13.2 % | -8.78 |
| absorbed in the junction | 35.8 % | -4.46 | 26.3 % | -5.81 |
| rectified current that reaches the TIA | 20.9 % | -6.79 | 35.3 % | -4.52 |
| readout, $\Delta(V_\mathrm{out} - V_\mathrm{ref})/\Delta I_\mathrm{TIA}$ over $R_2$ | 1.427 | +1.54 | 1.526 | +1.84 |
| product, $\eta$ at -37 dBm | 0.246 % | -26.09 | 1.52 % | -18.18 |
| $\eta$ from the fitted $\beta$ | 0.247 % | | 1.505 % | |

With $i_\mathrm{sc}$ defined as $\beta_{I,\mathrm{max}} P_\mathrm{j}$, the product is $\eta$ at that drive by construction. The factors are what carries information: they say where the power and the current go. The product differs from $\eta$ of the fitted $\beta$ by 0.6 % and 1.0 %, the local deviation from the fit at -37 dBm. Reading the $m = 1$ column: the termination $R_1$ is the largest single loss at 16 dB, the dc current division costs 6.8 dB, the series resistance and the junction capacitance 4.5 dB, and the replica readout gives 1.5 dB back. The 0.25 % is therefore not all lost in front of the junction: 6.8 dB of the 26 dB are lost behind it.

## 5. The 16-cell and the post-layout versions

**Sixteen cells.** `powdet_variant.py` sets both diodes to `nx=4 ny=4`. The model scales `rsmain` as $1360/(N_x N_y)$, so the series resistance drops 16-fold to 85.0 Ohm, which the operating point confirms. The junction capacitance and `cstray` grow 16-fold. From `sparx_powdet_sbd_beta_m16.json`:

| quantity | value | text |
|---|---|---|
| $\beta$ | 250.8 V/W | 251 V/W |
| $\eta$ | 1.505 % | 1.5 % |
| $Z_\mathrm{in}$ at 161 GHz | 27.93 - j28.43 Ohm | (28 - j28) Ohm |
| $P_\mathrm{1dB}$ | -13.26 dBm | -13.3 dBm |
| fit region of $\beta$ | -68.7 dBm to -15.0 dBm | |

$\beta$ rises 6.1-fold (7.8 dB). The budget of Section 4.4 shows where: the branch now takes 13.2 % of the power instead of 2.3 %, and more of the rectified current reaches the TIA, since the dc loop sees 85 Ohm of series resistance in each diode instead of 1360 Ohm. Against that, the input mismatch now costs 0.9 dB, and the 16 junction capacitances shunt the junction so far that its real part drops below the 85 Ohm of $R_\mathrm{s}$, which still takes 74 % of the branch power.

**Post-layout.** The extracted netlist adds the parasitic capacitances and the route resistances of supply, output and reference, see [Design variants](README.md#design-variants-and-why-no-symbol-is-swapped). From `sparx_powdet_sbd_beta_m1_pex.json`: $\beta$ = 38.78 V/W, 5.9 % below the 41.22 V/W of the schematic (the "6 %" of the text), $\eta$ = 0.233 %, $Z_\mathrm{in}$ = 40.27 - j25.01 Ohm and $P_\mathrm{1dB}$ = -2.42 dBm. The video bandwidth is in Section 6.2.

## 6. Video bandwidth and noise-equivalent power

Source: `sparx_powdet_sbd_tb_nf_vacask`. The `noise` and `hbac` analyses sweep 1 kHz to 5 GHz on 135 log-spaced points, 20 per decade. The values quoted at 1 MHz, 1 GHz and 2 GHz are taken at the nearest grid points, 0.999 MHz, 0.998 GHz and 1.991 GHz.

### 6.1 Video response

A detected signal modulated at the video frequency $f$ passes the same baseband network as the IF of the LO-pumped detector: the junction, the TIA and the 5 pF off-chip capacitor. The script therefore takes the normalized `hbac` conversion of the upper sideband, with the LO at -6.5 dBm, as the video response:

$$
\lvert H(f) \rvert^2 = \frac{g_\mathrm{U}(f)}{g_\mathrm{U}(f_\mathrm{min})}, \qquad f_\mathrm{min} = 1\ \mathrm{kHz},
$$

with $g_\mathrm{U}$ the conversion gain of Section 7.1 (column `g_usb` of `sparx_powdet_sbd_nf.csv`). The responsivity at the video frequency is $\beta(f) = \beta \lvert H(f) \rvert$ (column `beta_f_vw`).

### 6.2 Video bandwidth

The video bandwidth is the frequency where $\lvert H \rvert^2$ falls to 1/2. The script prints the first grid point below that level. Interpolated between the grid points, with a cubic fit of $\lvert H \rvert^2$ in dB against $\log f$ over the six points around the crossing, the bandwidths are lower:

| version | first grid point below -3 dB | interpolated -3 dB frequency | peak of $\lvert H \rvert^2$ |
|---|---|---|---|
| $m = 1$ | 1.256 GHz | 1.243 GHz | +0.49 dB at 316 MHz |
| post-layout | 1.120 GHz | 1.076 GHz | +0.51 dB at 316 MHz |
| $m = 16$ | 1.774 GHz | 1.604 GHz | +6.09 dB at 223 MHz |

The paper quotes the grid values. "The 1.3 GHz video bandwidth" is 1.256 GHz rounded, and the interpolated value is 1.24 GHz. "PEX reduces the video bandwidth by 11 %" is the ratio of the two grid points, 1.120 / 1.256 = $10^{-0.05}$, exactly one grid step. Interpolated, the reduction is 13.4 % (13.6 % with log-log interpolation). For $m = 16$ the junction capacitance at the TIA input causes 6 dB of peaking, which a bandwidth relative to 1 kHz hides.

### 6.3 Noise-equivalent power

The NEP is the input power that gives a signal-to-noise ratio of one in a 1 Hz bandwidth at the video frequency $f$. The detected signal is $\beta(f) P$ and the noise in 1 Hz is $\sqrt{S_v(f)}$, so [2]

$$
\mathrm{NEP}(f) = \frac{\sqrt{S_v(f)}}{\beta(f)} = \frac{\sqrt{S_v(f)}}{\beta \lvert H(f) \rvert} .
$$

$S_v$ is the output noise of the `noise` analysis at the dc operating point (column `asd_v`, squared), since the NEP describes the detector without an LO. Dividing by $\beta$ instead of $\beta(f)$ would understate the NEP by 20 dB at 5 GHz. From `nep_W_per_rtHz` of the NF JSON files:

| video frequency | $m = 1$ | post-layout | $m = 16$ |
|---|---|---|---|
| 1 MHz | 8.68 nW/sqrt(Hz) | 9.46 nW/sqrt(Hz) | 0.718 nW/sqrt(Hz) |
| 1 GHz | 225.9 pW/sqrt(Hz) | 247.2 pW/sqrt(Hz) | 13.48 pW/sqrt(Hz) |
| 2 GHz | 177.9 pW/sqrt(Hz) | 198.0 pW/sqrt(Hz) | 11.72 pW/sqrt(Hz) |
| ratio of 1 MHz to 1 GHz | 38.4 | 38.3 | 53.2 |

The ratio 38.4 is the "38-fold" improvement of an LO offset to a 1 GHz IF in the text. A conventional six-port detects at dc, where the NEP is that of the 1 MHz row or worse.

For comparison, the paper cites 250 V/W and 33 pW/sqrt(Hz) at 1 MHz modulation reported for a 280 GHz Schottky detector in 130 nm CMOS [2]. That detector is antenna-coupled and characterized at 1 MHz, so the like-for-like SPARX numbers are those of the 1 MHz row, and the 13.5 pW/sqrt(Hz) of the 16-cell design holds at a 1 GHz video frequency only.

### 6.4 What sets the noise

The `noise` analysis runs with `save full`, so `simulations/powdet_nf_noise.raw` holds every contribution. Integrated from 1 MHz to 5 GHz, the output noise power of the fabricated design divides as follows:

| contribution | share |
|---|---|
| `n(xdemod1:XD1:q1,flicker)`, PNP of the detector diode | 73.97 % |
| `n(xdemod1:XD2:q1,flicker)`, PNP of the replica diode | 22.60 % |
| `n(xdemod1:XR2:nr1)`, TIA feedback resistor | 1.96 % |
| `n(xdemod1:XD1:rsmain)`, series resistance | 0.41 % |
| everything else | 1.06 % |

The two PNP contributions are all flicker noise and add to 96.6 %, the "97 % of the output noise power" of the text. The device is `Q1 A C S mod1_pnp` inside the `schottky_nbl1` subcircuit: the anode side is the collector, the n-well under the Schottky contact the base, and the substrate the emitter, a vertical PNP. Its flicker model is $K_\mathrm{F} I_\mathrm{B}^{A_\mathrm{F}}/f$ with $K_\mathrm{F}$ = 6.70e-8 and $A_\mathrm{F}$ = 0.53 on a base current of about 20 pA. The same share follows from the committed JSON alone, since the script reports the MDS with and without the PNP contributors: $1 - (P_\mathrm{MDS,noPNP}/P_\mathrm{MDS})^2$ = 96.57 %.

The flicker corner, where the PNP carries half the output noise, is at 3.7 GHz for $m = 1$ (3.3 GHz post-layout), above the video bandwidth, so the fabricated detector is flicker-limited across its whole video band. For $m = 16$ the corner is at 1.04 GHz, and at 1 GHz the PNP still carries 51 % of the output noise.

## 7. Noise figure and Eq. (3)

With an LO applied, the detector is a mixer, and a mixer has a well-defined noise figure. Source: `sparx_powdet_sbd_tb_nf_vacask`, with the LO at 159 GHz and 300 mV source amplitude, that is $P_\mathrm{LO}$ = -6.48 dBm, the "-6.5 dBm" operating point.

### 7.1 Conversion gain in V²/W

An RF tone of available power $P_\mathrm{RF}$ in the upper sideband, at $f_\mathrm{LO} + f_\mathrm{IF}$, or in the lower sideband, at $f_\mathrm{LO} - f_\mathrm{IF}$, produces an IF output of peak amplitude $\lvert V_\mathrm{IF} \rvert$. The paper defines the transducer conversion gain as the mean-square output voltage per watt of available input power:

$$
g = \frac{\lvert V_\mathrm{IF} \rvert^2}{2 P_\mathrm{RF}} \quad [\mathrm{V^2/W}] .
$$

The detector drives a high-impedance load, so a power gain to the output is not defined, but the noise figure needs only ratios of output quantities at the same node, and V²/W is enough. `hbac` gives $g_\mathrm{U}(f)$ and $g_\mathrm{L}(f)$ for a unit source tone at either sideband (columns `g_usb`, `g_lsb`). `hbnoise` reports a `gain` $= \lvert V_\mathrm{IF}/V_\mathrm{in} \rvert^2$ for a unit tone of source amplitude $V_\mathrm{in}$ at its input sideband, and with $P_\mathrm{RF} = \lvert V_\mathrm{in} \rvert^2/(8 R_\mathrm{src})$,

$$
g = \frac{\lvert V_\mathrm{IF} \rvert^2 / 2}{\lvert V_\mathrm{in} \rvert^2 / (8 R_\mathrm{src})} = 4 R_\mathrm{src} \cdot \mathrm{gain} .
$$

The two agree to 3e-14 dB over the IF sweep and to 0.005 dB over the LO sweep (`hbnoise_gain_vs_hbac_max_dB`, `hbnoise_gain_vs_hbac_lo_sweep_max_dB`).

### 7.2 Derivation of Eq. (3)

The noise factor is the total output noise with the source termination at $T_0 = 290$ K, divided by the part of it the source termination causes:

$$
F = \frac{N_\mathrm{out}}{N_\mathrm{out,src}} .
$$

**Noise of the source.** The source resistance $R_\mathrm{src}$ at $T_0$ has the open-circuit noise voltage density $4kT_0R_\mathrm{src}$ and therefore the available noise power density $kT_0$, white. In a 1 Hz band at the upper sideband it acts like an input of available power $kT_0 \cdot 1\ \mathrm{Hz}$, which by the definition of $g$ produces the mean-square output $g_\mathrm{U} kT_0$ in 1 Hz at $f_\mathrm{IF}$. The 1 Hz band at the lower sideband produces $g_\mathrm{L} kT_0$ at the same IF. The two bands carry independent noise, so their powers add:

$$
N_\mathrm{out,src} = (g_\mathrm{U} + g_\mathrm{L})\, kT_0 \quad [\mathrm{V^2/Hz}] .
$$

**Noise of the detector.** $S_v(f_\mathrm{IF})$ is the output noise density with the LO on, from all noise sources of the detector, each modulated by the pumped operating point and folded from every sideband of every LO harmonic onto $f_\mathrm{IF}$. That is the `onoise` of `hbnoise`, with the contribution of the simulator's own source resistor removed. The total output noise is

$$
N_\mathrm{out} = S_v(f_\mathrm{IF}) + (g_\mathrm{U} + g_\mathrm{L})\, kT_0 .
$$

**Result.** Dividing the two gives Eq. (3) of the paper:

$$
F_\mathrm{DSB} = \frac{S_v(f_\mathrm{IF}) + (g_\mathrm{U} + g_\mathrm{L})\, kT_0}{(g_\mathrm{U} + g_\mathrm{L})\, kT_0} = 1 + \frac{S_v(f_\mathrm{IF})}{(g_\mathrm{U} + g_\mathrm{L})\, kT_0} .
$$

Numerator and denominator are both output voltage densities in V²/Hz, so the load impedance cancels. The source term is computed rather than taken from the simulator for two reasons. The simulator's resistor sits at 300.15 K, not at $T_0$. And it also reaches the output through every other sideband $k f_\mathrm{LO} \pm f_\mathrm{IF}$ with $k \neq 1$, which the double-sideband definition does not count as source noise. Both effects are small here. In `hbnoise` the simulator's source resistor carries at most 1.4e-4 of the output noise of the fabricated detector and 2.8e-3 for $m = 16$, about $1/F$, so nearly all of it enters through the two signal sidebands that Eq. (3) adds back exactly.

The script evaluates Eq. (3) once with $S_v$ from `hbnoise` (`nf_dsb_db`, the result), once with $S_v$ from `pnoise` and $g$ from `pac` (`nf_dsb_pnoise_db`, the shooting check), and once with the small-signal `noise` at the dc operating point in the numerator (`nf_dsb_quiescent_db`, the estimate available before periodic noise analysis existed).

### 7.3 Double sideband, single sideband, and the 3 dB

In homodyne operation, $f_\mathrm{RF} = f_\mathrm{LO}$, both sidebands fold onto the same baseband and both carry signal, so the double-sideband definition applies [3]. In the low-IF mode the RF occupies one sideband, the image carries only noise, and its source noise counts against the signal:

$$
F_\mathrm{SSB} = 1 + \frac{g_\mathrm{L}}{g_\mathrm{U}} + \frac{S_v}{g_\mathrm{U}\, kT_0} = \left(1 + \frac{g_\mathrm{L}}{g_\mathrm{U}}\right) F_\mathrm{DSB} .
$$

The sidebands of this detector are balanced within 0.02 dB at 2 GHz (`sideband_imbalance_gL_over_gU_dB`), so $\mathrm{NF}_\mathrm{SSB} = \mathrm{NF}_\mathrm{DSB}$ + 3.02 dB. That is the "low-IF mode adds 3 dB" of the text: 45.23 dB SSB against 42.21 dB DSB at 2 GHz (`nf_ssb_db`, `nf_dsb_db`).

### 7.4 Conversion gain from the transfer curve

The text checks the `hbac` conversion against $g = 2 S'^2 P_\mathrm{LO}$. Derivation: two tones from the same source, $e(t) = a_\mathrm{LO}\cos\omega_\mathrm{LO}t + a_\mathrm{RF}\cos(\omega_\mathrm{RF}t + \varphi)$, form a carrier with a slowly varying envelope. Its available power over one carrier period is

$$
P(t) = \frac{\lvert a_\mathrm{LO} + a_\mathrm{RF}\, e^{\mathrm{j}(\omega_\mathrm{IF}t + \varphi)} \rvert^2}{8 R_\mathrm{src}} = P_\mathrm{LO} + P_\mathrm{RF} + 2\sqrt{P_\mathrm{LO} P_\mathrm{RF}}\, \cos(\omega_\mathrm{IF}t + \varphi) .
$$

If the detector follows the envelope, that is for $f_\mathrm{IF}$ well inside the video bandwidth, the output is the transfer curve $\Delta V = S(P)$ evaluated at $P(t)$. For $P_\mathrm{RF} \ll P_\mathrm{LO}$ a first-order expansion around $P_\mathrm{LO}$ gives

$$
\Delta V(t) \approx S(P_\mathrm{LO}) + S'(P_\mathrm{LO}) \left[ P_\mathrm{RF} + 2\sqrt{P_\mathrm{LO} P_\mathrm{RF}}\, \cos(\omega_\mathrm{IF}t + \varphi) \right],
$$

so $\lvert V_\mathrm{IF} \rvert = 2 S'(P_\mathrm{LO}) \sqrt{P_\mathrm{LO} P_\mathrm{RF}}$ and

$$
g = \frac{\lvert V_\mathrm{IF} \rvert^2}{2 P_\mathrm{RF}} = 2\, S'(P_\mathrm{LO})^2\, P_\mathrm{LO} .
$$

In the square-law region $S' = \beta$, and $V_\mathrm{IF} = 2\beta\sqrt{P_\mathrm{LO}P_\mathrm{RF}}$ is proportional to $V_\mathrm{LO}V_\mathrm{RF}$, the square law of Section 3.2. The -6.5 dBm operating point lies only 3.7 dB below $P_\mathrm{1dB}$, where the curve already bends, so the local slope must be used. The NF script takes $S' = \mathrm{d}\lvert\Delta V\rvert/\mathrm{d}P$ numerically from the HB curve in the beta JSON and interpolates it at $P_\mathrm{LO}$:

| version | $\beta$ | $S'$ at -6.48 dBm | `hbac` at 1 kHz against $2S'^2P_\mathrm{LO}$ | against $2\beta^2P_\mathrm{LO}$ |
|---|---|---|---|---|
| $m = 1$ | 41.22 V/W | 38.01 V/W | +0.13 dB | -0.58 dB |
| post-layout | 38.78 V/W | 36.42 V/W | +0.16 dB | -0.39 dB |
| $m = 16$ | 250.8 V/W | 98.01 V/W | +0.10 dB | -8.06 dB |

The "within 0.16 dB" of the text is the largest entry of the fourth column (`hbac_minus_closed_form_dB`). The $m = 16$ row shows why $S'$ and not $\beta$: its LO sits 6.8 dB above its own $P_\mathrm{1dB}$.

### 7.5 How the noise figure relates to the NEP

Set $g_\mathrm{U} \approx g_\mathrm{L} \approx 2S'^2P_\mathrm{LO}\lvert H(f)\rvert^2$ from Section 7.4, and write the output noise as $S_v(f) = \mathrm{NEP}(f)^2 \beta^2 \lvert H(f)\rvert^2$ from Section 6.3. Eq. (3) then becomes

$$
F_\mathrm{DSB} - 1 \approx \frac{\mathrm{NEP}(f_\mathrm{IF})^2}{4\, P_\mathrm{LO}\, kT_0} \left(\frac{\beta}{S'}\right)^2 .
$$

The noise figure is the NEP squared in units of $4P_\mathrm{LO}kT_0$. With the noise at the dc operating point, NEP = 177.9 pW/sqrt(Hz) at 2 GHz, $P_\mathrm{LO}$ = 225 uW and $(\beta/S')^2$ = 1.18, this gives 40.14 dB, against the 40.00 dB the bench computes exactly (`nf_dsb_quiescent_db`). The difference is mostly the 0.13 dB by which `hbac` exceeds the closed form. The relation explains the shape of Fig. 7(b). In the square-law region the noise figure falls 1 dB per dB of LO power, and it can only be small where the NEP is small. The LO also raises the noise: `hbnoise` puts $S_v$ at 2 GHz 1.66 times above the dc value (`pumped_over_quiescent`), which turns 40.0 dB into 42.2 dB.

### 7.6 Fig. 7(b): noise figure against LO power

The NF bench sweeps the LO source amplitude from 1 mV to 1.4 V at 6 points per decade, 20 points from -56.0 dBm to +6.9 dBm, with `hbac` and `hbnoise` at a fixed 2 GHz IF and 15 harmonics, and `pnoise` at each point as the check (`sparx_powdet_sbd_nf_lo<suffix>.csv`). The grid point nearest the operating point is -6.34 dBm. The minima of the `hbnoise` curves (`nf_dsb_best_dB`, `p_lo_best_W`):

| version | minimum $\mathrm{NF}_\mathrm{DSB}$ | at $P_\mathrm{LO}$ | `pnoise` at the same point |
|---|---|---|---|
| $m = 1$ | 42.34 dB | -6.34 dBm | 42.27 dB |
| post-layout | 42.67 dB | -6.34 dBm | 42.71 dB |
| $m = 16$ | 26.78 dB | -3.03 dBm | 26.72 dB |

The IF sweep at the fixed -6.48 dBm runs at 9 harmonics and gives 42.21, 42.69 and 26.73 dB at 1.991 GHz. The differences of up to 0.13 dB to the LO sweep come mostly from the harmonic truncation of `hbnoise`, 9 against 15 harmonics, see [README, nine harmonics](README.md#nine-harmonics-are-not-enough-above-compression).

**PAC and PNOISE.** From the `shooting_check` block of the NF JSON files:

| difference | $m = 1$ | post-layout | $m = 16$ |
|---|---|---|---|
| `pac` - `hbac`, conversion, both sidebands, 1 kHz to 5 GHz | +0.005 to +0.007 dB | -0.010 to -0.007 dB | +0.008 to +0.027 dB |
| `pnoise` - `hbnoise`, output noise, 1 kHz to 5 GHz | +0.05 to +0.10 dB | +0.01 to +0.04 dB | -0.18 to +0.13 dB |
| `pnoise` - HB, NF over the LO sweep | -0.07 to +0.10 dB | -0.13 to +0.05 dB | -0.06 to +0.02 dB |

The largest magnitude is 0.18 dB, the "within 0.2 dB" of the text.

**Transient noise and the small-signal estimate.** `sparx_powdet_sbd_tb_tn_lo_vacask` runs the transient-noise ladder of [README, 3.4](README.md#34-transient-noise-the-independent-check-of-hbnoise) at nine points of the same LO grid and converts its linear term into a noise figure with the same `hbac` conversion (`sparx_powdet_sbd_tn_lo.csv`, fabricated design):

| $P_\mathrm{LO}$ | transient | `hbnoise` | `pnoise` | dc operating point | transient - `hbnoise` | `hbnoise` - dc operating point |
|---|---|---|---|---|---|---|
| -49.40 dBm | 82.59 dB | 81.96 dB | 81.96 dB | 82.04 dB | +0.63 dB | -0.08 dB |
| -42.77 dBm | 75.97 dB | 75.34 dB | 75.34 dB | 75.42 dB | +0.63 dB | -0.08 dB |
| -36.15 dBm | 69.35 dB | 68.72 dB | 68.72 dB | 68.79 dB | +0.64 dB | -0.08 dB |
| -29.53 dBm | 62.75 dB | 62.10 dB | 62.10 dB | 62.16 dB | +0.65 dB | -0.06 dB |
| -22.90 dBm | 56.17 dB | 55.51 dB | 55.51 dB | 55.50 dB | +0.66 dB | +0.01 dB |
| -16.28 dBm | 49.79 dB | 49.06 dB | 49.06 dB | 48.76 dB | +0.72 dB | +0.31 dB |
| -6.34 dBm | 43.12 dB | 42.34 dB | 42.27 dB | 39.99 dB | +0.78 dB | +2.35 dB |
| +0.28 dBm | 45.11 dB | 44.21 dB | 44.16 dB | 38.10 dB | +0.90 dB | +6.11 dB |
| +6.90 dBm | 47.08 dB | 45.94 dB | 46.03 dB | 37.50 dB | +1.14 dB | +8.44 dB |

The transient lies 0.63 dB to 1.14 dB above `hbnoise`, the "0.6 dB to 1.1 dB above" of the text. That offset depends on the noise realization of the transient by up to about 1 dB, see [README, 3.5](README.md#35-noise-figure-against-lo-drive-from-four-noise-estimates). The small-signal noise at the dc operating point is 2.35 dB optimistic at the minimum and 8.44 dB at +6.9 dBm. It keeps falling above -16 dBm, because the conversion keeps rising while its noise stays that of the unpumped diode. With the LO on, the average diode current rises, the PNP flicker of the detector diode grows with its base current, and the noise outruns the conversion, so all three large-signal analyses show the noise figure rising past its minimum.

![Noise figure of the fabricated detector at 2 GHz IF against LO power, four noise estimates](plot_simulations/figures/sparx_powdet_sbd_nf_lo_compare.png)

## 8. Minimum detectable power

The paper defines the minimum detectable power as the input whose detected voltage equals the output noise integrated over the video band:

$$
P_\mathrm{MDS} = \frac{v_\mathrm{n,rms}}{\beta}, \qquad v_\mathrm{n,rms}^2 = \int_{1\ \mathrm{MHz}}^{5\ \mathrm{GHz}} S_v(f)\, \mathrm{d}f ,
$$

with $S_v$ at the dc operating point as for the NEP, integrated with the trapezoidal rule on the analysis grid. The lower limit corresponds to an ac-coupled readout, and 5 GHz is the end of the analysis, beyond the video bandwidth. From the `mds` block of the NF JSON files:

| version | $v_\mathrm{n,rms}$, 1 MHz to 5 GHz | $P_\mathrm{MDS}$ | dc-coupled, from 1 kHz |
|---|---|---|---|
| $m = 1$ | 905.3 uV | -16.58 dBm | -14.99 dBm |
| post-layout | 919.6 uV | -16.25 dBm | -14.64 dBm |
| $m = 16$ | 466.6 uV | -27.30 dBm | -25.77 dBm |

All three lie inside the square-law region of their version, so dividing by the small-signal $\beta$ is consistent.

## 9. Paper values against the data

| text of Section IV | data | where |
|---|---|---|
| HB and shooting PSS agree within 0.6 % | 0.57 % from -66 dBm to +4 dBm | 3.6 |
| $\beta$ = 41 V/W | 41.216 V/W | 3.3 |
| flat from -71 dBm to -8 dBm | fit region -71.1 dBm to -7.7 dBm, within -0.6 % and +3.2 % | 3.3 |
| 1 dB compressed at -2.7 dBm | -2.74 dBm | 3.4 |
| (51 - j10) Ohm up to compression | 50.94 - j9.80 Ohm to 51.14 - j9.99 Ohm | 3.5 |
| $\eta$ = 0.25 % | 0.247 % | 4.2 |
| $\beta_{I,\mathrm{max}}$ = 18.29 A/W | 18.289 A/W | 4.1 |
| series resistance 1.36 kOhm, junction resistance 0.9 kOhm at 30 uA | 1360.0 Ohm, 899.7 Ohm at 30.39 uA | 2 |
| about 2 % into the diode branch | 2.24 % at dc, 2.32 % at 161 GHz | 4.3 |
| $m = 16$: 251 V/W, 1.5 %, (28 - j28) Ohm, -13.3 dBm | 250.8 V/W, 1.505 %, 27.93 - j28.43 Ohm, -13.26 dBm | 5 |
| PEX reduces $\beta$ by 6 % | 5.9 % | 5 |
| PEX reduces the video bandwidth by 11 % | 10.9 % between grid points, 13.4 % interpolated | 6.2 |
| NEP 8.7 nW/sqrt(Hz) at 1 MHz, 226 pW/sqrt(Hz) at 1 GHz | 8.68 nW/sqrt(Hz), 225.9 pW/sqrt(Hz) | 6.3 |
| 97 % flicker noise of the parasitic PNP | 96.6 % | 6.4 |
| 1.3 GHz video bandwidth | 1.256 GHz at the grid, 1.243 GHz interpolated | 6.2 |
| NEP improves 38-fold | 38.4 | 6.3 |
| 13 pW/sqrt(Hz) at 1 GHz for $m = 16$, above the flicker corner | 13.48 pW/sqrt(Hz), flicker corner at 1.04 GHz | 6.3, 6.4 |
| low-IF mode adds 3 dB | 3.02 dB | 7.3 |
| `hbac` within 0.16 dB of $2S'^2P_\mathrm{LO}$ | +0.10 dB to +0.16 dB | 7.4 |
| NF minimum 42.3 dB and 42.7 dB at -6.3 dBm, 26.8 dB at -3.0 dBm | 42.34 dB and 42.67 dB at -6.34 dBm, 26.78 dB at -3.03 dBm | 7.6 |
| PAC and PNOISE within 0.2 dB | 0.18 dB at most | 7.6 |
| TN 0.6 dB to 1.1 dB above | 0.63 dB to 1.14 dB | 7.6 |
| small-signal estimate 2.4 dB optimistic at the minimum | 2.35 dB | 7.6 |
| 8.4 dB optimistic at 6.9 dBm | 8.44 dB | 7.6 |
| MDS -16.6 dBm, -16.2 dBm, -27.3 dBm | -16.58 dBm, -16.25 dBm, -27.30 dBm | 8 |

Four entries need a remark. The 1.3 GHz video bandwidth and the 11 % reduction from PEX are values of the 20-points-per-decade analysis grid, and the interpolated values are 1.24 GHz and 13.4 %. The 2.4 dB at the noise-figure minimum is 2.35 dB, which rounds to 2.3 dB. And for $m = 16$, 1 GHz lies at its flicker corner of 1.04 GHz rather than above it.

## 10. Reproducing the numbers

The benches need VACASK `1b48553` or later, see [README, Running a testbench](README.md#running-a-testbench). Run them in this order, because the NF script reads the responsivity of the PSS run, and the transient-noise script reads the NF results:

```bash
make sim-xschem TB=sparx_powdet_sbd_tb_pss_vacask      # transfer curve, beta JSON
make sim-xschem TB=sparx_powdet_sbd_tb_nf_vacask       # NEP, NF, MDS, needs the beta JSON
make sim-xschem TB=sparx_powdet_sbd_tb_tn_lo_vacask    # transient noise against LO power, about 24 minutes
make sim-powdet-variants                               # PSS and NF benches for m16 and m1_pex
```

The headline numbers of all three versions follow from the committed data files alone, run from the repository root:

```python
import json
import numpy as np

D = 'testbenches/xschem/plot_simulations/data/'
VT, N, R2 = 1.380649e-23 * 300.15 / 1.602176634e-19, 1.057, 911.0
dbm = lambda p: 10 * np.log10(p / 1e-3)
for v in ('', '_m1_pex', '_m16'):
    b = json.load(open(f'{D}sparx_powdet_sbd_beta{v}.json'))
    n = json.load(open(f'{D}sparx_powdet_sbd_nf{v}.json'))
    beta, f = abs(b['beta_V_per_W']), np.asarray(n['f_Hz'])
    nep = np.asarray(n['nep_W_per_rtHz'])
    at = lambda x: int(np.argmin(np.abs(f - x)))
    lo = n['nf_vs_plo']
    i = int(np.argmin(lo['nf_dsb_dB']))
    mds = n['mds']['1e+06-5e+09']
    print(f"{v or '_m1':8s} beta {beta:6.1f} V/W  P1dB {dbm(b['p_1db_W']):6.2f} dBm  "
          f"Zin {b['z_in_small_signal_ohm'][0]:.1f}{b['z_in_small_signal_ohm'][1]:+.1f}j Ohm  "
          f"eta {100 * beta / R2 * 2 * N * VT:.3f} %  "
          f"NEP {nep[at(1e6)] * 1e9:.2f} nW, {nep[at(1e9)] * 1e12:.1f} pW/sqrt(Hz)  "
          f"NF min {lo['nf_dsb_dB'][i]:.2f} dB at {dbm(lo['p_lo_W'][i]):.2f} dBm  "
          f"MDS {dbm(mds['mds_W']):.2f} dBm  PNP {100 * (1 - (mds['mds_no_pnp_W'] / mds['mds_W']) ** 2):.1f} %")
```

```
_m1      beta   41.2 V/W  P1dB  -2.74 dBm  Zin 50.9-9.8j Ohm  eta 0.247 %  NEP 8.68 nW, 225.9 pW/sqrt(Hz)  NF min 42.34 dB at -6.34 dBm  MDS -16.58 dBm  PNP 96.6 %
_m1_pex  beta   38.8 V/W  P1dB  -2.42 dBm  Zin 40.3-25.0j Ohm  eta 0.233 %  NEP 9.46 nW, 247.2 pW/sqrt(Hz)  NF min 42.67 dB at -6.34 dBm  MDS -16.25 dBm  PNP 96.9 %
_m16     beta  250.8 V/W  P1dB -13.26 dBm  Zin 27.9-28.4j Ohm  eta 1.505 %  NEP 0.72 nW, 13.5 pW/sqrt(Hz)  NF min 26.78 dB at -3.03 dBm  MDS -27.30 dBm  PNP 87.5 %
```

The operating point of Section 2 and the budget of Section 4.4 need the rawfiles of the PSS run in `simulations/`, read with `rawfile.py` from the `python/` folder of VACASK.

## 11. References

[1] A. M. Cowley and H. O. Sorensen, "Quantitative Comparison of Solid-State Microwave Detectors," IEEE Transactions on Microwave Theory and Techniques, vol. 14, no. 12, pp. 588-602, 1966, doi: 10.1109/TMTT.1966.1126337.

[2] R. Han, Y. Zhang, D. Coquillat, H. Videlier, W. Knap, E. Brown, and K. K. O, "A 280-GHz Schottky Diode Detector in 130-nm Digital CMOS," IEEE Journal of Solid-State Circuits, vol. 46, no. 11, pp. 2602-2612, 2011, doi: 10.1109/JSSC.2011.2165234.

[3] B. Razavi, RF Microelectronics, 2nd ed. Upper Saddle River, NJ, USA: Prentice-Hall, 2012, Sec. 6.1.2.
