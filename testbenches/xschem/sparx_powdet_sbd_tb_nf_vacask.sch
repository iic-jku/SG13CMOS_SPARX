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
N 1340 -360 1340 -340 {
lab=GND}
N 1560 -440 1560 -360 {lab=GND}
N 1560 -520 1560 -500 {lab=#net1}
N 1560 -720 1560 -660 {lab=rfin}
N 1560 -600 1560 -580 {lab=src}
N 1940 -360 2100 -360 {lab=GND}
N 1940 -860 1940 -780 {lab=vdd}
N 1340 -360 1560 -360 {lab=GND}
N 2200 -580 2340 -580 {lab=out_cm}
N 2380 -530 2380 -360 {lab=GND}
N 2380 -650 2380 -590 {lab=out}
N 2100 -700 2100 -540 {lab=ref}
N 2100 -540 2340 -540 {lab=ref}
N 1340 -440 1340 -360 {lab=GND}
N 1340 -860 1340 -500 {lab=vdd}
N 2200 -360 2380 -360 {lab=GND}
N 2200 -420 2200 -360 {lab=GND}
N 2100 -360 2200 -360 {lab=GND}
N 2100 -420 2100 -360 {lab=GND}
N 2100 -540 2100 -480 {lab=ref}
N 2200 -580 2200 -480 {lab=out_cm}
N 2200 -740 2200 -580 {lab=out_cm}
N 1560 -720 1860 -720 {lab=rfin}
N 1940 -660 1940 -360 {lab=GND}
N 1560 -360 1940 -360 {lab=GND}
N 1340 -860 1940 -860 {lab=vdd}
N 2020 -740 2200 -740 {lab=out_cm}
N 2020 -700 2100 -700 {lab=ref}
C {devices/vsource.sym} 1340 -470 0 0 {name=vdd value="dc=1.5"}
C {devices/res.sym} 1560 -630 0 0 {name=Rs value=50}
C {devices/lab_pin.sym} 1560 -600 0 0 {name=p21 sig_type=std_logic lab=src}
C {devices/vsource.sym} 1560 -550 0 0 {name=vin3 value="type=\\"sine\\" sinedc=0 ampl=0 freq="freq_rf" spur=\{[1]\} smag=[1]"}
C {devices/vsource.sym} 1560 -470 0 0 {name=vin2 value="type=\\"sine\\" sinedc=0 ampl=0 freq="freq_lo""}
C {simulator_commands_shown.sym} 2000 -1370 0 0 {
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
  // LO at freq_lo, RF one IF away from it. Rs = 50 Ohm, so a source amplitude
  // a is an available power a^2 / (8 Rs): 300 mV is -6.5 dBm. vin3 carries
  // spur=\{[1]\} smag=[1], the unit upper-sideband tone the hbac analyses use.
  var freq_lo=159G
  var freq_rf=161G
  var ampl_lo=300m

  // No include of the .save file: its operating-point saves bind to op and
  // noise but not to hbac or hbnoise, which then write no rawfile.
  // save full keeps every noise contribution for the contributor ranking.
  save full

  analysis sparx_powdet_sbd_tb_nf_vacask op

  // (1) Output noise at the quiescent operating point, LO off. This is the
  //     detector's own floor, which NEP and MDS are built on. The noise figure
  //     rested on it before hbnoise existed, and the plot script keeps that
  //     estimate next to the pumped result.
  analysis powdet_nf_noise noise out=\\"out\\" in=\\"vin3\\" from=1k to=5G mode=\\"dec\\" points=20

  // (2) Conversion of each sideband to the IF from hbac around the single-tone
  //     HB solution of the LO. spur [1] is RF = LO + f, [-1] is RF = LO - f.
  //     The LO amplitude is a literal because a sweep cannot follow a parameter
  //     bound to an expression. Keep it equal to ampl_lo.
  alter instance(\\"vin2\\") ampl=300m
  analysis powdet_nf_hbac_usb hbac freq=[freq_lo] nharm=9 outspur=[0] from=1k to=5G mode=\\"dec\\" points=20
  alter instance(\\"vin3\\") spur=\{[-1]\}
  analysis powdet_nf_hbac_lsb hbac freq=[freq_lo] nharm=9 outspur=[0] from=1k to=5G mode=\\"dec\\" points=20
  alter instance(\\"vin3\\") spur=\{[1]\}

  // (3) Output noise with the LO on, from hbnoise around the same HB solution:
  //     every source is modulated by the pumped operating point and folded from
  //     all 19 spurs to the IF. This is the numerator of the noise figure.
  //     gain is |V_out(IF) / V_in|^2 for a unit tone at inspur, the transfer
  //     hbac computes, and the plot script checks the two against each other.
  //     The second run only moves inspur to the lower sideband, its onoise is
  //     the same.
  analysis powdet_nf_hbnoise_usb hbnoise freq=[freq_lo] nharm=9 in=\\"vin3\\" inspur=[1] outspur=[0] out=\\"out\\" from=1k to=5G mode=\\"dec\\" points=20
  analysis powdet_nf_hbnoise_lsb hbnoise freq=[freq_lo] nharm=9 in=\\"vin3\\" inspur=[-1] outspur=[0] out=\\"out\\" from=1k to=5G mode=\\"dec\\" points=20

  // (4) Conversion and pumped noise at one IF against the LO drive, for the
  //     noise figure versus LO power. A sweep body holds one analysis, so the
  //     same sweep is written twice. nharm=15 because nine harmonics are not
  //     converged above P(1 dB): at +4 dBm they overstate the conversion of the
  //     fabricated detector by 8.4 dB against pac and against 25 harmonics. At
  //     the -6.5 dBm of (2) and (3), 9 and 25 harmonics agree within 0.15 dB.
  sweep a_lo instance=\\"vin2\\" parameter=\\"ampl\\" from=1m to=1.4 mode=\\"dec\\" points=6
    analysis powdet_nf_hbac_lo hbac freq=[freq_lo] nharm=15 outspur=[0] values=[2G]
  sweep a_lo_n instance=\\"vin2\\" parameter=\\"ampl\\" from=1m to=1.4 mode=\\"dec\\" points=6
    analysis powdet_nf_hbnoise_lo hbnoise freq=[freq_lo] nharm=15 in=\\"vin3\\" inspur=[1] outspur=[0] out=\\"out\\" values=[2G]

  // (5) The same conversion and pumped noise around the periodic steady state
  //     of the LO found by shooting, which shares no code with HB: pac is the
  //     twin of hbac, pnoise of hbnoise. The PSS is solved once and stored, the
  //     other three analyses linearise at it (psssolve=0). truncharm=9 is
  //     converged, 40 moves the result by less than 0.005 dB. pac takes the spur of the
  //     RF source as a signed harmonic number, hbac as a tone-weight vector.
  var tper_lo=1/freq_lo
  alter instance(\\"vin3\\") spur=\{1\}
  analysis powdet_nf_pac_usb pac tper=tper_lo tstab=50*tper_lo maxharm=9 truncharm=9 outharm=0 store=\\"pss_lo\\" from=1k to=5G mode=\\"dec\\" points=20
  alter instance(\\"vin3\\") spur=\{-1\}
  analysis powdet_nf_pac_lsb pac psssolve=0 ic=\\"pss_lo\\" truncharm=9 outharm=0 from=1k to=5G mode=\\"dec\\" points=20
  alter instance(\\"vin3\\") spur=\{[1]\}
  analysis powdet_nf_pnoise_usb pnoise psssolve=0 ic=\\"pss_lo\\" truncharm=9 in=\\"vin3\\" inharm=1 outharm=0 out=\\"out\\" from=1k to=5G mode=\\"dec\\" points=20
  analysis powdet_nf_pnoise_lsb pnoise psssolve=0 ic=\\"pss_lo\\" truncharm=9 in=\\"vin3\\" inharm=-1 outharm=0 out=\\"out\\" from=1k to=5G mode=\\"dec\\" points=20

  // (6) pnoise against the LO drive, the twin of (4). Its gain is the pac
  //     conversion, so the one sweep gives the noise figure.
  sweep a_lo_p instance=\\"vin2\\" parameter=\\"ampl\\" from=1m to=1.4 mode=\\"dec\\" points=6
    analysis powdet_nf_pnoise_lo pnoise tper=tper_lo tstab=50*tper_lo maxharm=9 truncharm=9 in=\\"vin3\\" inharm=1 outharm=0 out=\\"out\\" values=[2G]

  postprocess(PYTHON, \\"../plot_simulations/plot_sparx_powdet_sbd_tb_nf_vacask.py\\")
endc
"}
C {sparx_powdet_sbd.sym} 1940 -720 0 0 {name=xdemod1}
C {capa.sym} 2100 -450 0 0 {name=C1
m=1
value=5p}
C {capa.sym} 2200 -450 0 0 {name=C2
m=1
value=5p}
C {title-3.sym} 0 0 0 0 {name=l4 author="Simon Dorrer" rev=1.0 lock=true}
C {devices/launcher.sym} 1740 -1320 0 0 {name=h5
descr="annotate OP" 
tclcommand="set show_hidden_texts 1; xschem annotate_op"
}
C {devices/gnd.sym} 1340 -340 0 0 {name=l1 lab=GND}
C {devices/lab_pin.sym} 1560 -720 0 0 {name=p11 sig_type=std_logic lab=rfin}
C {devices/lab_pin.sym} 2200 -740 0 1 {name=p12 sig_type=std_logic lab=out_cm}
C {spice_probe.sym} 1560 -720 0 0 {name=p14 attrs=""}
C {spice_probe.sym} 2200 -740 0 0 {name=p15 attrs=""}
C {devices/lab_pin.sym} 2100 -700 0 1 {name=p16 sig_type=std_logic lab=ref}
C {spice_probe.sym} 2100 -700 0 0 {name=p17 attrs=""}
C {devices/lab_pin.sym} 1340 -860 0 0 {name=p18 sig_type=std_logic lab=vdd}
C {vcvs.sym} 2380 -560 0 0 {name=E2 value=1}
C {spice_probe.sym} 2380 -650 0 0 {name=p19 attrs=""}
C {devices/lab_pin.sym} 2380 -650 0 1 {name=p20 sig_type=std_logic lab=out}
C {noconn.sym} 2380 -620 0 0 {name=l7}
C {sparx_powdet_sbd_pex.sym} 1940 -980 0 0 {name=xdemod2
spice_ignore=true
spectre_ignore=true}
C {launcher.sym} 1740 -1380 0 0 {name=h2
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
