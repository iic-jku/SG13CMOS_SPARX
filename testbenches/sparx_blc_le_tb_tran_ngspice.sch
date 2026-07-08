v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
B 2 1040 -780 1840 -380 {flags=graph
y1=-1
y2=1
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=0
x2=4e-11
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="v1
v2
v3
v4"
color="11 7 12 21"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
T {Ngspice Testbench for Transient analysis - Branch Line Coupler} 430 -1710 0 0 1 1 {}
N 1620 -1000 1620 -960 {lab=v3}
N 1540 -1000 1620 -1000 {lab=v3}
N 1620 -900 1620 -860 {lab=GND}
N 1620 -1000 1660 -1000 {lab=v3}
N 1820 -900 1820 -860 {lab=GND}
N 1820 -1080 1860 -1080 {lab=v2}
N 1820 -1080 1820 -960 {lab=v2}
N 1540 -1080 1820 -1080 {lab=v2}
N 1260 -1000 1340 -1000 {lab=v4}
N 1260 -900 1260 -860 {lab=GND}
N 1260 -1000 1260 -960 {lab=v4}
N 1220 -1000 1260 -1000 {lab=v4}
N 1060 -900 1060 -860 {lab=GND}
N 1020 -1080 1060 -1080 {lab=v1}
N 1060 -1080 1060 -960 {lab=v1}
N 1060 -1080 1340 -1080 {lab=v1}
C {devices/code_shown.sym} 120 -1230 0 0 {name=NGSPICE
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

* Transient Analysis
tran 100f 40p
remzerovec
write @schname\\\\.raw
set appendwrite

* Plotting
plot v1 v2 v3 v4

* Write Data
unset appendwrite
set wr_vecnames
set wr_singlescale
wrdata ../sim_data/@schname\\\\.txt v1 v2 v3 v4

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
C {devices/vsource.sym} 1060 -930 0 1 {name=vin spice_ignore=False value="sin(0.5 1 160G)"
}
C {lab_pin.sym} 1660 -1000 0 1 {name=p3 sig_type=std_logic lab=v3}
C {devices/lab_pin.sym} 1860 -1080 0 1 {name=l19 sig_type=std_logic lab=v2
}
C {devices/gnd.sym} 1260 -860 0 0 {name=l39 lab=GND}
C {devices/gnd.sym} 1620 -860 0 0 {name=l3 lab=GND}
C {lab_pin.sym} 1220 -1000 0 0 {name=p1 sig_type=std_logic lab=v4}
C {devices/gnd.sym} 1820 -860 0 0 {name=l1 lab=GND}
C {lab_pin.sym} 1020 -1080 0 0 {name=p2 sig_type=std_logic lab=v1}
C {devices/gnd.sym} 1060 -860 0 1 {name=l4 lab=GND}
C {sparx_blc_le.sym} 1440 -1040 0 0 {name=x1}
C {res.sym} 1260 -930 0 0 {name=R1
value=50
footprint=1206
device=resistor
m=1}
C {res.sym} 1620 -930 0 0 {name=R2
value=50
footprint=1206
device=resistor
m=1}
C {res.sym} 1820 -930 0 0 {name=R3
value=50
footprint=1206
device=resistor
m=1}
