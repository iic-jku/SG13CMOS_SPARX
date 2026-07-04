v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
B 2 820 -1440 1620 -1040 {flags=graph
y1=-33
y2=-6
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=2.1426146e+11
x2=2.9426146e+11
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
B 2 820 -1020 1620 -620 {flags=graph
y1=-110
y2=110
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=2.1426146e+11
x2=2.9426146e+11
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="\\"arg(S11); ph(S_1_1)\\"
\\"arg(S22); ph(S_2_2)\\"
\\"arg(S33); ph(S_3_3)\\"
\\"arg(S44); ph(S_4_4)\\""
color="4 7 12 21"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
B 2 1680 -1440 2480 -1040 {flags=graph
y1=-3.5
y2=-3.3
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=2.1426146e+11
x2=2.9426146e+11
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
B 2 1680 -1020 2480 -620 {flags=graph
y1=-120
y2=-67
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=2.1426146e+11
x2=2.9426146e+11
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="\\"arg(S12); ph(S_1_2)\\"
\\"arg(S21); ph(S_2_1)\\"
\\"arg(S13); ph(S_1_3)\\"
\\"arg(S31); ph(S_3_1)\\"
\\"arg(S14); ph(S_1_4)\\"
\\"arg(S41); ph(S_4_1)\\""
color="4 7 12 21 17 18"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
B 2 820 -600 1620 -200 {flags=graph
y1=-7.1
y2=-6.7
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=2.1426146e+11
x2=2.9426146e+11
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
B 2 1680 -600 2480 -200 {flags=graph
y1=-7.1
y2=-6.7
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=2.1426146e+11
x2=2.9426146e+11
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
T {Ngspice Testbench for AC S-parameter analysis - Six-Port} 830 -2380 0 0 1 1 {}
N 1970 -2820 1970 -2780 {lab=v3}
N 1890 -2820 1970 -2820 {lab=v3}
N 1970 -2720 1970 -2680 {lab=GND}
N 1970 -2820 2010 -2820 {lab=v3}
N 2170 -2720 2170 -2680 {lab=GND}
N 2170 -2900 2210 -2900 {lab=v4}
N 2170 -2900 2170 -2780 {lab=v4}
N 1890 -2900 2170 -2900 {lab=v4}
N 1610 -2820 1690 -2820 {lab=v2}
N 1610 -2720 1610 -2680 {lab=GND}
N 1610 -2820 1610 -2780 {lab=v2}
N 1570 -2820 1610 -2820 {lab=v2}
N 1410 -2720 1410 -2680 {lab=GND}
N 1370 -2900 1410 -2900 {lab=v1}
N 1410 -2900 1410 -2780 {lab=v1}
N 1410 -2900 1690 -2900 {lab=v1}
N 2600 -1840 2600 -1800 {lab=VDD}
N 2600 -1740 2600 -1700 {lab=GND}
N 1700 -2040 1700 -1960 {lab=VDD}
N 1660 -2000 1660 -1960 {lab=#net1}
N 1660 -2000 1740 -2000 {lab=#net1}
N 1740 -2000 1740 -1960 {lab=#net1}
N 1500 -2000 1660 -2000 {lab=#net1}
N 1500 -1780 1500 -1640 {lab=#net1}
N 1500 -1860 1540 -1860 {lab=#net1}
N 1500 -2000 1500 -1860 {lab=#net1}
N 1500 -1780 1540 -1780 {lab=#net1}
N 1500 -1860 1500 -1780 {lab=#net1}
N 1740 -2000 1900 -2000 {lab=#net1}
N 1460 -1820 1540 -1820 {lab=#net2}
N 1860 -1820 1940 -1820 {lab=#net3}
N 1900 -2000 1900 -1860 {lab=#net1}
N 1860 -1860 1900 -1860 {lab=#net1}
N 1900 -1860 1900 -1780 {lab=#net1}
N 1860 -1780 1900 -1780 {lab=#net1}
N 1900 -1780 1900 -1640 {lab=#net1}
N 1740 -1680 1740 -1640 {lab=#net1}
N 1660 -1680 1660 -1640 {lab=#net1}
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
wrdata ../sim_data/@schname\\\\.txt
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
C {lab_pin.sym} 2010 -2820 0 1 {name=p3 sig_type=std_logic lab=v3}
C {devices/lab_pin.sym} 1570 -2820 0 0 {name=l19 sig_type=std_logic lab=v2
}
C {devices/gnd.sym} 1610 -2680 0 0 {name=l39 lab=GND}
C {devices/vsource.sym} 1610 -2750 0 1 {name=v2 value="dc 0 ac 1 portnum 2 z0 50"
}
C {devices/gnd.sym} 1970 -2680 0 0 {name=l3 lab=GND}
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
C {devices/vsource.sym} 1970 -2750 0 0 {name=v3 value="dc 0 ac 1 portnum 3 z0 50"
}
C {lab_pin.sym} 2210 -2900 0 1 {name=p1 sig_type=std_logic lab=v4}
C {devices/gnd.sym} 2170 -2680 0 0 {name=l1 lab=GND}
C {devices/vsource.sym} 2170 -2750 0 0 {name=v4 value="dc 0 ac 1 portnum 4 z0 50"
}
C {lab_pin.sym} 1370 -2900 0 0 {name=p2 sig_type=std_logic lab=v1}
C {devices/gnd.sym} 1410 -2680 0 1 {name=l4 lab=GND}
C {devices/vsource.sym} 1410 -2750 0 1 {name=v1 value="dc 0 ac 1 portnum 1 z0 50"
}
C {sparx_top.sym} 1700 -1820 0 0 {name=x1}
C {devices/gnd.sym} 2600 -1700 0 0 {name=l5 lab=GND}
C {devices/vsource.sym} 2600 -1770 0 0 {name=VDD value=1.5}
C {vdd.sym} 2600 -1840 0 0 {name=l6 lab=VDD}
C {vdd.sym} 1700 -2040 0 0 {name=l7 lab=VDD}
C {devices/gnd.sym} 1900 -1640 0 0 {name=l8 lab=GND}
C {devices/gnd.sym} 1740 -1640 0 0 {name=l9 lab=GND}
C {devices/gnd.sym} 1660 -1640 0 0 {name=l10 lab=GND}
C {devices/gnd.sym} 1500 -1640 0 0 {name=l11 lab=GND}
