v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
B 2 460 -1020 1260 -620 {flags=graph
y1=-33
y2=-6
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=1.2e+11
x2=2e+11
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="\\"|S11|; s_1_1 db20()\\"
\\"|S22|; s_2_2 db20()\\"
\\"|S33|; s_3_3 db20()\\""
color="4 7 12"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
B 2 460 -600 1260 -200 {flags=graph
y1=-110
y2=110
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=1.2e+11
x2=2e+11
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="\\"arg(S11); ph(S_1_1) cph()\\"
\\"arg(S22); ph(S_2_2) cph()\\"
\\"arg(S33); ph(S_3_3) cph()\\""
color="4 7 12"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
B 2 1320 -1020 2120 -620 {flags=graph
y1=-3.5
y2=-3.3
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=1.2e+11
x2=2e+11
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="\\"|S12|; s_1_2 db20()\\"
\\"|S21|; s_2_1 db20()\\"
\\"|S13|; s_1_3 db20()\\"
\\"|S31|; s_3_1 db20()\\""
color="4 7 12 21"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
B 2 1320 -600 2120 -200 {flags=graph
y1=-120
y2=-67
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=1.2e+11
x2=2e+11
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="\\"arg(S12); ph(S_1_2) cph()\\"
\\"arg(S21); ph(S_2_1) cph()\\"
\\"arg(S13); ph(S_1_3) cph()\\"
\\"arg(S31); ph(S_3_1) cph()\\""
color="4 7 12 21"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
B 2 2160 -1020 2960 -620 {flags=graph
y1=-7.1
y2=-6.7
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=1.2e+11
x2=2e+11
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="\\"|S23|; s_2_3 db20()\\"
\\"|S32|; s_3_2 db20()\\""
color="4 7"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
B 2 2160 -600 2960 -200 {flags=graph
y1=-180
y2=180
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=1.2e+11
x2=2e+11
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="\\"arg(S23); ph(S_2_3) cph()\\"
\\"arg(S32); ph(S_3_2) cph()\\""
color="4 7"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
T {Ngspice Testbench for AC S-parameter analysis - Wilkinson Power Divider} 740 -2370 0 0 1 1 {}
T {SPDX-FileCopyrightText: 2025-2026 The SPARX Team
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
} 1520 -60 0 0 0.4 0.4 {}
N 1420 -1540 1420 -1480 {lab=v1}
N 1420 -1420 1420 -1360 {lab=GND}
N 1340 -1540 1420 -1540 {lab=v1}
N 1420 -1540 1500 -1540 {lab=v1}
N 1780 -1500 1780 -1460 {lab=v3}
N 1700 -1500 1780 -1500 {lab=v3}
N 1780 -1400 1780 -1360 {lab=GND}
N 1780 -1500 1820 -1500 {lab=v3}
N 1980 -1400 1980 -1360 {lab=GND}
N 1980 -1580 2020 -1580 {lab=#net1}
N 1980 -1580 1980 -1460 {lab=#net1}
N 1700 -1580 1980 -1580 {lab=#net1}
C {devices/code_shown.sym} 60 -2250 0 0 {name=NGSPICE
only_toplevel=true
lock=false
value="
.include ../../../netlist/spice/sparx_wpd_le.spice
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

let s11_deg = cph(S_1_1) * 180/pi
let s21_deg = cph(S_2_1) * 180/pi
let s12_deg = cph(S_1_2) * 180/pi
let s22_deg = cph(S_2_2) * 180/pi
let s33_deg = cph(s_3_3) * 180/pi
let s31_deg = cph(S_3_1) * 180/pi
let s13_deg = cph(S_1_3) * 180/pi
let s32_deg = cph(S_3_2) * 180/pi
let s23_deg = cph(S_2_3) * 180/pi

* Plotting
plot s11_dB s22_dB s33_dB
plot s11_deg s22_deg s33_deg
plot s12_dB s21_dB s13_dB s31_dB
plot s12_deg s21_deg s13_deg s31_deg
plot s23_dB s32_dB
plot s23_deg s32_deg

* Write Data
unset appendwrite
set wr_vecnames
set wr_singlescale
wrdata ../plot_simulations/data/@schname\\\\.txt
+ s11_dB s22_dB s33_dB
+ s11_deg s22_deg s33_deg
+ s12_dB s21_dB s13_dB s31_dB
+ s12_deg s21_deg s13_deg s31_deg
+ s23_dB s32_dB
+ s23_deg s32_deg

*quit
.endc
"}
C {title-2.sym} 0 0 0 0 {name=l2 author="Simon Dorrer" rev=1.0 lock=true}
C {lab_pin.sym} 2020 -1580 0 1 {name=p3 sig_type=std_logic lab=v2}
C {devices/lab_pin.sym} 1340 -1540 0 0 {name=l19 sig_type=std_logic lab=v1
}
C {devices/gnd.sym} 1420 -1360 0 0 {name=l39 lab=GND}
C {devices/vsource.sym} 1420 -1450 0 1 {name=v1 value="dc 0 ac 1 portnum 1 z0 50"
}
C {devices/gnd.sym} 1780 -1360 0 0 {name=l3 lab=GND}
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
C {devices/vsource.sym} 1980 -1430 0 0 {name=v2 value="dc 0 ac 1 portnum 2 z0 50"
}
C {lab_pin.sym} 1820 -1500 0 1 {name=p1 sig_type=std_logic lab=v3}
C {devices/gnd.sym} 1980 -1360 0 0 {name=l1 lab=GND}
C {devices/vsource.sym} 1780 -1430 0 0 {name=v3 value="dc 0 ac 1 portnum 3 z0 50"
}
C {sparx_wpd_le.sym} 1600 -1540 0 0 {name=x1}
