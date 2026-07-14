v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
B 2 820 -1440 1620 -1040 {flags=graph
y1=-26
y2=-2.4
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=1.44e+11
x2=1.76e+11
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
B 2 820 -1020 1620 -620 {flags=graph
y1=-94
y2=160
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=1.44e+11
x2=1.76e+11
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
B 2 1680 -1440 2480 -1040 {flags=graph
y1=1.3
y2=6.3
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=1.44e+11
x2=1.76e+11
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="\\"|S41|-|S31|; s41_31_dB\\"
\\"|S51|-|S61|; s51_61_dB\\"
\\"|S32|-|S42|; s32_42_dB\\"
\\"|S62|-|S52|; s62_52_dB\\""
color="4 7 12 21"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
B 2 1680 -1020 2480 -620 {flags=graph
y1=77
y2=110
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=1.44e+11
x2=1.76e+11
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="\\"arg(S41)-arg(S31); s41_31_deg\\"
\\"arg(S51)-arg(S61); s51_61_deg\\"
\\"arg(S32)-arg(S42); s32_42_deg\\"
\\"arg(S62)-arg(S52); s62_52_deg\\""
color="4 7 12 21"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
T {Ngspice Testbench for AC S-parameter analysis - Six-Port Core} 830 -2380 0 0 1 1 {}
N 1860 -1820 1860 -1720 {lab=v7}
N 1860 -1660 1860 -1620 {lab=GND}
N 1860 -1820 1900 -1820 {lab=v7}
N 2060 -1660 2060 -1620 {lab=GND}
N 2060 -1900 2100 -1900 {lab=v2}
N 2060 -1900 2060 -1720 {lab=v2}
N 1560 -1760 1560 -1720 {lab=v6}
N 1560 -1660 1560 -1620 {lab=GND}
N 1640 -1760 1640 -1720 {lab=v5}
N 1640 -1660 1640 -1620 {lab=GND}
N 1720 -1820 1860 -1820 {lab=v7}
N 1720 -1900 2060 -1900 {lab=v2}
N 1340 -1660 1340 -1620 {lab=GND}
N 1340 -1860 1480 -1860 {lab=v1}
N 1340 -1860 1340 -1720 {lab=v1}
N 1300 -1860 1340 -1860 {lab=v1}
N 1640 -2000 1640 -1960 {lab=v4}
N 1640 -2100 1640 -2060 {lab=GND}
N 1560 -2000 1560 -1960 {lab=v3}
N 1560 -2100 1560 -2060 {lab=GND}
C {devices/code_shown.sym} 80 -2130 0 0 {name=NGSPICE
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
let s31_dB = db(S_3_1)
let s41_dB = db(S_4_1)
let s51_dB = db(S_5_1)
let s61_dB = db(S_6_1)
let s32_dB = db(S_3_2)
let s42_dB = db(S_4_2)
let s52_dB = db(S_5_2)
let s62_dB = db(S_6_2)
let s11_dB = db(S_1_1)
let s22_dB = db(S_2_2)
let s33_dB = db(s_3_3)
let s44_dB = db(S_4_4)
let s55_dB = db(S_5_5)
let s66_dB = db(S_6_6)
let s77_dB = db(S_7_7)
let s41_31_dB = (s41_dB - s31_dB)
let s51_61_dB = s51_dB - s61_dB
let s32_42_dB = s32_dB - s42_dB
let s62_52_dB = s62_dB - s52_dB

let s31_deg = cph(S_3_1) * 180/pi
let s41_deg = cph(S_4_1) * 180/pi
let s51_deg = cph(S_5_1) * 180/pi
let s61_deg = cph(S_6_1) * 180/pi
let s32_deg = cph(S_3_2) * 180/pi
let s42_deg = cph(S_4_2) * 180/pi
let s52_deg = cph(S_5_2) * 180/pi
let s62_deg = cph(S_6_2) * 180/pi
let s11_deg = cph(S_1_1) * 180/pi
let s22_deg = cph(S_2_2) * 180/pi
let s33_deg = cph(s_3_3) * 180/pi
let s44_deg = cph(S_4_4) * 180/pi
let s55_deg = cph(S_5_5) * 180/pi
let s66_deg = cph(S_6_6) * 180/pi
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
+ s11_dB s22_dB s33_dB s44_dB s55_dB s66_dB s77_dB
+ s41_31_dB s51_61_dB s32_42_dB s62_52_dB
+ s41_31_deg s51_61_deg s32_42_deg s62_52_deg

*quit
.endc
"}
C {title-2.sym} 0 0 0 0 {name=l2 author="Simon Dorrer" rev=1.0 lock=true}
C {lab_pin.sym} 1900 -1820 0 1 {name=p3 sig_type=std_logic lab=v7}
C {devices/gnd.sym} 1860 -1620 0 0 {name=l3 lab=GND}
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
C {devices/vsource.sym} 1860 -1690 0 0 {name=v7 value="dc 0 ac 1 portnum 7 z0 50"
}
C {lab_pin.sym} 2100 -1900 0 1 {name=p1 sig_type=std_logic lab=v2}
C {devices/gnd.sym} 2060 -1620 0 0 {name=l1 lab=GND}
C {devices/vsource.sym} 2060 -1690 0 0 {name=v2 value="dc 0 ac 1 portnum 2 z0 50"
}
C {sparx_core.sym} 1600 -1860 0 0 {name=x1}
C {lab_pin.sym} 1560 -1740 0 0 {name=p4 sig_type=std_logic lab=v6}
C {devices/gnd.sym} 1560 -1620 0 1 {name=l5 lab=GND}
C {devices/vsource.sym} 1560 -1690 0 1 {name=v6 value="dc 0 ac 1 portnum 6 z0 50"
}
C {lab_pin.sym} 1640 -1740 0 1 {name=p6 sig_type=std_logic lab=v5}
C {devices/gnd.sym} 1640 -1620 0 0 {name=l7 lab=GND}
C {devices/vsource.sym} 1640 -1690 0 0 {name=v5 value="dc 0 ac 1 portnum 5 z0 50"
}
C {lab_pin.sym} 1300 -1860 0 0 {name=p5 sig_type=std_logic lab=v1}
C {devices/gnd.sym} 1340 -1620 0 1 {name=l6 lab=GND}
C {devices/vsource.sym} 1340 -1690 0 1 {name=v1 value="dc 0 ac 1 portnum 1 z0 50"
}
C {lab_pin.sym} 1640 -1980 2 0 {name=p7 sig_type=std_logic lab=v4}
C {devices/gnd.sym} 1640 -2100 2 1 {name=l8 lab=GND}
C {devices/vsource.sym} 1640 -2030 2 1 {name=v4 value="dc 0 ac 1 portnum 4 z0 50"
}
C {lab_pin.sym} 1560 -1980 2 1 {name=p8 sig_type=std_logic lab=v3}
C {devices/gnd.sym} 1560 -2100 2 0 {name=l9 lab=GND}
C {devices/vsource.sym} 1560 -2030 2 0 {name=v3 value="dc 0 ac 1 portnum 3 z0 50"
}
