v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
B 2 30 -660 830 -260 {flags=graph
y1=0.73
y2=0.75
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=2e-09
x2=3e-09
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0`
node="vref1
vref2
vref3
vref4"
color="11 7 12 21"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
B 2 850 -660 1650 -260 {flags=graph
y1=0.71
y2=0.73
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=2e-09
x2=3e-09
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="vout1
vout2
vout3
vout4"
color="11 7 12 21"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
B 2 1670 -660 2470 -260 {flags=graph
y1=-0.0096
y2=-0.007
ypos1=0
ypos2=2
divy=5
subdivy=4
unity=1
x1=2e-09
x2=3e-09
divx=5
subdivx=8
xlabmag=1.0
ylabmag=1.0
node="vout1-vref1; vout1 vref1 -
vout2-vref2; vout2 vref2 -
vout3-vref3; vout3 vref3 -
vout4-vref4; vout4 vref4 -"
color="11 7 12 21"
dataset=-1
unitx=1
logx=0
logy=0
linewidth_mult=4}
T {Ngspice Testbench for Transient analysis - Six-Port LE} 510 -1710 0 0 1 1 {}
T {SPDX-FileCopyrightText: 2025-2026 The SPARX Team
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
} 1920 -220 0 0 0.4 0.4 {}
N 940 -980 940 -940 {lab=GND}
N 1180 -1020 1180 -940 {lab=GND}
N 1260 -1020 1260 -940 {lab=GND}
N 1020 -1200 1060 -1200 {lab=GND}
N 1020 -1120 1020 -940 {lab=GND}
N 1020 -1120 1060 -1120 {lab=GND}
N 1020 -1200 1020 -1120 {lab=GND}
N 940 -1160 1060 -1160 {lab=vlo}
N 940 -1160 940 -1130 {lab=vlo}
N 940 -1070 940 -1040 {lab=lo_src}
N 1500 -980 1500 -940 {lab=GND}
N 1500 -1160 1500 -1130 {lab=vrf}
N 1500 -1070 1500 -1040 {lab=rf_src}
N 1380 -1200 1420 -1200 {lab=GND}
N 1420 -1120 1420 -940 {lab=GND}
N 1380 -1120 1420 -1120 {lab=GND}
N 1420 -1200 1420 -1120 {lab=GND}
N 1380 -1160 1500 -1160 {lab=vrf}
N 1700 -980 1700 -940 {lab=GND}
N 1920 -1080 1920 -1040 {lab=vout1}
N 1920 -980 1920 -940 {lab=GND}
N 1700 -1080 1700 -1040 {lab=VDD}
N 1140 -1020 1140 -980 {lab=vout3}
N 1100 -1020 1100 -1000 {lab=vref3}
N 1300 -1020 1300 -980 {lab=vout4}
N 1340 -1020 1340 -1000 {lab=vref4}
N 1220 -1020 1220 -980 {lab=VDD}
N 1180 -1380 1180 -1300 {lab=GND}
N 1260 -1380 1260 -1300 {lab=GND}
N 1140 -1340 1140 -1300 {lab=vout1}
N 1100 -1320 1100 -1300 {lab=vref1}
N 1300 -1340 1300 -1300 {lab=vout2}
N 1340 -1320 1340 -1300 {lab=vref2}
N 1220 -1340 1220 -1300 {lab=VDD}
N 2040 -1080 2040 -1040 {lab=vout2}
N 2040 -980 2040 -940 {lab=GND}
N 2160 -1080 2160 -1040 {lab=vout3}
N 2160 -980 2160 -940 {lab=GND}
N 2280 -1080 2280 -1040 {lab=vout4}
N 2280 -980 2280 -940 {lab=GND}
N 1920 -870 1920 -830 {lab=vref1}
N 1920 -770 1920 -730 {lab=GND}
N 2040 -870 2040 -830 {lab=vref2}
N 2040 -770 2040 -730 {lab=GND}
N 2160 -870 2160 -830 {lab=vref3}
N 2160 -770 2160 -730 {lab=GND}
N 2280 -870 2280 -830 {lab=vref4}
N 2280 -770 2280 -730 {lab=GND}
C {devices/code_shown.sym} 60 -1530 0 0 {name=NGSPICE
only_toplevel=true
lock=false
value="
.include ../../../netlist/spice/sparx_core_le.spice
.include ../sim_range.spice
.temp 27
.options savecurrents klu method=gear reltol=1e-3 abstol=1e-15 gmin=1e-15 interp
.control

save all

set wr_vecnames
set wr_singlescale

* User Constants
* LO +12 dBm and RF -20 dBm available at the pads: both sources sit behind 50 Ohm,
* so a source amplitude a is an available power a^2 / (8 * 50), 2.52 V and 63.2 mV.
* +12 dBm at the LO pad puts about -6.5 dBm on each detector behind the 16 to 18 dB
* of the LO path, the operating point of the detector benches.
* 3 ns of transient with the integrator step capped at 20 fs (tmax): the LTE control alone
* lets Gear take 0.3 ps steps on the 161 GHz carrier and damps it, the IF outputs then
* come out 12 times too small. interp writes the output on the 1 ps grid of tstep, without it
* every accepted step of the 161 GHz carrier lands in the rawfile (500 MB for 15 ns).
* f_min / f_max come from ../sim_range.spice (.csparam),
* auto-synced to the loaded Touchstone by snp2le.
* edit that file for a standalone run.

* Operating Point Analysis
op
remzerovec
write @schname\\\\.raw
set appendwrite

* Transient Analysis
tran 1p 10n 0 20f
remzerovec
write @schname\\\\.raw
set appendwrite

* Plotting
plot vref1 vref2 vref3 vref4
plot vout1 vout2 vout3 vout4

* Write Data
unset appendwrite
set wr_vecnames
set wr_singlescale
wrdata ../plot_simulations/data/@schname\\\\.txt
+ vref1 vref2 vref3 vref4
+ vout1 vout2 vout3 vout4

*quit
.endc
"}
C {title-3.sym} 0 0 0 0 {name=l2 author="Simon Dorrer" rev=1.0 lock=true}
C {devices/launcher.sym} 1820 -1440 0 0 {name=h2
descr="Simulate" 
tclcommand="xschem save; xschem netlist; file mkdir $netlist_dir; write_data [save_params] $netlist_dir/[file rootname [file tail [xschem get current_name]]].save; xschem simulate"
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
C {devices/vsource.sym} 940 -1010 0 1 {name=vlo spice_ignore=False value="sin(0 2.52 159G)"
}
C {lab_pin.sym} 1140 -980 0 0 {name=p4 sig_type=std_logic lab=vout3}
C {devices/gnd.sym} 1180 -940 0 1 {name=l5 lab=GND}
C {devices/gnd.sym} 1260 -940 0 0 {name=l7 lab=GND}
C {devices/gnd.sym} 940 -940 0 1 {name=l6 lab=GND}
C {devices/res.sym} 940 -1100 0 0 {name=Rlo value=50}
C {devices/lab_pin.sym} 940 -1070 0 0 {name=pl1 sig_type=std_logic lab=lo_src}
C {devices/res.sym} 1500 -1100 0 0 {name=Rrf value=50}
C {devices/lab_pin.sym} 1500 -1070 0 0 {name=pl2 sig_type=std_logic lab=rf_src}
C {devices/vsource.sym} 1500 -1010 0 0 {name=vrf spice_ignore=False value="sin(0 63.2m 161G)"
}
C {devices/gnd.sym} 1020 -940 0 1 {name=l3 lab=GND}
C {devices/gnd.sym} 1500 -940 0 0 {name=l4 lab=GND}
C {devices/gnd.sym} 1420 -940 0 0 {name=l10 lab=GND}
C {devices/vsource.sym} 1700 -1010 0 0 {name=VDD spice_ignore=False value=1.5
}
C {devices/gnd.sym} 1700 -940 0 0 {name=l1 lab=GND}
C {capa.sym} 1920 -1010 0 1 {name=C1
m=1
value=5p
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 1920 -940 0 0 {name=l11 lab=GND}
C {vdd.sym} 1700 -1080 0 0 {name=l12 lab=VDD}
C {lab_pin.sym} 940 -1160 0 0 {name=p1 sig_type=std_logic lab=vlo}
C {lab_pin.sym} 1500 -1160 0 1 {name=Vrf1 sig_type=std_logic lab=vrf}
C {lab_pin.sym} 1100 -1000 0 0 {name=p2 sig_type=std_logic lab=vref3}
C {lab_pin.sym} 1300 -980 0 1 {name=p3 sig_type=std_logic lab=vout4}
C {lab_pin.sym} 1340 -1000 0 1 {name=p5 sig_type=std_logic lab=vref4}
C {vdd.sym} 1220 -980 2 0 {name=l14 lab=VDD}
C {lab_pin.sym} 1140 -1340 2 1 {name=p6 sig_type=std_logic lab=vout1}
C {devices/gnd.sym} 1180 -1380 2 0 {name=l8 lab=GND}
C {devices/gnd.sym} 1260 -1380 2 1 {name=l9 lab=GND}
C {lab_pin.sym} 1100 -1320 2 1 {name=p7 sig_type=std_logic lab=vref1}
C {lab_pin.sym} 1300 -1340 2 0 {name=p8 sig_type=std_logic lab=vout2}
C {lab_pin.sym} 1340 -1320 2 0 {name=p9 sig_type=std_logic lab=vref2}
C {vdd.sym} 1220 -1340 0 1 {name=l13 lab=VDD}
C {capa.sym} 2040 -1010 0 1 {name=C2
m=1
value=5p
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 2040 -940 0 0 {name=l15 lab=GND}
C {capa.sym} 2160 -1010 0 1 {name=C3
m=1
value=5p
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 2160 -940 0 0 {name=l16 lab=GND}
C {capa.sym} 2280 -1010 0 1 {name=C4
m=1
value=5p
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 2280 -940 0 0 {name=l17 lab=GND}
C {lab_pin.sym} 1920 -1080 2 1 {name=p10 sig_type=std_logic lab=vout1}
C {lab_pin.sym} 2040 -1080 2 1 {name=p11 sig_type=std_logic lab=vout2}
C {lab_pin.sym} 2160 -1080 0 0 {name=p12 sig_type=std_logic lab=vout3}
C {lab_pin.sym} 2280 -1080 0 0 {name=p13 sig_type=std_logic lab=vout4}
C {capa.sym} 1920 -800 0 1 {name=C5
m=1
value=5p
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 1920 -730 0 0 {name=l18 lab=GND}
C {lab_pin.sym} 1920 -870 0 0 {name=p14 sig_type=std_logic lab=vref1}
C {capa.sym} 2040 -800 0 1 {name=C6
m=1
value=5p
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 2040 -730 0 0 {name=l19 lab=GND}
C {lab_pin.sym} 2040 -870 0 0 {name=p15 sig_type=std_logic lab=vref2}
C {capa.sym} 2160 -800 0 1 {name=C7
m=1
value=5p
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 2160 -730 0 0 {name=l20 lab=GND}
C {lab_pin.sym} 2160 -870 0 0 {name=p16 sig_type=std_logic lab=vref3}
C {capa.sym} 2280 -800 0 1 {name=C8
m=1
value=5p
footprint=1206
device="ceramic capacitor"}
C {devices/gnd.sym} 2280 -730 0 0 {name=l21 lab=GND}
C {lab_pin.sym} 2280 -870 0 0 {name=p17 sig_type=std_logic lab=vref4}
C {sparx_top_le.sym} 1220 -1160 0 0 {name=x1}
C {devices/code_shown.sym} 1750 -1540 0 0 {name=SAVE only_toplevel=true
format="tcleval( @value )"
value="
.include [file rootname [file tail [xschem get schname]]].save
"}
