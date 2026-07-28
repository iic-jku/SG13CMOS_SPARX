v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
B 2 780 -1880 1580 -1480 {flags=graph
y1=-28
y2=-4.9
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=8e+10
x2=2.4e+11
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="\\"|S11|; s_1_1 db20()\\"
\\"|S22|; s_2_2 db20()\\"
\\"|S33|; s_3_3 db20()\\"
\\"|S44|; s_4_4 db20()\\""
color="4 7 12 21"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
B 2 780 -1460 1580 -1060 {flags=graph
y1=-170
y2=170
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=8e+10
x2=2.4e+11
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="\\"arg(S11); ph(S_1_1) cph()\\"
\\"arg(S22); ph(S_2_2) cph()\\"
\\"arg(S33); ph(S_3_3) cph()\\"
\\"arg(S44); ph(S_4_4) cph()\\""
color="4 7 12 21"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
B 2 1640 -1880 2440 -1480 {flags=graph
y1=-18
y2=-3.1
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=8e+10
x2=2.4e+11
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="\\"|S12|; s_1_2 db20()\\"
\\"|S21|; s_2_1 db20()\\"
\\"|S13|; s_1_3 db20()\\"
\\"|S31|; s_3_1 db20()\\"
\\"|S14|; s_1_4 db20()\\"
\\"|S41|; s_4_1 db20()\\""
color="4 7 12 21 17 18"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
B 2 1640 -1460 2440 -1060 {flags=graph
y1=-280
y2=-46
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=8e+10
x2=2.4e+11
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="\\"arg(S12); ph(S_1_2) cph()\\"
\\"arg(S21); ph(S_2_1) cph()\\"
\\"arg(S13); ph(S_1_3) cph()\\"
\\"arg(S31); ph(S_3_1) cph()\\"
\\"arg(S14); ph(S_1_4) cph()\\"
\\"arg(S41); ph(S_4_1) cph()\\""
color="4 7 12 21 17 18"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
B 2 780 -1040 1580 -640 {flags=graph
y1=-18
y2=-3.1
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=8e+10
x2=2.4e+11
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="\\"|S23|; s_2_3 db20()\\"
\\"|S32|; s_3_2 db20()\\"
\\"|S24|; s_2_4 db20()\\"
\\"|S42|; s_4_2 db20()\\""
color="4 7 12 21"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
B 2 780 -620 1580 -220 {flags=graph
y1=-290
y2=-62
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=8e+10
x2=2.4e+11
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="\\"arg(S23); ph(S_2_3) cph()\\"
\\"arg(S32); ph(S_3_2) cph()\\"
\\"arg(S24); ph(S_2_4) cph()\\"
\\"arg(S42); ph(S_4_2) cph()\\""
color="4 7 12 21"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
B 2 1640 -1040 2440 -640 {flags=graph
y1=-7.8
y2=-4.5
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=8e+10
x2=2.4e+11
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="\\"|S34|; s_3_4 db20()\\"
\\"|S43|; s_4_3 db20()\\""
color="4 7"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
B 2 1640 -620 2440 -220 {flags=graph
y1=-150
y2=-48
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=8e+10
x2=2.4e+11
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="\\"arg(S34); ph(S_3_4) cph()\\"
\\"arg(S43); ph(S_4_3) cph()\\""
color="4 7"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
T {Ngspice Testbench for AC S-parameter analysis - Branch Line Coupler} 760 -2390 0 0 1 1 {}
T {SPDX-FileCopyrightText: 2025-2026 The SPARX Team
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
} 2850 -220 0 0 0.4 0.4 {}
N 1800 -2100 1800 -2060 {lab=v3}
N 1720 -2100 1800 -2100 {lab=v3}
N 1800 -2000 1800 -1960 {lab=GND}
N 1800 -2100 1840 -2100 {lab=v3}
N 2000 -2000 2000 -1960 {lab=GND}
N 2000 -2180 2040 -2180 {lab=#net1}
N 2000 -2180 2000 -2060 {lab=#net1}
N 1720 -2180 2000 -2180 {lab=#net1}
N 1440 -2100 1520 -2100 {lab=v4}
N 1440 -2000 1440 -1960 {lab=GND}
N 1440 -2100 1440 -2060 {lab=v4}
N 1400 -2100 1440 -2100 {lab=v4}
N 1240 -2000 1240 -1960 {lab=GND}
N 1200 -2180 1240 -2180 {lab=v1}
N 1240 -2180 1240 -2060 {lab=v1}
N 1240 -2180 1520 -2180 {lab=v1}
C {devices/code_shown.sym} 80 -2130 0 0 {name=NGSPICE
only_toplevel=true
lock=false
value="
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
write @schname\\\\.raw
set appendwrite

* Calculating S-Parameters
let s11_dB = db(S_1_1)
let s21_dB = db(S_2_1)
let s12_dB = db(S_1_2)
let s22_dB = db(S_2_2)
let s33_dB = db(s_3_3)
let s31_dB = db(S_3_1)
let s13_dB = db(S_1_3)
let s32_dB = db(S_3_2)
let s23_dB = db(S_2_3)
let s44_dB = db(S_4_4)
let s41_dB = db(S_4_1)
let s14_dB = db(S_1_4)
let s42_dB = db(S_4_2)
let s24_dB = db(S_2_4)
let s43_dB = db(s_4_3)
let s34_dB = db(s_3_4)

let s11_deg = cph(S_1_1) * 180/pi
let s21_deg = cph(S_2_1) * 180/pi
let s12_deg = cph(S_1_2) * 180/pi
let s22_deg = cph(S_2_2) * 180/pi
let s33_deg = cph(s_3_3) * 180/pi
let s31_deg = cph(S_3_1) * 180/pi
let s13_deg = cph(S_1_3) * 180/pi
let s32_deg = cph(S_3_2) * 180/pi
let s23_deg = cph(S_2_3) * 180/pi
let s44_deg = cph(s_4_4) * 180/pi
let s41_deg = cph(S_4_1) * 180/pi
let s14_deg = cph(S_1_4) * 180/pi
let s42_deg = cph(S_4_2) * 180/pi
let s24_deg = cph(S_2_4) * 180/pi
let s43_deg = cph(S_4_3) * 180/pi
let s34_deg = cph(S_3_4) * 180/pi

* Plotting
plot s11_dB s22_dB s33_dB s44_dB
plot s11_deg s22_deg s33_deg s44_deg
plot s12_dB s21_dB s13_dB s31_dB s14_dB s41_dB
plot s12_deg s21_deg s13_deg s31_deg s14_deg s41_deg
plot s23_dB s32_dB s24_dB s42_dB
plot s23_deg s32_deg s24_deg s42_deg
plot s34_dB s43_dB
plot s34_deg s43_deg

* Write Data
unset appendwrite
set wr_vecnames
set wr_singlescale
wrdata ../plot_simulations/data/@schname\\\\.txt
+ s11_dB s22_dB s33_dB s44_dB
+ s11_deg s22_deg s33_deg s44_deg
+ s12_dB s21_dB s13_dB s31_dB s14_dB s41_dB
+ s12_deg s21_deg s13_deg s31_deg s14_deg s41_deg
+ s23_dB s32_dB s24_dB s42_dB
+ s23_deg s32_deg s24_deg s42_deg
+ s34_dB s43_dB
+ s34_deg s43_deg

*quit
.endc
"}
C {title-2.sym} 0 0 0 0 {name=l2 author="Simon Dorrer" rev=1.0 lock=true}
C {lab_pin.sym} 1840 -2100 0 1 {name=p3 sig_type=std_logic lab=v3}
C {devices/lab_pin.sym} 2040 -2180 0 1 {name=l19 sig_type=std_logic lab=v2
}
C {devices/gnd.sym} 1440 -1960 0 0 {name=l39 lab=GND}
C {devices/vsource.sym} 2000 -2030 0 0 {name=v2 value="dc 0 ac 1 portnum 2 z0 50"
}
C {devices/gnd.sym} 1800 -1960 0 0 {name=l3 lab=GND}
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
C {devices/vsource.sym} 1800 -2030 0 0 {name=v3 value="dc 0 ac 1 portnum 3 z0 50"
}
C {lab_pin.sym} 1400 -2100 0 0 {name=p1 sig_type=std_logic lab=v4}
C {devices/gnd.sym} 2000 -1960 0 0 {name=l1 lab=GND}
C {devices/vsource.sym} 1440 -2030 0 1 {name=v4 value="dc 0 ac 1 portnum 4 z0 50"
}
C {lab_pin.sym} 1200 -2180 0 0 {name=p2 sig_type=std_logic lab=v1}
C {devices/gnd.sym} 1240 -1960 0 1 {name=l4 lab=GND}
C {devices/vsource.sym} 1240 -2030 0 1 {name=v1 value="dc 0 ac 1 portnum 1 z0 50"
}
C {sparx_blc_le.sym} 1620 -2140 0 0 {name=x1}
