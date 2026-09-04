v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
T {VACASK Noise-Figure Testbench for the SBD-Based Power Detector} 330 -1720 0 0 1 1 {}
T {SPDX-FileCopyrightText: 2025-2026 The SPARX Team
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
} 1920 -220 0 0 0.4 0.4 {}
N 1220 -360 1220 -340 {
lab=GND}
N 1440 -440 1440 -360 {lab=GND}
N 1440 -520 1440 -500 {lab=#net1}
N 1440 -720 1440 -660 {lab=rfin}
N 1440 -600 1440 -580 {lab=src}
N 1820 -360 1980 -360 {lab=GND}
N 1820 -860 1820 -780 {lab=vdd}
N 1220 -360 1440 -360 {lab=GND}
N 2080 -580 2220 -580 {lab=out_cm}
N 2260 -530 2260 -360 {lab=GND}
N 2260 -650 2260 -590 {lab=out}
N 1980 -700 1980 -540 {lab=ref}
N 1980 -540 2220 -540 {lab=ref}
N 1220 -440 1220 -360 {lab=GND}
N 1220 -860 1220 -500 {lab=vdd}
N 2080 -360 2260 -360 {lab=GND}
N 2080 -420 2080 -360 {lab=GND}
N 1980 -360 2080 -360 {lab=GND}
N 1980 -420 1980 -360 {lab=GND}
N 1980 -540 1980 -480 {lab=ref}
N 2080 -580 2080 -480 {lab=out_cm}
N 2080 -740 2080 -580 {lab=out_cm}
N 1440 -720 1740 -720 {lab=rfin}
N 1820 -660 1820 -360 {lab=GND}
N 1440 -360 1820 -360 {lab=GND}
N 1220 -860 1820 -860 {lab=vdd}
N 1900 -740 2080 -740 {lab=out_cm}
N 1900 -700 1980 -700 {lab=ref}
C {devices/vsource.sym} 1220 -470 0 0 {name=vdd value="dc=1.5"}
C {devices/res.sym} 1440 -630 0 0 {name=Rs value=50}
C {devices/lab_pin.sym} 1440 -600 0 0 {name=p21 sig_type=std_logic lab=src}
C {devices/vsource.sym} 1440 -550 0 0 {name=vin3 value="type=\\"sine\\" sinedc=0 ampl=0 freq="freq_rf" spur=\{[1]\} smag=[1]"}
C {devices/vsource.sym} 1440 -470 0 0 {name=vin2 value="type=\\"sine\\" sinedc=0 ampl=0 freq="freq_lo""}
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
C {simulator_commands_shown.sym} 80 -1370 0 0 {
name=Script_VACASK
simulator=vacask
only_toplevel=false
value="
control
  // LO at freq_lo, RF one IF away from it. Rs = 50 Ohm at the input, so a
  // source amplitude a is an available power a^2 / (8 * Rs): the 300 mV LO
  // below is -6.5 dBm. vin3 carries spur=\{[1]\} smag=[1], which is the
  // small-signal excitation the hbac analysis uses: a unit tone at
  // freq_lo + f, the upper sideband. It has no effect on any other analysis.
  var freq_lo=159G
  var freq_rf=161G
  var ampl_lo=300m

  // No include of the .save file here: its operating-point parameter saves
  // bind to op and noise but not to hbac, which then writes no rawfile.
  // save full keeps every noise contribution for the contributor ranking.
  save full

  analysis sparx_powdet_sbd_tb_nf_vacask op

  // (1) Output noise density over the video band, the numerator of the noise
  //     figure. It is a baseband quantity, so no RF transfer function is
  //     involved. `save full` writes the per-source contributions the plot
  //     script ranks. VACASK has no pnoise, so this linearises at the DC
  //     operating point: the LO-induced bias shift is not included.
  analysis powdet_nf_noise noise out=\\"out\\" in=\\"vin3\\" from=1k to=5G mode=\\"dec\\" points=20

  // (2) Conversion from the RF port to the output, computed by the periodic
  //     small-signal (hbac) analysis around the single-tone HB operating point
  //     of the LO. One sweep over the offset frequency f gives the response at
  //     the IF f for the upper sideband (spur [1], RF = LO + f), a second one
  //     with the spur flipped gives the lower sideband (RF = LO - f). This
  //     replaced a two-tone HB sweep that cost minutes per IF point: hbac
  //     takes about a second, and it agreed with two-tone HB at 2 GHz to
  //     0.13 dB and with the closed form 2 S'(P_lo)^2 P_lo to 0.13 dB at low
  //     IF and 0.5 dB at 5 GHz when it was introduced.
  //     The LO amplitude is a literal because a sweep cannot follow a
  //     parameter bound to an expression. Keep it equal to ampl_lo.
  alter instance(\\"vin2\\") ampl=300m
  analysis powdet_nf_hbac_usb hbac freq=[freq_lo] nharm=9 outspur=[0] from=1k to=5G mode=\\"dec\\" points=20
  alter instance(\\"vin3\\") spur=\{[-1]\}
  analysis powdet_nf_hbac_lsb hbac freq=[freq_lo] nharm=9 outspur=[0] from=1k to=5G mode=\\"dec\\" points=20
  alter instance(\\"vin3\\") spur=\{[1]\}

  // (3) The same conversion against the LO drive at one IF, for the noise
  //     figure versus LO power.
  sweep a_lo instance=\\"vin2\\" parameter=\\"ampl\\" from=1m to=1.4 mode=\\"dec\\" points=6
    analysis powdet_nf_hbac_lo hbac freq=[freq_lo] nharm=9 outspur=[0] values=[2G]

  postprocess(PYTHON, \\"../plot_simulations/plot_sparx_powdet_sbd_tb_nf_vacask.py\\")
endc
"}
C {sparx_powdet_sbd.sym} 1820 -720 0 0 {name=xdemod1}
C {capa.sym} 1980 -450 0 0 {name=C1
m=1
value=5p}
C {capa.sym} 2080 -450 0 0 {name=C2
m=1
value=5p}
C {title-3.sym} 0 0 0 0 {name=l4 author="Simon Dorrer" rev=1.0 lock=true}
C {devices/launcher.sym} 1620 -1320 0 0 {name=h5
descr="annotate OP" 
tclcommand="set show_hidden_texts 1; xschem annotate_op"
}
C {devices/gnd.sym} 1220 -340 0 0 {name=l1 lab=GND}
C {devices/lab_pin.sym} 1440 -720 0 0 {name=p11 sig_type=std_logic lab=rfin}
C {devices/lab_pin.sym} 2080 -740 0 1 {name=p12 sig_type=std_logic lab=out_cm}
C {spice_probe.sym} 1440 -720 0 0 {name=p14 attrs=""}
C {spice_probe.sym} 2080 -740 0 0 {name=p15 attrs=""}
C {devices/lab_pin.sym} 1980 -700 0 1 {name=p16 sig_type=std_logic lab=ref}
C {spice_probe.sym} 1980 -700 0 0 {name=p17 attrs=""}
C {devices/lab_pin.sym} 1220 -860 0 0 {name=p18 sig_type=std_logic lab=vdd}
C {vcvs.sym} 2260 -560 0 0 {name=E2 value=1}
C {spice_probe.sym} 2260 -650 0 0 {name=p19 attrs=""}
C {devices/lab_pin.sym} 2260 -650 0 1 {name=p20 sig_type=std_logic lab=out}
C {noconn.sym} 2260 -620 0 0 {name=l7}
C {sparx_powdet_sbd_pex.sym} 1820 -980 0 0 {name=xdemod2
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
