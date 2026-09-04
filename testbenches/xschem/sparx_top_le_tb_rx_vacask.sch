v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
T {VACASK Testbench for Receiver Simulation - Six-Port with Full-Core LE Model and Four PDs} 60 -1720 0 0 1 1 {}
T {SPDX-FileCopyrightText: 2026 The SPARX Team
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
} 1920 -220 0 0 0.4 0.4 {}
N 1540 -760 1540 -720 {lab=GND}
N 1780 -800 1780 -720 {lab=GND}
N 1860 -800 1860 -720 {lab=GND}
N 1620 -980 1660 -980 {lab=GND}
N 1620 -900 1620 -720 {lab=GND}
N 1620 -900 1660 -900 {lab=GND}
N 1620 -980 1620 -900 {lab=GND}
N 1540 -940 1540 -910 {lab=vlo}
N 1540 -850 1540 -820 {lab=lo_src}
N 1540 -940 1660 -940 {lab=vlo}
N 2100 -760 2100 -720 {lab=GND}
N 2100 -940 2100 -910 {lab=vrf}
N 2100 -850 2100 -820 {lab=rf_src}
N 1980 -980 2020 -980 {lab=GND}
N 2020 -900 2020 -720 {lab=GND}
N 1980 -900 2020 -900 {lab=GND}
N 2020 -980 2020 -900 {lab=GND}
N 1980 -940 2100 -940 {lab=vrf}
N 1340 -1020 1340 -980 {lab=GND}
N 1340 -1120 1340 -1080 {lab=VDD}
N 1740 -800 1740 -760 {lab=vout3}
N 1700 -800 1700 -780 {lab=vref3}
N 1900 -800 1900 -760 {lab=vout4}
N 1940 -800 1940 -780 {lab=vref4}
N 1820 -800 1820 -760 {lab=VDD}
N 1780 -1160 1780 -1080 {lab=GND}
N 1860 -1160 1860 -1080 {lab=GND}
N 1740 -1120 1740 -1080 {lab=vout1}
N 1700 -1100 1700 -1080 {lab=vref1}
N 1900 -1120 1900 -1080 {lab=vout2}
N 1940 -1100 1940 -1080 {lab=vref2}
N 1820 -1120 1820 -1080 {lab=VDD}
N 1860 -620 1860 -580 {lab=vout1}
N 1860 -520 1860 -480 {lab=GND}
N 1980 -620 1980 -580 {lab=vout2}
N 1980 -520 1980 -480 {lab=GND}
N 2100 -620 2100 -580 {lab=vout3}
N 2100 -520 2100 -480 {lab=GND}
N 2220 -620 2220 -580 {lab=vout4}
N 2220 -520 2220 -480 {lab=GND}
N 1860 -420 1860 -380 {lab=vref1}
N 1860 -320 1860 -280 {lab=GND}
N 1980 -420 1980 -380 {lab=vref2}
N 1980 -320 1980 -280 {lab=GND}
N 2100 -420 2100 -380 {lab=vref3}
N 2100 -320 2100 -280 {lab=GND}
N 2220 -420 2220 -380 {lab=vref4}
N 2220 -320 2220 -280 {lab=GND}
N 1360 -620 1360 -580 {lab=out1}
N 1360 -520 1360 -480 {lab=GND}
N 1280 -570 1320 -570 {lab=vout1}
N 1280 -530 1320 -530 {lab=vref1}
N 1360 -420 1360 -380 {lab=out2}
N 1360 -320 1360 -280 {lab=GND}
N 1280 -370 1320 -370 {lab=vout2}
N 1280 -330 1320 -330 {lab=vref2}
N 1620 -620 1620 -580 {lab=out3}
N 1620 -520 1620 -480 {lab=GND}
N 1540 -570 1580 -570 {lab=vout3}
N 1540 -530 1580 -530 {lab=vref3}
N 1620 -420 1620 -380 {lab=out4}
N 1620 -320 1620 -280 {lab=GND}
N 1540 -370 1580 -370 {lab=vout4}
N 1540 -330 1580 -330 {lab=vref4}
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
C {simulator_commands_shown.sym} 1620 -1450 0 0 {name=Libs_VACASK
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
C {launcher.sym} 1680 -1560 0 0 {name=h2
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
C {devices/vsource.sym} 1540 -790 0 1 {name=vlo value="type=\\"sine\\" sinedc=0 ampl=0 freq="freq_lo""}
C {devices/res.sym} 1540 -880 0 0 {name=Rlo value=50}
C {devices/lab_pin.sym} 1540 -850 0 0 {name=pl1 sig_type=std_logic lab=lo_src}
C {lab_pin.sym} 1740 -760 0 0 {name=p4 sig_type=std_logic lab=vout3}
C {devices/gnd.sym} 1780 -720 0 1 {name=l5 lab=GND}
C {devices/gnd.sym} 1860 -720 0 0 {name=l7 lab=GND}
C {devices/gnd.sym} 1540 -720 0 1 {name=l6 lab=GND}
C {devices/vsource.sym} 2100 -790 0 0 {name=vrf value="type=\\"sine\\" sinedc=0 ampl=0 freq="freq_rf" spur=\{[1]\} smag=[1]"}
C {devices/res.sym} 2100 -880 0 0 {name=Rrf value=50}
C {devices/lab_pin.sym} 2100 -850 0 0 {name=pl2 sig_type=std_logic lab=rf_src}
C {devices/gnd.sym} 1620 -720 0 1 {name=l3 lab=GND}
C {devices/gnd.sym} 2100 -720 0 0 {name=l4 lab=GND}
C {devices/gnd.sym} 2020 -720 0 0 {name=l10 lab=GND}
C {devices/vsource.sym} 1340 -1050 0 0 {name=VDD value="dc=1.5"}
C {devices/gnd.sym} 1340 -980 0 0 {name=l1 lab=GND}
C {capa.sym} 1860 -550 0 1 {name=C1
m=1
value=5p
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 1860 -480 0 0 {name=l11 lab=GND}
C {vdd.sym} 1340 -1120 0 0 {name=l12 lab=VDD}
C {lab_pin.sym} 1540 -940 0 0 {name=p1 sig_type=std_logic lab=vlo}
C {lab_pin.sym} 2100 -940 0 1 {name=Vrf1 sig_type=std_logic lab=vrf}
C {lab_pin.sym} 1700 -780 0 0 {name=p2 sig_type=std_logic lab=vref3}
C {lab_pin.sym} 1900 -760 0 1 {name=p3 sig_type=std_logic lab=vout4}
C {lab_pin.sym} 1940 -780 0 1 {name=p5 sig_type=std_logic lab=vref4}
C {vdd.sym} 1820 -760 2 0 {name=l14 lab=VDD}
C {lab_pin.sym} 1740 -1120 2 1 {name=p6 sig_type=std_logic lab=vout1}
C {devices/gnd.sym} 1780 -1160 2 0 {name=l8 lab=GND}
C {devices/gnd.sym} 1860 -1160 2 1 {name=l9 lab=GND}
C {lab_pin.sym} 1700 -1100 2 1 {name=p7 sig_type=std_logic lab=vref1}
C {lab_pin.sym} 1900 -1120 2 0 {name=p8 sig_type=std_logic lab=vout2}
C {lab_pin.sym} 1940 -1100 2 0 {name=p9 sig_type=std_logic lab=vref2}
C {vdd.sym} 1820 -1120 0 1 {name=l13 lab=VDD}
C {capa.sym} 1980 -550 0 1 {name=C2
m=1
value=5p
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 1980 -480 0 0 {name=l15 lab=GND}
C {capa.sym} 2100 -550 0 1 {name=C3
m=1
value=5p
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 2100 -480 0 0 {name=l16 lab=GND}
C {capa.sym} 2220 -550 0 1 {name=C4
m=1
value=5p
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 2220 -480 0 0 {name=l17 lab=GND}
C {lab_pin.sym} 1860 -620 2 1 {name=p10 sig_type=std_logic lab=vout1}
C {lab_pin.sym} 1980 -620 2 1 {name=p11 sig_type=std_logic lab=vout2}
C {lab_pin.sym} 2100 -620 0 0 {name=p12 sig_type=std_logic lab=vout3}
C {lab_pin.sym} 2220 -620 0 0 {name=p13 sig_type=std_logic lab=vout4}
C {capa.sym} 1860 -350 0 1 {name=C5
m=1
value=5p
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 1860 -280 0 0 {name=l18 lab=GND}
C {capa.sym} 1980 -350 0 1 {name=C6
m=1
value=5p
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 1980 -280 0 0 {name=l19 lab=GND}
C {capa.sym} 2100 -350 0 1 {name=C7
m=1
value=5p
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 2100 -280 0 0 {name=l20 lab=GND}
C {capa.sym} 2220 -350 0 1 {name=C8
m=1
value=5p
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 2220 -280 0 0 {name=l21 lab=GND}
C {lab_pin.sym} 1860 -420 2 1 {name=p14 sig_type=std_logic lab=vref1}
C {lab_pin.sym} 1980 -420 2 1 {name=p15 sig_type=std_logic lab=vref2}
C {lab_pin.sym} 2100 -420 0 0 {name=p16 sig_type=std_logic lab=vref3}
C {lab_pin.sym} 2220 -420 0 0 {name=p17 sig_type=std_logic lab=vref4}
C {vcvs.sym} 1360 -550 0 0 {name=E1 value=1}
C {lab_pin.sym} 1360 -620 0 1 {name=p18 sig_type=std_logic lab=out1}
C {devices/gnd.sym} 1360 -480 0 0 {name=l22 lab=GND}
C {lab_pin.sym} 1280 -570 0 0 {name=p19 sig_type=std_logic lab=vout1}
C {lab_pin.sym} 1280 -530 0 0 {name=p20 sig_type=std_logic lab=vref1}
C {vcvs.sym} 1360 -350 0 0 {name=E2 value=1}
C {lab_pin.sym} 1360 -420 0 1 {name=p21 sig_type=std_logic lab=out2}
C {devices/gnd.sym} 1360 -280 0 0 {name=l23 lab=GND}
C {lab_pin.sym} 1280 -370 0 0 {name=p22 sig_type=std_logic lab=vout2}
C {lab_pin.sym} 1280 -330 0 0 {name=p23 sig_type=std_logic lab=vref2}
C {vcvs.sym} 1620 -550 0 0 {name=E3 value=1}
C {lab_pin.sym} 1620 -620 0 1 {name=p24 sig_type=std_logic lab=out3}
C {devices/gnd.sym} 1620 -480 0 0 {name=l24 lab=GND}
C {lab_pin.sym} 1540 -570 0 0 {name=p25 sig_type=std_logic lab=vout3}
C {lab_pin.sym} 1540 -530 0 0 {name=p26 sig_type=std_logic lab=vref3}
C {vcvs.sym} 1620 -350 0 0 {name=E4 value=1}
C {lab_pin.sym} 1620 -420 0 1 {name=p27 sig_type=std_logic lab=out4}
C {devices/gnd.sym} 1620 -280 0 0 {name=l25 lab=GND}
C {lab_pin.sym} 1540 -370 0 0 {name=p28 sig_type=std_logic lab=vout4}
C {lab_pin.sym} 1540 -330 0 0 {name=p29 sig_type=std_logic lab=vref4}
C {sparx_top_le.sym} 1820 -940 0 0 {name=x1}
