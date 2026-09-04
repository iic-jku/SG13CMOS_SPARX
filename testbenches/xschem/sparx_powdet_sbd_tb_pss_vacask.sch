v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
T {VACASK PSS (single-tone HB) Testbench for the SBD-Based Power Detector} 290 -1700 0 0 1 1 {}
T {SPDX-FileCopyrightText: 2025-2026 The SPARX Team
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
} 1920 -220 0 0 0.4 0.4 {}
N 1320 -360 1320 -340 {
lab=GND}
N 1540 -440 1540 -360 {lab=GND}
N 1540 -520 1540 -500 {lab=#net1}
N 1540 -720 1540 -660 {lab=rfin}
N 1540 -600 1540 -580 {lab=src}
N 1920 -360 2080 -360 {lab=GND}
N 1920 -860 1920 -780 {lab=vdd}
N 1320 -360 1540 -360 {lab=GND}
N 2180 -580 2320 -580 {lab=out_cm}
N 2360 -530 2360 -360 {lab=GND}
N 2360 -650 2360 -590 {lab=out}
N 2080 -700 2080 -540 {lab=ref}
N 2080 -540 2320 -540 {lab=ref}
N 1320 -440 1320 -360 {lab=GND}
N 1320 -860 1320 -500 {lab=vdd}
N 2180 -360 2360 -360 {lab=GND}
N 2180 -420 2180 -360 {lab=GND}
N 2080 -360 2180 -360 {lab=GND}
N 2080 -420 2080 -360 {lab=GND}
N 2080 -540 2080 -480 {lab=ref}
N 2180 -580 2180 -480 {lab=out_cm}
N 2180 -740 2180 -580 {lab=out_cm}
N 1540 -720 1840 -720 {lab=rfin}
N 1920 -660 1920 -360 {lab=GND}
N 1540 -360 1920 -360 {lab=GND}
N 1320 -860 1920 -860 {lab=vdd}
N 2000 -740 2180 -740 {lab=out_cm}
N 2000 -700 2080 -700 {lab=ref}
C {devices/vsource.sym} 1320 -470 0 0 {name=vdd value="dc=1.5"}
C {devices/res.sym} 1540 -630 0 0 {name=Rs value=50}
C {devices/lab_pin.sym} 1540 -600 0 0 {name=p21 sig_type=std_logic lab=src}
C {devices/vsource.sym} 1540 -550 0 0 {name=vin3 value="type=\\"sine\\" sinedc=0 ampl=1m freq="freq_rf""}
C {devices/vsource.sym} 1540 -470 0 0 {name=vin2 value="type=\\"sine\\" sinedc=0 ampl=0 freq="freq_lo""}
C {simulator_commands_shown.sym} 1880 -1370 0 0 {
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
  // Single RF tone. vin2 (the LO source) stays in the topology so that all
  // power-detector benches share one netlist, but it is idle here.
  var freq_rf=161G
  var freq_lo=159G

  include \\"sparx_powdet_sbd_tb_pss_vacask.save\\"
  save default

  analysis sparx_powdet_sbd_tb_pss_vacask op

  // The detected term is a sub-microvolt DC shift riding on a -7 mV output
  // offset, so the default tolerances do not resolve it: with reltol=1e-3 the
  // fitted responsivity is still wrong by 25 % at -40 dBm and diverges below
  // that. These settings hold beta flat to within 1 % down to -70 dBm.
  options reltol=1e-8 abstol=1e-16 vntol=1e-9

  // (1) Single-tone harmonic balance over the source amplitude. Rs = 50 Ohm,
  //     so the available power is a^2 / (8 * Rs). The plot script reads the
  //     DC bin of the spectrum at the output and the fundamental at the input.
  sweep ampl_rf instance=\\"vin3\\" parameter=\\"ampl\\" from=100u to=1.4 mode=\\"dec\\" points=8
    analysis powdet_pss1 hb freq=[freq_rf] nharm=15

  // (2) Shooting PSS at five amplitudes of the same grid, as the check of the
  //     harmonic balance: the plot script compares the period average of the
  //     output against the HB DC bin at the same amplitude. driven=1 fixes the
  //     period at 1/freq_rf, without it the shooting solves for the period of
  //     an oscillator and aborts. tstab only seeds the shooting, the Newton
  //     loop converges to the periodic state from there. The HB tolerances
  //     above are too tight for the transient integrator inside pss, which
  //     aborts on them, so the shooting runs at the default tolerances.
  //     Tighter settings change the detected term by less than 1e-4
  //     where they integrate at all and abort at low drive (reltol=1e-4
  //     on the 16-cell variant, 1e-5 on the fabricated one), the
  //     shooting resolves the detected term to better than 1 % down to
  //     10 uV without them. One analysis per point rather
  //     than a sweep, so a point that fails does not take the others with it.
  //     maxacfreq=0: without it pss sizes its time step for a periodic
  //     small-signal follow-up that is never run and aborts on the step size.
  var tper=1/freq_rf
  options reltol=1e-3 abstol=1e-12 vntol=1e-6
  alter instance(\\"vin3\\") ampl=10m
  analysis powdet_pss2a pss driven=1 tper=tper tstab=50*tper maxacfreq=0
  alter instance(\\"vin3\\") ampl=31.62m
  analysis powdet_pss2b pss driven=1 tper=tper tstab=50*tper maxacfreq=0
  alter instance(\\"vin3\\") ampl=100m
  analysis powdet_pss2c pss driven=1 tper=tper tstab=50*tper maxacfreq=0
  alter instance(\\"vin3\\") ampl=316.2m
  analysis powdet_pss2d pss driven=1 tper=tper tstab=50*tper maxacfreq=0
  alter instance(\\"vin3\\") ampl=1.0
  analysis powdet_pss2e pss driven=1 tper=tper tstab=50*tper maxacfreq=0

  postprocess(PYTHON, \\"../plot_simulations/plot_sparx_powdet_sbd_tb_pss_vacask.py\\")
endc
"}
C {sparx_powdet_sbd.sym} 1920 -720 0 0 {name=xdemod1}
C {capa.sym} 2080 -450 0 0 {name=C1
m=1
value=5p}
C {capa.sym} 2180 -450 0 0 {name=C2
m=1
value=5p}
C {title-3.sym} 0 0 0 0 {name=l4 author="Simon Dorrer" rev=1.0 lock=true}
C {devices/launcher.sym} 1620 -1320 0 0 {name=h5
descr="annotate OP" 
tclcommand="set show_hidden_texts 1; xschem annotate_op"
}
C {devices/gnd.sym} 1320 -340 0 0 {name=l1 lab=GND}
C {devices/lab_pin.sym} 1540 -720 0 0 {name=p11 sig_type=std_logic lab=rfin}
C {devices/lab_pin.sym} 2180 -740 0 1 {name=p12 sig_type=std_logic lab=out_cm}
C {spice_probe.sym} 1540 -720 0 0 {name=p14 attrs=""}
C {spice_probe.sym} 2180 -740 0 0 {name=p15 attrs=""}
C {devices/lab_pin.sym} 2080 -700 0 1 {name=p16 sig_type=std_logic lab=ref}
C {spice_probe.sym} 2080 -700 0 0 {name=p17 attrs=""}
C {devices/lab_pin.sym} 1320 -860 0 0 {name=p18 sig_type=std_logic lab=vdd}
C {vcvs.sym} 2360 -560 0 0 {name=E2 value=1}
C {spice_probe.sym} 2360 -650 0 0 {name=p19 attrs=""}
C {devices/lab_pin.sym} 2360 -650 0 1 {name=p20 sig_type=std_logic lab=out}
C {noconn.sym} 2360 -620 0 0 {name=l7}
C {sparx_powdet_sbd_pex.sym} 1920 -980 0 0 {name=xdemod2
spice_ignore=true
spectre_ignore=true}
C {launcher.sym} 1620 -1380 0 0 {name=h2
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
