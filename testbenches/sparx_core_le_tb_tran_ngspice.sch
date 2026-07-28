v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
B 2 500 -660 1300 -260 {flags=graph
y1=-1
y2=1
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=4.5389649e-10
x2=1.1105213e-09
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="v1
v2
v3
v4
v5
v6
v7"
color="11 7 12 21 17 18 15"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
B 2 1320 -660 2120 -260 {flags=graph
y1=-0.062
y2=0.062
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=4.5389649e-10
x2=1.1105213e-09
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="v3
v4
v5
v6"
color="11 7 12 21"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
T {Ngspice Testbench for Transient analysis - Six-Port Core} 430 -1710 0 0 1 1 {}
T {SPDX-FileCopyrightText: 2025-2026 The SPARX Team
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
} 1920 -220 0 0 0.4 0.4 {}
N 1480 -1080 1480 -980 {lab=v7}
N 1480 -920 1480 -880 {lab=GND}
N 1480 -1080 1520 -1080 {lab=v7}
N 1680 -920 1680 -880 {lab=GND}
N 1680 -1160 1720 -1160 {lab=v2}
N 1680 -1160 1680 -980 {lab=v2}
N 1180 -1020 1180 -980 {lab=v6}
N 1180 -920 1180 -880 {lab=GND}
N 1260 -1020 1260 -980 {lab=v5}
N 1260 -920 1260 -880 {lab=GND}
N 1340 -1080 1480 -1080 {lab=v7}
N 1340 -1160 1680 -1160 {lab=v2}
N 960 -920 960 -880 {lab=GND}
N 960 -1120 1100 -1120 {lab=v1}
N 960 -1120 960 -980 {lab=v1}
N 920 -1120 960 -1120 {lab=v1}
N 1260 -1260 1260 -1220 {lab=v4}
N 1260 -1360 1260 -1320 {lab=GND}
N 1180 -1260 1180 -1220 {lab=v3}
N 1180 -1360 1180 -1320 {lab=GND}
C {devices/code_shown.sym} 80 -1450 0 0 {name=NGSPICE
only_toplevel=true
lock=false
value="
.include ../../netlist/spice/sparx_core_le.spice
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
tran 100p 4n
remzerovec
write @schname\\\\.raw
set appendwrite

* Plotting
plot v1 v2 v3 v4 v5 v6 v7
plot v3 v4 v5 v6

* Write Data
unset appendwrite
set wr_vecnames
set wr_singlescale
wrdata ../plot_simulations/data/@schname\\\\.txt v1 v2 v3 v4 v5 v6 v7

*quit
.endc
"}
C {title-3.sym} 0 0 0 0 {name=l2 author="Simon Dorrer" rev=1.0 lock=true}
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
C {devices/vsource.sym} 960 -950 0 1 {name=vlo spice_ignore=False value="sin(0 1 159G)"
}
C {res.sym} 1180 -950 0 1 {name=R1
value=50
footprint=1206
device=resistor
m=1}
C {lab_pin.sym} 1520 -1080 0 1 {name=p3 sig_type=std_logic lab=v7}
C {devices/gnd.sym} 1480 -880 0 0 {name=l3 lab=GND}
C {lab_pin.sym} 1720 -1160 0 1 {name=p1 sig_type=std_logic lab=v2}
C {devices/gnd.sym} 1680 -880 0 0 {name=l1 lab=GND}
C {lab_pin.sym} 1180 -1000 0 0 {name=p4 sig_type=std_logic lab=v6}
C {devices/gnd.sym} 1180 -880 0 1 {name=l5 lab=GND}
C {lab_pin.sym} 1260 -1000 0 1 {name=p6 sig_type=std_logic lab=v5}
C {devices/gnd.sym} 1260 -880 0 0 {name=l7 lab=GND}
C {lab_pin.sym} 920 -1120 0 0 {name=p5 sig_type=std_logic lab=v1}
C {devices/gnd.sym} 960 -880 0 1 {name=l6 lab=GND}
C {lab_pin.sym} 1260 -1240 2 0 {name=p7 sig_type=std_logic lab=v4}
C {devices/gnd.sym} 1260 -1360 2 1 {name=l8 lab=GND}
C {lab_pin.sym} 1180 -1240 2 1 {name=p8 sig_type=std_logic lab=v3}
C {devices/gnd.sym} 1180 -1360 2 0 {name=l9 lab=GND}
C {devices/vsource.sym} 1680 -950 0 0 {name=vrf spice_ignore=False value="sin(0 100m 161G)"
}
C {res.sym} 1260 -950 0 0 {name=R2
value=50
footprint=1206
device=resistor
m=1}
C {res.sym} 1480 -950 0 0 {name=R3
value=50
footprint=1206
device=resistor
m=1}
C {res.sym} 1180 -1290 2 0 {name=R4
value=50
footprint=1206
device=resistor
m=1}
C {res.sym} 1260 -1290 2 1 {name=R5
value=50
footprint=1206
device=resistor
m=1}
C {sparx_core_le.sym} 1220 -1120 0 0 {name=x1}
