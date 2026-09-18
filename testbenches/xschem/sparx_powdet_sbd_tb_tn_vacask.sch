v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
T {VACASK Transient-Noise Testbench for the SBD-Based Power Detector} 370 -1710 0 0 1 1 {}
T {SPDX-FileCopyrightText: 2025-2026 The SPARX Team
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
} 1920 -220 0 0 0.4 0.4 {}
N 1320 -380 1320 -360 {
lab=GND}
N 1540 -460 1540 -380 {lab=GND}
N 1540 -540 1540 -520 {lab=#net1}
N 1540 -740 1540 -680 {lab=rfin}
N 1540 -620 1540 -600 {lab=src}
N 1920 -380 2080 -380 {lab=GND}
N 1920 -880 1920 -800 {lab=vdd}
N 1320 -380 1540 -380 {lab=GND}
N 2180 -600 2320 -600 {lab=out_cm}
N 2360 -550 2360 -380 {lab=GND}
N 2360 -670 2360 -610 {lab=out}
N 2080 -720 2080 -560 {lab=ref}
N 2080 -560 2320 -560 {lab=ref}
N 1320 -460 1320 -380 {lab=GND}
N 1320 -880 1320 -520 {lab=vdd}
N 2180 -380 2360 -380 {lab=GND}
N 2180 -440 2180 -380 {lab=GND}
N 2080 -380 2180 -380 {lab=GND}
N 2080 -440 2080 -380 {lab=GND}
N 2080 -560 2080 -500 {lab=ref}
N 2180 -600 2180 -500 {lab=out_cm}
N 2180 -760 2180 -600 {lab=out_cm}
N 1540 -740 1840 -740 {lab=rfin}
N 1920 -680 1920 -380 {lab=GND}
N 1540 -380 1920 -380 {lab=GND}
N 1320 -880 1920 -880 {lab=vdd}
N 2000 -760 2180 -760 {lab=out_cm}
N 2000 -720 2080 -720 {lab=ref}
C {devices/vsource.sym} 1320 -490 0 0 {name=vdd value="dc=1.5"}
C {devices/res.sym} 1540 -650 0 0 {name=Rs value=50}
C {devices/lab_pin.sym} 1540 -620 0 0 {name=p21 sig_type=std_logic lab=src}
C {devices/vsource.sym} 1540 -570 0 0 {name=vin3 value="type=\\"sine\\" sinedc=0 ampl=ampl_rf freq="freq_rf""}
C {devices/vsource.sym} 1540 -490 0 0 {name=vin2 value="type=\\"sine\\" sinedc=0 ampl=ampl_lo freq="freq_lo""}
C {simulator_commands_shown.sym} 1900 -1350 0 0 {
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
C {simulator_commands_shown.sym} 80 -1070 0 0 {
name=Script_VACASK
simulator=vacask
only_toplevel=false
value="
control
  // LO-pumped transient noise, three runs that differ only in noisescale.
  // The plot script splits the output PSD into a term linear in noisescale^2,
  // which must reproduce hbnoise from the NF bench, and whatever is left.
  //
  // Four settings are not optional, each found by bisecting an aborting run:
  //  1. noisemode=\\"sde\\". The default \\"zoh\\" aborts with \\"Timestep too small\\"
  //     on any PSP103 device.
  //  2. rsw on every sp_diode model card. Without it the sidewall flicker
  //     exponent is never assigned, stays 0, and VACASK rejects it. jsw is 0,
  //     so the sidewall branch carries no current and nothing else changes.
  //  3. tran_noiselte far above its default of 1, or the noise drives the
  //     timestep down until the run aborts. The result does not depend on the
  //     value where both run.
  //  4. No noise analysis in this deck. It aborts the transient in either
  //     order. The references live in the NF bench.
  //
  // maxstep resolves the 159 GHz LO. With ampl_lo=0 the ladder runs unpumped
  // and the plot script checks it against the quiescent noise analysis instead,
  // which is the configuration this bench had before hbnoise existed.
  var freq_lo=159G
  var freq_rf=161G
  var ampl_rf=0
  var ampl_lo=300m
  save v(\\"out\\")
  options strictsave=1
  options tran_noiselte=1e6

  analysis sparx_powdet_sbd_tb_tn_vacask op

  alter model(\\"dmain_mod\\") rsw=1e-3
  alter model(\\"drev_mod\\") rsw=1e-3
  alter model(\\"dsub_mod\\") rsw=1e-3

  // One analysis per noisescale rather than a sweep: an aborting run writes no
  // rawfile, and one failing rung of a sweep would cost the others too. The
  // plot script reads the noisescale values back out of this netlist.
  // The ladder stays at or below 0.1. At 1.0 the output is 15 times above
  // hbnoise with an excess that grows faster than second order in noisescale,
  // the same artefact the unpumped ladder showed, and the split then fails.
  analysis powdet_tn1 tran stop=100n step=0.1p maxstep=0.15p noisefmax=20G noisefmin=10M oversample=3 noiseseed=1 noisemode=\\"sde\\" noisescale=0.01
  analysis powdet_tn2 tran stop=100n step=0.1p maxstep=0.15p noisefmax=20G noisefmin=10M oversample=3 noiseseed=1 noisemode=\\"sde\\" noisescale=0.0316227766
  analysis powdet_tn3 tran stop=100n step=0.1p maxstep=0.15p noisefmax=20G noisefmin=10M oversample=3 noiseseed=1 noisemode=\\"sde\\" noisescale=0.1

  postprocess(PYTHON, \\"../plot_simulations/plot_sparx_powdet_sbd_tb_tn_vacask.py\\")
endc
"}
C {sparx_powdet_sbd.sym} 1920 -740 0 0 {name=xdemod1}
C {capa.sym} 2080 -470 0 0 {name=C1
m=1
value=5p}
C {capa.sym} 2180 -470 0 0 {name=C2
m=1
value=5p}
C {title-3.sym} 0 0 0 0 {name=l4 author="Simon Dorrer" rev=1.0 lock=true}
C {devices/launcher.sym} 1640 -1300 0 0 {name=h5
descr="annotate OP" 
tclcommand="set show_hidden_texts 1; xschem annotate_op"
}
C {devices/gnd.sym} 1320 -360 0 0 {name=l1 lab=GND}
C {devices/lab_pin.sym} 1540 -740 0 0 {name=p11 sig_type=std_logic lab=rfin}
C {devices/lab_pin.sym} 2180 -760 0 1 {name=p12 sig_type=std_logic lab=out_cm}
C {spice_probe.sym} 1540 -740 0 0 {name=p14 attrs=""}
C {spice_probe.sym} 2180 -760 0 0 {name=p15 attrs=""}
C {devices/lab_pin.sym} 2080 -720 0 1 {name=p16 sig_type=std_logic lab=ref}
C {spice_probe.sym} 2080 -720 0 0 {name=p17 attrs=""}
C {devices/lab_pin.sym} 1320 -880 0 0 {name=p18 sig_type=std_logic lab=vdd}
C {vcvs.sym} 2360 -580 0 0 {name=E2 value=1}
C {spice_probe.sym} 2360 -670 0 0 {name=p19 attrs=""}
C {devices/lab_pin.sym} 2360 -670 0 1 {name=p20 sig_type=std_logic lab=out}
C {noconn.sym} 2360 -640 0 0 {name=l7}
C {sparx_powdet_sbd_pex.sym} 1920 -1000 0 0 {name=xdemod2
spice_ignore=true
spectre_ignore=true}
C {launcher.sym} 1640 -1360 0 0 {name=h2
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
