v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
B 2 960 -800 1760 -400 {flags=graph
y1=-1
y2=1
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=-1.194049e-12
x2=2.1845951e-11
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="v1
v2
v3"
color="11 7 12"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
T {Ngspice Testbench for Transient analysis - Wilkinson Power Divider} 430 -1710 0 0 1 1 {}
T {SPDX-FileCopyrightText: 2025-2026 The SPARX Team
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
} 1920 -220 0 0 0.4 0.4 {}
N 1100 -1120 1100 -1060 {lab=v1}
N 1100 -1000 1100 -940 {lab=GND}
N 1020 -1120 1100 -1120 {lab=v1}
N 1100 -1120 1180 -1120 {lab=v1}
N 1460 -1080 1460 -1040 {lab=v3}
N 1380 -1080 1460 -1080 {lab=v3}
N 1460 -980 1460 -940 {lab=GND}
N 1460 -1080 1500 -1080 {lab=v3}
N 1660 -980 1660 -940 {lab=GND}
N 1660 -1160 1700 -1160 {lab=#net1}
N 1660 -1160 1660 -1040 {lab=#net1}
N 1380 -1160 1660 -1160 {lab=#net1}
C {devices/code_shown.sym} 120 -1230 0 0 {name=NGSPICE
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

* Transient Analysis
tran 100f 20p
remzerovec
write @schname\\\\.raw
set appendwrite

* Plotting
plot v1 v2 v3

* Write Data
unset appendwrite
set wr_vecnames
set wr_singlescale
wrdata ../plot_simulations/data/@schname\\\\.txt v1 v2 v3

*quit
.endc
"}
C {title-3.sym} 0 0 0 0 {name=l2 author="Simon Dorrer" rev=1.0 lock=true}
C {lab_pin.sym} 1700 -1160 0 1 {name=p3 sig_type=std_logic lab=v2}
C {devices/lab_pin.sym} 1020 -1120 0 0 {name=l19 sig_type=std_logic lab=v1
}
C {devices/gnd.sym} 1100 -940 0 0 {name=l39 lab=GND}
C {devices/gnd.sym} 1460 -940 0 0 {name=l3 lab=GND}
C {devices/launcher.sym} 1820 -1440 0 0 {name=h2
descr="Simulate" 
tclcommand="xschem save; xschem netlist; xschem simulate"
}
C {devices/launcher.sym} 1820 -1320 0 0 {name=h1
descr="Load waves" 
tclcommand="xschem raw_read $netlist_dir/[file rootname [file tail [xschem get current_name]]].raw tran"
}
C {devices/launcher.sym} 1820 -1380 0 0 {name=h3
descr="Annotate OP" 
tclcommand="set show_hidden_texts 1; xschem annotate_op"
}
C {devices/code_shown.sym} 2080 -1430 0 0 {name=MODEL only_toplevel=true
format="tcleval( @value )"
value="
.lib cornerMOSlv.lib mos_tt
.lib cornerMOShv.lib mos_tt
.lib cornerHBT.lib hbt_typ
.lib cornerRES.lib res_typ
.lib cornerCAP.lib cap_typ
.lib cornerDIO.lib dio_tt
"}
C {lab_pin.sym} 1500 -1080 0 1 {name=p1 sig_type=std_logic lab=v3}
C {devices/gnd.sym} 1660 -940 0 0 {name=l1 lab=GND}
C {sparx_wpd_le.sym} 1280 -1120 0 0 {name=x1}
C {res.sym} 1460 -1010 0 0 {name=R1
value=50
footprint=1206
device=resistor
m=1}
C {res.sym} 1660 -1010 0 0 {name=R2
value=50
footprint=1206
device=resistor
m=1}
C {devices/vsource.sym} 1100 -1030 0 1 {name=vin spice_ignore=False value="sin(0.5 1 160G)"
}
