v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
T {VACASK Transient-Noise Testbench for the SBD-Based Power Detector} 600 -1720 0 0 1 1 {}
T {SPDX-FileCopyrightText: 2025-2026 The SPARX Team
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
} 1920 -220 0 0 0.4 0.4 {}
N 800 -300 800 -280 {
lab=GND}
N 1020 -380 1020 -300 {lab=GND}
N 1020 -460 1020 -440 {lab=#net1}
N 1020 -660 1020 -600 {lab=rfin}
N 1020 -540 1020 -520 {lab=src}
N 1400 -300 1560 -300 {lab=GND}
N 1400 -800 1400 -720 {lab=vdd}
N 800 -300 1020 -300 {lab=GND}
N 1660 -520 1800 -520 {lab=out_cm}
N 1840 -470 1840 -300 {lab=GND}
N 1840 -590 1840 -530 {lab=out}
N 1560 -640 1560 -480 {lab=ref}
N 1560 -480 1800 -480 {lab=ref}
N 800 -380 800 -300 {lab=GND}
N 800 -800 800 -440 {lab=vdd}
N 1660 -300 1840 -300 {lab=GND}
N 1660 -360 1660 -300 {lab=GND}
N 1560 -300 1660 -300 {lab=GND}
N 1560 -360 1560 -300 {lab=GND}
N 1560 -480 1560 -420 {lab=ref}
N 1660 -520 1660 -420 {lab=out_cm}
N 1660 -680 1660 -520 {lab=out_cm}
N 1020 -660 1320 -660 {lab=rfin}
N 1400 -600 1400 -300 {lab=GND}
N 1020 -300 1400 -300 {lab=GND}
N 800 -800 1400 -800 {lab=vdd}
N 1480 -680 1660 -680 {lab=out_cm}
N 1480 -640 1560 -640 {lab=ref}
C {devices/vsource.sym} 800 -410 0 0 {name=vdd value="dc=1.5"}
C {devices/res.sym} 1020 -570 0 0 {name=Rs value=50}
C {devices/lab_pin.sym} 1020 -540 0 0 {name=p21 sig_type=std_logic lab=src}
C {devices/vsource.sym} 1020 -490 0 0 {name=vin3 value="type=\\"sine\\" sinedc=0 ampl=ampl_rf freq="freq_rf""}
C {devices/vsource.sym} 1020 -410 0 0 {name=vin2 value="type=\\"sine\\" sinedc=0 ampl=ampl_lo freq="freq_lo""}
C {simulator_commands_shown.sym} 1880 -1310 0 0 {
name=Libs_VACASK
simulator=vacask
only_toplevel=false
value="
include \\"sg13g2_vacask_common.lib\\"
include \\"cornerMOSlv.lib\\" section=mos_tt
include \\"cornerRES.lib\\" section=res_typ
include \\"cornerCAP.lib\\" section=cap_typ
include \\"cornerDIO.lib\\" section=dio_tt
"
      }
C {simulator_commands_shown.sym} 100 -1350 0 0 {
name=Script_VACASK
simulator=vacask
only_toplevel=false
value="
control
  // Transient noise. Four settings below are not optional on this circuit,
  // each was found by bisection against an aborting or wrong run:
  //
  //  1. noisemode=\\"sde\\". The default \\"zoh\\" aborts with \\"Timestep too small\\"
  //     on any PSP103 device, reproduced on a single sg13_lv_nmos.
  //  2. rsw on every sp_diode model card. devices/spice/diode.va guards the
  //     sidewall noise sources with if($param_given(rsw)), so without rsw the
  //     flickersw exponent is never assigned and stays 0, and VACASK rejects
  //     any exponent outside 0.1 .. 1.9. jsw defaults to 0, so the sidewall
  //     branch carries no current and the small-signal noise is unchanged to
  //     all printed digits for rsw anywhere in 1 mOhm .. 1 MOhm.
  //  3. tran_noiselte far above its default of 1, or the noise drives the
  //     timestep down until the run aborts. 100 is not enough here, 1e6 is.
  //     The result is insensitive to the value where both run: 100 and 1e4
  //     agreed to 1.5 % in the output ASD at 1 GHz.
  //  4. No noise analysis in this deck. A small-signal noise analysis
  //     anywhere in the same netlist aborts the transient immediately, in
  //     either order. The noise reference lives in the NF testbench.
  //
  // The noisescale ladder is the point of this bench. At full noise amplitude
  // the transient output noise on this detector comes out 3 to 8 times above
  // the small-signal noise analysis. Scaling every noise source by noisescale
  // and running the same transient three times separates a linear term, which
  // must reproduce the small-signal analysis and does to within 12 %, from
  // whatever the excess is. What it is not, is the detector rectifying its own
  // noise: that term is exactly second order in the noise amplitude and its
  // size follows from the junction curvature I0/(2 n^2 V_T^2) = 0.02 A/V^2
  // and the 0.36 mV RMS the white sources put across the junction in 20 GHz,
  // which gives 2.4e-11 V/rtHz at the output against 1.9e-8 observed at
  // 1 GHz. The excess also grows faster than second order between the two
  // upper rungs. The plot script prints both diagnostics. Until the mechanism
  // is understood, the full-amplitude transient noise of this circuit is a
  // simulator artefact, and this bench is a validation of the small-signal
  // noise analysis in the linear limit, nothing more. Hence not in sim-all.
  var freq_lo=159G
  var freq_rf=161G
  var ampl_rf=0
  // LO drive. 0 keeps the detector unpumped, which is the configuration the
  // small-signal reference can be compared against. Setting this to 300m
  // pumps the diode, but the timestep must then resolve 159 GHz, so drop
  // maxstep to 0.15p and expect about three times the run time per point.
  var ampl_lo=0
  save v(\\"out\\")
  options strictsave=1
  options tran_noiselte=1e6

  analysis sparx_powdet_sbd_tb_tn_vacask op

  alter model(\\"dmain_mod\\") rsw=1e-3
  alter model(\\"drev_mod\\") rsw=1e-3
  alter model(\\"dsub_mod\\") rsw=1e-3

  // One analysis per noisescale rather than a sweep over it: VACASK writes no
  // rawfile at all when a transient-noise run aborts, so one failing rung of a
  // sweep costs every other rung too. Separate analyses lose only themselves,
  // and the plot script reads the noisescale values back out of this netlist.
  analysis powdet_tn1 tran stop=100n step=1p maxstep=8p noisefmax=20G noisefmin=10M oversample=3 noiseseed=1 noisemode=\\"sde\\" noisescale=0.1
  analysis powdet_tn2 tran stop=100n step=1p maxstep=8p noisefmax=20G noisefmin=10M oversample=3 noiseseed=1 noisemode=\\"sde\\" noisescale=0.316227766
  analysis powdet_tn3 tran stop=100n step=1p maxstep=8p noisefmax=20G noisefmin=10M oversample=3 noiseseed=1 noisemode=\\"sde\\" noisescale=1.0

  postprocess(PYTHON, \\"../plot_simulations/plot_sparx_powdet_sbd_tb_tn_vacask.py\\")
endc
"}
C {sparx_powdet_sbd.sym} 1400 -660 0 0 {name=xdemod1}
C {capa.sym} 1560 -390 0 0 {name=C1
m=1
value=5p}
C {capa.sym} 1660 -390 0 0 {name=C2
m=1
value=5p}
C {title-3.sym} 0 0 0 0 {name=l4 author="Simon Dorrer" rev=1.0 lock=true}
C {devices/launcher.sym} 1620 -1260 0 0 {name=h5
descr="annotate OP" 
tclcommand="set show_hidden_texts 1; xschem annotate_op"
}
C {devices/gnd.sym} 800 -280 0 0 {name=l1 lab=GND}
C {devices/lab_pin.sym} 1020 -660 0 0 {name=p11 sig_type=std_logic lab=rfin}
C {devices/lab_pin.sym} 1660 -680 0 1 {name=p12 sig_type=std_logic lab=out_cm}
C {spice_probe.sym} 1020 -660 0 0 {name=p14 attrs=""}
C {spice_probe.sym} 1660 -680 0 0 {name=p15 attrs=""}
C {devices/lab_pin.sym} 1560 -640 0 1 {name=p16 sig_type=std_logic lab=ref}
C {spice_probe.sym} 1560 -640 0 0 {name=p17 attrs=""}
C {devices/lab_pin.sym} 800 -800 0 0 {name=p18 sig_type=std_logic lab=vdd}
C {vcvs.sym} 1840 -500 0 0 {name=E2 value=1}
C {spice_probe.sym} 1840 -590 0 0 {name=p19 attrs=""}
C {devices/lab_pin.sym} 1840 -590 0 1 {name=p20 sig_type=std_logic lab=out}
C {noconn.sym} 1840 -560 0 0 {name=l7}
C {sparx_powdet_sbd_pex.sym} 1400 -920 0 0 {name=xdemod2
spice_ignore=true
spectre_ignore=true}
C {launcher.sym} 1620 -1320 0 0 {name=h2
descr="Simulate VACASK"
tclcommand="
# Setup the default simulation commands if not already set up
# for example by already launched simulations.
set_sim_defaults
puts $sim(spectre,0,cmd)

# change the simulator to be used (#0 in spectre category is VACASK)
set sim(spectre,default) 0
xschem set netlist_type spectre

# Create FET and BIP .save file
mkdir -p $netlist_dir
write_data [save_params] $netlist_dir/[file rootname [file tail [xschem get current_name]]].save

# run netlist and simulation
xschem netlist
simulate
"}
