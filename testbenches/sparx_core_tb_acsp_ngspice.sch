v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
B 2 880 -1400 1680 -1000 {flags=graph
y1=-27
y2=-0.18
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=1.5289113e+11
x2=1.7007099e+11
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="\\"|S11|; s_1_1 db20()\\"
\\"|S22|; s_2_2 db20()\\"
\\"|S33|; s_3_3 db20()\\"
\\"|S44|; s_4_4 db20()\\"
\\"|S55|; s_5_5 db20()\\"
\\"|S66|; s_6_6 db20()\\"
\\"|S77|; s_7_7 db20()\\""
color="4 7 12 21 9 10 17"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
B 2 880 -980 1680 -580 {flags=graph
y1=-520
y2=220
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=1.5289113e+11
x2=1.7007099e+11
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="\\"arg(S11); ph(S_1_1) cph()\\"
\\"arg(S22); ph(S_2_2) cph()\\"
\\"arg(S33); ph(S_3_3) cph()\\"
\\"arg(S44); ph(S_4_4) cph()\\"
\\"arg(S55); ph(S_5_5) cph()\\"
\\"arg(S66); ph(S_6_6) cph()\\"
\\"arg(S77); ph(S_7_7) cph()\\""
color="4 7 12 21 9 10 17"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
B 2 1740 -1400 2540 -1000 {flags=graph
y1=0.0022
y2=7.1
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=1.5289113e+11
x2=1.7007099e+11
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="\\"|S41|-|S31|; re(s41_31_dB)\\"
\\"|S51|-|S61|; re(s51_61_dB)\\"
\\"|S32|-|S42|; re(s32_42_dB)\\"
\\"|S62|-|S52|; re(s62_52_dB)\\""
color="4 7 12 21"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
B 2 1740 -980 2540 -580 {flags=graph
y1=-160
y2=-25
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=1.5289113e+11
x2=1.7007099e+11
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="\\"arg(S41)-arg(S31); re(s41_31_deg)\\"
\\"arg(S51)-arg(S61); re(s51_61_deg)\\"
\\"arg(S32)-arg(S42); re(s32_42_deg)\\"
\\"arg(S62)-arg(S52); re(s62_52_deg)\\""
color="4 7 12 21"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
T {Ngspice Testbench for AC S-parameter analysis - Six-Port Core} 830 -2380 0 0 1 1 {}
T {SPDX-FileCopyrightText: 2025-2026 The SPARX Team
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
} 2840 -220 0 0 0.4 0.4 {}
N 1920 -1780 1920 -1680 {lab=v7}
N 1920 -1620 1920 -1580 {lab=GND}
N 1920 -1780 1960 -1780 {lab=v7}
N 2120 -1620 2120 -1580 {lab=GND}
N 2120 -1860 2160 -1860 {lab=v2}
N 2120 -1860 2120 -1680 {lab=v2}
N 1620 -1720 1620 -1680 {lab=v6}
N 1620 -1620 1620 -1580 {lab=GND}
N 1700 -1720 1700 -1680 {lab=v5}
N 1700 -1620 1700 -1580 {lab=GND}
N 1780 -1780 1920 -1780 {lab=v7}
N 1780 -1860 2120 -1860 {lab=v2}
N 1400 -1620 1400 -1580 {lab=GND}
N 1400 -1820 1540 -1820 {lab=v1}
N 1400 -1820 1400 -1680 {lab=v1}
N 1360 -1820 1400 -1820 {lab=v1}
N 1700 -1960 1700 -1920 {lab=v4}
N 1700 -2060 1700 -2020 {lab=GND}
N 1620 -1960 1620 -1920 {lab=v3}
N 1620 -2060 1620 -2020 {lab=GND}
C {devices/code.sym} 110 -2060 0 0 {name=NGSPICE
only_toplevel=true
lock=false
value="
.include ../../netlist/spice/sparx_bpf_le.spice
.include ../../netlist/spice/sparx_wpd_le.spice
.include ../../netlist/spice/sparx_blc_le.spice
.include ../sim_range.spice
.param temp=27
.options savecurrents klu method=gear reltol=1e-3 abstol=1e-15 gmin=1e-15
.control

save all

set wr_vecnames
set wr_singlescale

* User Constants
* f_min / f_max come from ../sim_range.spice (.csparam),
* auto-synced to the loaded Touchstone by snp2le.
* edit that file for a standalone run.

* Operating Point Analysis
op
remzerovec
write @schname\\\\.raw
set appendwrite

* AC S-Parameter Analysis
sp lin 1001 $&const.f_min $&const.f_max
remzerovec

* Calculating S-Parameters
let s11_dB = db(S_1_1)
let s12_dB = db(S_1_2)
let s13_dB = db(S_1_3)
let s14_dB = db(S_1_4)
let s15_dB = db(S_1_5)
let s16_dB = db(S_1_6)
let s17_dB = db(S_1_7)
let s21_dB = db(S_2_1)
let s22_dB = db(S_2_2)
let s23_dB = db(S_2_3)
let s24_dB = db(S_2_4)
let s25_dB = db(S_2_5)
let s26_dB = db(S_2_6)
let s27_dB = db(S_2_7)
let s31_dB = db(S_3_1)
let s32_dB = db(S_3_2)
let s33_dB = db(S_3_3)
let s34_dB = db(S_3_4)
let s35_dB = db(S_3_5)
let s36_dB = db(S_3_6)
let s37_dB = db(S_3_7)
let s41_dB = db(S_4_1)
let s42_dB = db(S_4_2)
let s43_dB = db(S_4_3)
let s44_dB = db(S_4_4)
let s45_dB = db(S_4_5)
let s46_dB = db(S_4_6)
let s47_dB = db(S_4_7)
let s51_dB = db(S_5_1)
let s52_dB = db(S_5_2)
let s53_dB = db(S_5_3)
let s54_dB = db(S_5_4)
let s55_dB = db(S_5_5)
let s56_dB = db(S_5_6)
let s57_dB = db(S_5_7)
let s61_dB = db(S_6_1)
let s62_dB = db(S_6_2)
let s63_dB = db(S_6_3)
let s64_dB = db(S_6_4)
let s65_dB = db(S_6_5)
let s66_dB = db(S_6_6)
let s67_dB = db(S_6_7)
let s71_dB = db(S_7_1)
let s72_dB = db(S_7_2)
let s73_dB = db(S_7_3)
let s74_dB = db(S_7_4)
let s75_dB = db(S_7_5)
let s76_dB = db(S_7_6)
let s77_dB = db(S_7_7)
let s41_31_dB = s41_dB - s31_dB
let s51_61_dB = s51_dB - s61_dB
let s32_42_dB = s32_dB - s42_dB
let s62_52_dB = s62_dB - s52_dB

let s11_deg = cph(S_1_1) * 180/pi
let s12_deg = cph(S_1_2) * 180/pi
let s13_deg = cph(S_1_3) * 180/pi
let s14_deg = cph(S_1_4) * 180/pi
let s15_deg = cph(S_1_5) * 180/pi
let s16_deg = cph(S_1_6) * 180/pi
let s17_deg = cph(S_1_7) * 180/pi
let s21_deg = cph(S_2_1) * 180/pi
let s22_deg = cph(S_2_2) * 180/pi
let s23_deg = cph(S_2_3) * 180/pi
let s24_deg = cph(S_2_4) * 180/pi
let s25_deg = cph(S_2_5) * 180/pi
let s26_deg = cph(S_2_6) * 180/pi
let s27_deg = cph(S_2_7) * 180/pi
let s31_deg = cph(S_3_1) * 180/pi
let s32_deg = cph(S_3_2) * 180/pi
let s33_deg = cph(S_3_3) * 180/pi
let s34_deg = cph(S_3_4) * 180/pi
let s35_deg = cph(S_3_5) * 180/pi
let s36_deg = cph(S_3_6) * 180/pi
let s37_deg = cph(S_3_7) * 180/pi
let s41_deg = cph(S_4_1) * 180/pi
let s42_deg = cph(S_4_2) * 180/pi
let s43_deg = cph(S_4_3) * 180/pi
let s44_deg = cph(S_4_4) * 180/pi
let s45_deg = cph(S_4_5) * 180/pi
let s46_deg = cph(S_4_6) * 180/pi
let s47_deg = cph(S_4_7) * 180/pi
let s51_deg = cph(S_5_1) * 180/pi
let s52_deg = cph(S_5_2) * 180/pi
let s53_deg = cph(S_5_3) * 180/pi
let s54_deg = cph(S_5_4) * 180/pi
let s55_deg = cph(S_5_5) * 180/pi
let s56_deg = cph(S_5_6) * 180/pi
let s57_deg = cph(S_5_7) * 180/pi
let s61_deg = cph(S_6_1) * 180/pi
let s62_deg = cph(S_6_2) * 180/pi
let s63_deg = cph(S_6_3) * 180/pi
let s64_deg = cph(S_6_4) * 180/pi
let s65_deg = cph(S_6_5) * 180/pi
let s66_deg = cph(S_6_6) * 180/pi
let s67_deg = cph(S_6_7) * 180/pi
let s71_deg = cph(S_7_1) * 180/pi
let s72_deg = cph(S_7_2) * 180/pi
let s73_deg = cph(S_7_3) * 180/pi
let s74_deg = cph(S_7_4) * 180/pi
let s75_deg = cph(S_7_5) * 180/pi
let s76_deg = cph(S_7_6) * 180/pi
let s77_deg = cph(S_7_7) * 180/pi

let s41_31_deg = ph(S_4_1/S_3_1) * 180/pi
let s51_61_deg = ph(S_5_1/S_6_1) * 180/pi
let s32_42_deg = ph(S_3_2/S_4_2) * 180/pi
let s62_52_deg = ph(S_6_2/S_5_2) * 180/pi

* Write the raw AFTER the derived vectors so the interactive graphs can
* reference the imbalance vectors (s41_31_deg, ...) directly by name.
write @schname\\\\.raw
set appendwrite

* Plotting
plot s11_dB s22_dB s33_dB s44_dB s55_dB s66_dB s77_dB
plot s41_31_dB s51_61_dB s32_42_dB s62_52_dB
plot s41_31_deg s51_61_deg s32_42_deg s62_52_deg

* Write Data
unset appendwrite
set wr_vecnames
set wr_singlescale
wrdata ../sim_data/@schname\\\\.txt
+ s11_dB s12_dB s13_dB s14_dB s15_dB s16_dB s17_dB
+ s21_dB s22_dB s23_dB s24_dB s25_dB s26_dB s27_dB
+ s31_dB s32_dB s33_dB s34_dB s35_dB s36_dB s37_dB
+ s41_dB s42_dB s43_dB s44_dB s45_dB s46_dB s47_dB
+ s51_dB s52_dB s53_dB s54_dB s55_dB s56_dB s57_dB
+ s61_dB s62_dB s63_dB s64_dB s65_dB s66_dB s67_dB
+ s71_dB s72_dB s73_dB s74_dB s75_dB s76_dB s77_dB
+ s11_deg s12_deg s13_deg s14_deg s15_deg s16_deg s17_deg
+ s21_deg s22_deg s23_deg s24_deg s25_deg s26_deg s27_deg
+ s31_deg s32_deg s33_deg s34_deg s35_deg s36_deg s37_deg
+ s41_deg s42_deg s43_deg s44_deg s45_deg s46_deg s47_deg
+ s51_deg s52_deg s53_deg s54_deg s55_deg s56_deg s57_deg
+ s61_deg s62_deg s63_deg s64_deg s65_deg s66_deg s67_deg
+ s71_deg s72_deg s73_deg s74_deg s75_deg s76_deg s77_deg
+ s41_31_dB s51_61_dB s32_42_dB s62_52_dB
+ s41_31_deg s51_61_deg s32_42_deg s62_52_deg

*quit
.endc
"}
C {title-2.sym} 0 0 0 0 {name=l2 author="Simon Dorrer" rev=1.0 lock=true}
C {lab_pin.sym} 1960 -1780 0 1 {name=p3 sig_type=std_logic lab=v7}
C {devices/gnd.sym} 1920 -1580 0 0 {name=l3 lab=GND}
C {devices/launcher.sym} 2600 -2120 0 0 {name=h2
descr="Simulate" 
tclcommand="xschem save; xschem netlist; xschem simulate"
}
C {devices/launcher.sym} 2600 -2000 0 0 {name=h1
descr="Load waves" 
tclcommand="xschem raw_read $netlist_dir/[file rootname [file tail [xschem get current_name]]].raw sp"
}
C {devices/launcher.sym} 2600 -2060 0 0 {name=h3
descr="Annotate OP" 
tclcommand="set show_hidden_texts 1; xschem annotate_op"
}
C {devices/code_shown.sym} 2860 -2110 0 0 {name=MODEL only_toplevel=true
format="tcleval( @value )"
value="
.lib cornerMOSlv.lib mos_tt
.lib cornerMOShv.lib mos_tt
.lib cornerHBT.lib hbt_typ
.lib cornerRES.lib res_typ
.lib cornerCAP.lib cap_typ
.lib cornerDIO.lib dio_tt
"}
C {devices/vsource.sym} 1920 -1650 0 0 {name=v7 value="dc 0 ac 1 portnum 7 z0 50"
}
C {lab_pin.sym} 2160 -1860 0 1 {name=p1 sig_type=std_logic lab=v2}
C {devices/gnd.sym} 2120 -1580 0 0 {name=l1 lab=GND}
C {devices/vsource.sym} 2120 -1650 0 0 {name=v2 value="dc 0 ac 1 portnum 2 z0 50"
}
C {sparx_core.sym} 1660 -1820 0 0 {name=x1}
C {lab_pin.sym} 1620 -1700 0 0 {name=p4 sig_type=std_logic lab=v6}
C {devices/gnd.sym} 1620 -1580 0 1 {name=l5 lab=GND}
C {devices/vsource.sym} 1620 -1650 0 1 {name=v6 value="dc 0 ac 1 portnum 6 z0 50"
}
C {lab_pin.sym} 1700 -1700 0 1 {name=p6 sig_type=std_logic lab=v5}
C {devices/gnd.sym} 1700 -1580 0 0 {name=l7 lab=GND}
C {devices/vsource.sym} 1700 -1650 0 0 {name=v5 value="dc 0 ac 1 portnum 5 z0 50"
}
C {lab_pin.sym} 1360 -1820 0 0 {name=p5 sig_type=std_logic lab=v1}
C {devices/gnd.sym} 1400 -1580 0 1 {name=l6 lab=GND}
C {devices/vsource.sym} 1400 -1650 0 1 {name=v1 value="dc 0 ac 1 portnum 1 z0 50"
}
C {lab_pin.sym} 1700 -1940 2 0 {name=p7 sig_type=std_logic lab=v4}
C {devices/gnd.sym} 1700 -2060 2 1 {name=l8 lab=GND}
C {devices/vsource.sym} 1700 -1990 2 1 {name=v4 value="dc 0 ac 1 portnum 4 z0 50"
}
C {lab_pin.sym} 1620 -1940 2 1 {name=p8 sig_type=std_logic lab=v3}
C {devices/gnd.sym} 1620 -2060 2 0 {name=l9 lab=GND}
C {devices/vsource.sym} 1620 -1990 2 0 {name=v3 value="dc 0 ac 1 portnum 3 z0 50"
}
