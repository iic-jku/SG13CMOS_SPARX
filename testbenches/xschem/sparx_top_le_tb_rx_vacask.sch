v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
T {VACASK Testbench for Receiver-Level Simulation - Six-Port with Full-Core LE Model and Four Power Detectors} 400 -1710 0 0 1 1 {}
T {SPDX-FileCopyrightText: 2026 The SPARX Team
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
} 1920 -220 0 0 0.4 0.4 {}
N 940 -980 940 -940 {lab=GND}
N 1180 -1020 1180 -940 {lab=GND}
N 1260 -1020 1260 -940 {lab=GND}
N 1020 -1200 1060 -1200 {lab=GND}
N 1020 -1120 1020 -940 {lab=GND}
N 1020 -1120 1060 -1120 {lab=GND}
N 1020 -1200 1020 -1120 {lab=GND}
N 940 -1160 940 -1130 {lab=vlo}
N 940 -1070 940 -1040 {lab=lo_src}
N 940 -1160 1060 -1160 {lab=vlo}
N 1500 -980 1500 -940 {lab=GND}
N 1500 -1160 1500 -1130 {lab=vrf}
N 1500 -1070 1500 -1040 {lab=rf_src}
N 1380 -1200 1420 -1200 {lab=GND}
N 1420 -1120 1420 -940 {lab=GND}
N 1380 -1120 1420 -1120 {lab=GND}
N 1420 -1200 1420 -1120 {lab=GND}
N 1380 -1160 1500 -1160 {lab=vrf}
N 1700 -980 1700 -940 {lab=GND}
N 1700 -1080 1700 -1040 {lab=VDD}
N 1140 -1020 1140 -980 {lab=vout3}
N 1100 -1020 1100 -1000 {lab=vref3}
N 1300 -1020 1300 -980 {lab=vout4}
N 1340 -1020 1340 -1000 {lab=vref4}
N 1220 -1020 1220 -980 {lab=VDD}
N 1180 -1380 1180 -1300 {lab=GND}
N 1260 -1380 1260 -1300 {lab=GND}
N 1140 -1340 1140 -1300 {lab=vout1}
N 1100 -1320 1100 -1300 {lab=vref1}
N 1300 -1340 1300 -1300 {lab=vout2}
N 1340 -1320 1340 -1300 {lab=vref2}
N 1220 -1340 1220 -1300 {lab=VDD}
N 1920 -1080 1920 -1040 {lab=vout1}
N 1920 -980 1920 -940 {lab=GND}
N 2040 -1080 2040 -1040 {lab=vout2}
N 2040 -980 2040 -940 {lab=GND}
N 2160 -1080 2160 -1040 {lab=vout3}
N 2160 -980 2160 -940 {lab=GND}
N 2280 -1080 2280 -1040 {lab=vout4}
N 2280 -980 2280 -940 {lab=GND}
N 1920 -870 1920 -830 {lab=vref1}
N 1920 -770 1920 -730 {lab=GND}
N 2040 -870 2040 -830 {lab=vref2}
N 2040 -770 2040 -730 {lab=GND}
N 2160 -870 2160 -830 {lab=vref3}
N 2160 -770 2160 -730 {lab=GND}
N 2280 -870 2280 -830 {lab=vref4}
N 2280 -770 2280 -730 {lab=GND}
N 2500 -1170 2500 -1130 {lab=out1}
N 2500 -1070 2500 -1030 {lab=GND}
N 2420 -1120 2460 -1120 {lab=vout1}
N 2420 -1080 2460 -1080 {lab=vref1}
N 2500 -970 2500 -930 {lab=out2}
N 2500 -870 2500 -830 {lab=GND}
N 2420 -920 2460 -920 {lab=vout2}
N 2420 -880 2460 -880 {lab=vref2}
N 2500 -770 2500 -730 {lab=out3}
N 2500 -670 2500 -630 {lab=GND}
N 2420 -720 2460 -720 {lab=vout3}
N 2420 -680 2460 -680 {lab=vref3}
N 2500 -570 2500 -530 {lab=out4}
N 2500 -470 2500 -430 {lab=GND}
N 2420 -520 2460 -520 {lab=vout4}
N 2420 -480 2460 -480 {lab=vref4}
C {simulator_commands_shown.sym} 60 -1530 0 0 {name=Script_VACASK
simulator=vacask
only_toplevel=false
value="
control
  // Receiver-level characterisation: the full-core fit sparx_core_le (order 24
  // vector fit of the Palace 7-port solve, see netlist/spectre) drives the four
  // power detectors inside sparx_top_le. The LO enters core port 1 (BPF, WPD,
  // BLC), the RF port 2 (two BLCs). Both sources sit behind 50 Ohm, so a source
  // amplitude a is an available power a^2 / (8 * 50) at the pad:
  //   +12 dBm = 2.52 V, +3 dBm = 894 mV, -20 dBm = 63.2 mV.
  // +12 dBm at the LO pad puts about -6.5 dBm on each detector, the operating
  // point of the detector benches, behind the 17 to 19 dB of the LO path.
  // vrf carries spur=\{[1]\} smag=[1]: the unit small-signal tone at freq_lo + f
  // that hbac uses as the RF. It has no effect on any other analysis.
  var freq_lo=159G
  var freq_rf=161G
  var ampl_lo=2.52
  var ampl_rf=63.2m

  // Top-level nodes and the four detector inputs only: the receiver has about
  // 1700 unknowns and the 10 ns transient 200000 points.
  options strictsave=1
  save v(out1) v(out2) v(out3) v(out4)
  save v(vout1) v(vout2) v(vout3) v(vout4) v(vref1) v(vref2) v(vref3) v(vref4)
  save v(vlo) v(vrf) v(\\"x1:net1\\") v(\\"x1:net2\\") v(\\"x1:net3\\") v(\\"x1:net4\\")

  analysis op1 op

  // (0) RF alone at -20 dBm: the RF reaching each detector from the HB
  //     spectrum at freq_rf, which is the RF-path loss at circuit level.
  alter instance(\\"vrf\\") ampl=ampl_rf
  analysis rx_hb_rf hb freq=[freq_rf] nharm=5
  alter instance(\\"vrf\\") ampl=0

  // (1) LO at the detector operating point, RF as the hbac spur: the IF
  //     response of the four detectors, and the LO reaching each of them from
  //     the HB spectrum at freq_lo.
  alter instance(\\"vlo\\") ampl=ampl_lo
  analysis rx_hb hb freq=[freq_lo] nharm=9
  analysis rx_hbac_if hbac freq=[freq_lo] nharm=9 outspur=[0] from=1M to=5G mode=\\"dec\\" points=10

  // (2) IF output at 2 GHz against the LO power at the pad, -6 dBm to +15 dBm.
  sweep a_lo instance=\\"vlo\\" parameter=\\"ampl\\" from=0.316 to=3.56 mode=\\"dec\\" points=20
    analysis rx_hbac_lo hbac freq=[freq_lo] nharm=9 outspur=[0] values=[2G]

  // (3) Two-tone HB cross-check at the transient's levels. A cold two-tone
  //     solve does not converge on the detector, so the LO is ramped.
  alter instance(\\"vrf\\") ampl=ampl_rf
  sweep a_lo2 instance=\\"vlo\\" parameter=\\"ampl\\" from=0.63 to=2.52 mode=\\"lin\\" points=4
    analysis rx_hb2 hb freq=[freq_lo, freq_rf] nharm=[5,2] truncate=\\"diamond\\"

  // (4) Transient at the same levels, 10 ns so the detected dc has fully settled, the last nanosecond is plotted.
  alter instance(\\"vlo\\") ampl=ampl_lo
  analysis rx_tran tran stop=10n step=10f maxstep=50f

  postprocess(PYTHON, \\"../plot_simulations/plot_sparx_top_le_tb_rx_vacask.py\\")
endc
"}
C {simulator_commands_shown.sym} 1880 -1530 0 0 {name=Libs_VACASK
simulator=vacask
only_toplevel=false
value="
include \\"sg13g2_vacask_common.lib\\"
include \\"cornerMOSlv.lib\\" section=mos_tt
include \\"cornerRES.lib\\" section=res_typ
include \\"cornerCAP.lib\\" section=cap_typ
include \\"cornerDIO.lib\\" section=dio_tt
// capacitor, resistor, vsource and vcvs models are auto-emitted by the symbols
// of this bench, the fitted core needs the controlled sources on top of them.
model vccs vccs
model cccs cccs
include \\"../../../netlist/spectre/sparx_core_le.inc\\"
"}
C {title-3.sym} 0 0 0 0 {name=l2 author="Simon Dorrer" rev=1.0 lock=true}
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
C {devices/vsource.sym} 940 -1010 0 1 {name=vlo value="type=\\"sine\\" sinedc=0 ampl=0 freq="freq_lo""}
C {devices/res.sym} 940 -1100 0 0 {name=Rlo value=50}
C {devices/lab_pin.sym} 940 -1070 0 0 {name=pl1 sig_type=std_logic lab=lo_src}
C {lab_pin.sym} 1140 -980 0 0 {name=p4 sig_type=std_logic lab=vout3}
C {devices/gnd.sym} 1180 -940 0 1 {name=l5 lab=GND}
C {devices/gnd.sym} 1260 -940 0 0 {name=l7 lab=GND}
C {devices/gnd.sym} 940 -940 0 1 {name=l6 lab=GND}
C {devices/vsource.sym} 1500 -1010 0 0 {name=vrf value="type=\\"sine\\" sinedc=0 ampl=0 freq="freq_rf" spur=\{[1]\} smag=[1]"}
C {devices/res.sym} 1500 -1100 0 0 {name=Rrf value=50}
C {devices/lab_pin.sym} 1500 -1070 0 0 {name=pl2 sig_type=std_logic lab=rf_src}
C {devices/gnd.sym} 1020 -940 0 1 {name=l3 lab=GND}
C {devices/gnd.sym} 1500 -940 0 0 {name=l4 lab=GND}
C {devices/gnd.sym} 1420 -940 0 0 {name=l10 lab=GND}
C {devices/vsource.sym} 1700 -1010 0 0 {name=VDD value="dc=1.5"}
C {devices/gnd.sym} 1700 -940 0 0 {name=l1 lab=GND}
C {capa.sym} 1920 -1010 0 1 {name=C1
m=1
value=5p
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 1920 -940 0 0 {name=l11 lab=GND}
C {vdd.sym} 1700 -1080 0 0 {name=l12 lab=VDD}
C {lab_pin.sym} 940 -1160 0 0 {name=p1 sig_type=std_logic lab=vlo}
C {lab_pin.sym} 1500 -1160 0 1 {name=Vrf1 sig_type=std_logic lab=vrf}
C {lab_pin.sym} 1100 -1000 0 0 {name=p2 sig_type=std_logic lab=vref3}
C {lab_pin.sym} 1300 -980 0 1 {name=p3 sig_type=std_logic lab=vout4}
C {lab_pin.sym} 1340 -1000 0 1 {name=p5 sig_type=std_logic lab=vref4}
C {vdd.sym} 1220 -980 2 0 {name=l14 lab=VDD}
C {lab_pin.sym} 1140 -1340 2 1 {name=p6 sig_type=std_logic lab=vout1}
C {devices/gnd.sym} 1180 -1380 2 0 {name=l8 lab=GND}
C {devices/gnd.sym} 1260 -1380 2 1 {name=l9 lab=GND}
C {lab_pin.sym} 1100 -1320 2 1 {name=p7 sig_type=std_logic lab=vref1}
C {lab_pin.sym} 1300 -1340 2 0 {name=p8 sig_type=std_logic lab=vout2}
C {lab_pin.sym} 1340 -1320 2 0 {name=p9 sig_type=std_logic lab=vref2}
C {vdd.sym} 1220 -1340 0 1 {name=l13 lab=VDD}
C {capa.sym} 2040 -1010 0 1 {name=C2
m=1
value=5p
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 2040 -940 0 0 {name=l15 lab=GND}
C {capa.sym} 2160 -1010 0 1 {name=C3
m=1
value=5p
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 2160 -940 0 0 {name=l16 lab=GND}
C {capa.sym} 2280 -1010 0 1 {name=C4
m=1
value=5p
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 2280 -940 0 0 {name=l17 lab=GND}
C {lab_pin.sym} 1920 -1080 2 1 {name=p10 sig_type=std_logic lab=vout1}
C {lab_pin.sym} 2040 -1080 2 1 {name=p11 sig_type=std_logic lab=vout2}
C {lab_pin.sym} 2160 -1080 0 0 {name=p12 sig_type=std_logic lab=vout3}
C {lab_pin.sym} 2280 -1080 0 0 {name=p13 sig_type=std_logic lab=vout4}
C {capa.sym} 1920 -800 0 1 {name=C5
m=1
value=5p
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 1920 -730 0 0 {name=l18 lab=GND}
C {capa.sym} 2040 -800 0 1 {name=C6
m=1
value=5p
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 2040 -730 0 0 {name=l19 lab=GND}
C {capa.sym} 2160 -800 0 1 {name=C7
m=1
value=5p
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 2160 -730 0 0 {name=l20 lab=GND}
C {capa.sym} 2280 -800 0 1 {name=C8
m=1
value=5p
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 2280 -730 0 0 {name=l21 lab=GND}
C {lab_pin.sym} 1920 -870 2 1 {name=p14 sig_type=std_logic lab=vref1}
C {lab_pin.sym} 2040 -870 2 1 {name=p15 sig_type=std_logic lab=vref2}
C {lab_pin.sym} 2160 -870 0 0 {name=p16 sig_type=std_logic lab=vref3}
C {lab_pin.sym} 2280 -870 0 0 {name=p17 sig_type=std_logic lab=vref4}
C {vcvs.sym} 2500 -1100 0 0 {name=E1 value=1}
C {lab_pin.sym} 2500 -1170 0 1 {name=p18 sig_type=std_logic lab=out1}
C {devices/gnd.sym} 2500 -1030 0 0 {name=l22 lab=GND}
C {lab_pin.sym} 2420 -1120 0 0 {name=p19 sig_type=std_logic lab=vout1}
C {lab_pin.sym} 2420 -1080 0 0 {name=p20 sig_type=std_logic lab=vref1}
C {vcvs.sym} 2500 -900 0 0 {name=E2 value=1}
C {lab_pin.sym} 2500 -970 0 1 {name=p21 sig_type=std_logic lab=out2}
C {devices/gnd.sym} 2500 -830 0 0 {name=l23 lab=GND}
C {lab_pin.sym} 2420 -920 0 0 {name=p22 sig_type=std_logic lab=vout2}
C {lab_pin.sym} 2420 -880 0 0 {name=p23 sig_type=std_logic lab=vref2}
C {vcvs.sym} 2500 -700 0 0 {name=E3 value=1}
C {lab_pin.sym} 2500 -770 0 1 {name=p24 sig_type=std_logic lab=out3}
C {devices/gnd.sym} 2500 -630 0 0 {name=l24 lab=GND}
C {lab_pin.sym} 2420 -720 0 0 {name=p25 sig_type=std_logic lab=vout3}
C {lab_pin.sym} 2420 -680 0 0 {name=p26 sig_type=std_logic lab=vref3}
C {vcvs.sym} 2500 -500 0 0 {name=E4 value=1}
C {lab_pin.sym} 2500 -570 0 1 {name=p27 sig_type=std_logic lab=out4}
C {devices/gnd.sym} 2500 -430 0 0 {name=l25 lab=GND}
C {lab_pin.sym} 2420 -520 0 0 {name=p28 sig_type=std_logic lab=vout4}
C {lab_pin.sym} 2420 -480 0 0 {name=p29 sig_type=std_logic lab=vref4}
C {sparx_top_le.sym} 1220 -1160 0 0 {name=x1}
