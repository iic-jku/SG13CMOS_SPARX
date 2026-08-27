v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
B 2 820 -1000 1620 -600 {flags=graph
y1=-7.2
y2=-0.66
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
\\"|S22|; s_2_2 db20()\\""
color="4 7"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
B 2 820 -580 1620 -180 {flags=graph
y1=100
y2=160
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
\\"arg(S22); ph(S_2_2) cph()\\""
color="4 7"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
B 2 1680 -1000 2480 -600 {flags=graph
y1=-42
y2=-9.8
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
\\"|S21|; s_2_1 db20()\\""
color="4 7"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
B 2 1680 -580 2480 -180 {flags=graph
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
node="\\"arg(S12); ph(S_1_2) cph()\\"
\\"arg(S21); ph(S_2_1) cph()\\""
color="4 7"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
T {Ngspice Testbench for AC S-parameter analysis - Bandpass Filter} 400 -1710 0 0 1 1 {}
T {SPDX-FileCopyrightText: 2025-2026 The SPARX Team
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
} 610 -60 0 0 0.4 0.4 {}
N 1000 -1240 1000 -1180 {lab=v1}
N 1000 -1120 1000 -1060 {lab=GND}
N 920 -1240 1000 -1240 {lab=v1}
N 1280 -1240 1360 -1240 {lab=v2}
N 1360 -1120 1360 -1060 {lab=GND}
N 1360 -1240 1360 -1180 {lab=v2}
N 1360 -1240 1440 -1240 {lab=v2}
N 1000 -1240 1080 -1240 {lab=v1}
C {devices/code_shown.sym} 40 -1330 0 0 {name=NGSPICE
only_toplevel=true
lock=false
value="
.include ../../../netlist/spice/sparx_bpf_le.spice
.include ../sim_range.spice
.temp 27
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

let s11_deg = cph(S_1_1) * 180/pi
let s21_deg = cph(S_2_1) * 180/pi
let s12_deg = cph(S_1_2) * 180/pi
let s22_deg = cph(S_2_2) * 180/pi

* Plotting
plot s11_dB s22_dB
plot s11_deg s22_deg
plot s12_dB s21_dB
plot s12_deg s21_deg

* Write Data
unset appendwrite
set wr_vecnames
set wr_singlescale
wrdata ../plot_simulations/data/@schname\\\\.txt
+ s11_dB s22_dB s12_dB s21_dB
+ s11_deg s22_deg s12_deg s21_deg

*quit
.endc
"}
C {title-3.sym} 0 0 0 0 {name=l2 author="Simon Dorrer" rev=1.0 lock=true}
C {lab_pin.sym} 1440 -1240 0 1 {name=p3 sig_type=std_logic lab=v2}
C {devices/lab_pin.sym} 920 -1240 0 0 {name=l19 sig_type=std_logic lab=v1
}
C {devices/gnd.sym} 1000 -1060 0 0 {name=l39 lab=GND}
C {devices/vsource.sym} 1000 -1150 0 1 {name=v1 value="dc 0 ac 1 portnum 1 z0 50"
}
C {devices/gnd.sym} 1360 -1060 0 0 {name=l3 lab=GND}
C {devices/launcher.sym} 1740 -1180 0 0 {name=h2
descr="Simulate" 
tclcommand="xschem save; xschem netlist; file mkdir $netlist_dir; write_data [save_params] $netlist_dir/[file rootname [file tail [xschem get current_name]]].save; xschem simulate"
}
C {devices/launcher.sym} 1740 -1060 0 0 {name=h1
descr="Load waves" 
tclcommand="xschem raw_read $netlist_dir/[file rootname [file tail [xschem get current_name]]].raw sp"
}
C {devices/launcher.sym} 1740 -1120 0 0 {name=h3
descr="Annotate OP" 
tclcommand="set show_hidden_texts 1; xschem annotate_op"
}
C {devices/code_shown.sym} 2000 -1170 0 0 {name=MODEL only_toplevel=true
format="tcleval( @value )"
value="
.lib cornerMOSlv.lib mos_tt
.lib cornerMOShv.lib mos_tt
.lib cornerHBT.lib hbt_typ
.lib cornerRES.lib res_typ
.lib cornerCAP.lib cap_typ
.lib cornerDIO.lib dio_tt
"}
C {devices/vsource.sym} 1360 -1150 0 0 {name=v2 value="dc 0 ac 1 portnum 2 z0 50"
}
C {sparx_bpf_le.sym} 1180 -1240 0 0 {name=x1}
