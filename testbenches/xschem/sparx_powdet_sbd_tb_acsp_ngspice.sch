v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
T {ngspice needs two ports for sp.
Port 2 is a dummy, only S11 is used.} 1000 -340 0 0 0.3 0.3 {}
T {Ngspice S-Parameter Testbench for SBD-Based Power Detector} 600 -1720 0 0 1 1 {}
T {Vin3 is an RF port: its z0 of 50 Ohm
puts the sp reference plane at rfin,
so S11 and Z_in are those of the
detector input.} 1060 -820 0 0 0.3 0.3 {}
T {SPDX-FileCopyrightText: 2025-2026 The SPARX Team
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
} 1920 -220 0 0 0.4 0.4 {}
N 800 -400 800 -380 {
lab=GND}
N 1080 -480 1240 -480 {lab=rfdummy}
N 1020 -700 1020 -540 {lab=gnd_local}
N 1400 -540 1560 -540 {lab=gnd_local}
N 1400 -1040 1400 -960 {lab=vdd}
N 800 -540 1020 -540 {lab=gnd_local}
N 1560 -880 1560 -660 {lab=ref}
N 800 -620 800 -540 {lab=gnd_local}
N 800 -1040 800 -680 {lab=vdd}
N 1660 -600 1660 -540 {lab=gnd_local}
N 1560 -540 1660 -540 {lab=gnd_local}
N 1560 -600 1560 -540 {lab=gnd_local}
N 1660 -920 1660 -660 {lab=out_cm}
N 1020 -900 1320 -900 {lab=rfin}
N 1400 -840 1400 -540 {lab=gnd_local}
N 1020 -540 1400 -540 {lab=gnd_local}
N 800 -540 800 -460 {lab=gnd_local}
N 1080 -400 1080 -380 {lab=GND}
N 1240 -400 1240 -380 {lab=GND}
N 1240 -480 1240 -460 {lab=rfdummy}
N 1080 -480 1080 -460 {lab=rfdummy}
N 800 -1040 1400 -1040 {lab=vdd}
N 1480 -920 1660 -920 {lab=out_cm}
N 1480 -880 1560 -880 {lab=ref}
N 1020 -900 1020 -760 {lab=rfin}
C {devices/vsource.sym} 800 -430 0 0 {name=Vss value=0}
C {devices/gnd.sym} 800 -380 0 0 {name=l2 lab=GND}
C {devices/lab_pin.sym} 800 -480 0 1 {name=p1 sig_type=std_logic lab=gnd_local}
C {devices/vsource.sym} 1020 -730 0 0 {name=Vin3 value="dc 0 ac 0 portnum 1 z0 50"}
C {devices/lab_pin.sym} 1020 -900 0 0 {name=p4 sig_type=std_logic lab=rfin}
C {devices/code_shown.sym} 2000 -1350 0 0 {name=MODEL only_toplevel=true
format="tcleval( @value )"
value="
.lib cornerDIO.lib dio_tt
.lib cornerMOSlv.lib mos_tt
.lib cornerRES.lib res_typ
.lib cornerCAP.lib cap_typ
"}
C {devices/code_shown.sym} 100 -1330 0 0 {name=NGSPICE only_toplevel=true
value="
.temp 27
.save all
.options savecurrents klu method=gear reltol=1e-3 abstol=1e-12 gmin=1e-12 rshunt=1e14
.control
set num_threads=8
* z0 of the RF port Vin3, the reference of S11
let z0 = 50

op
write @schname\\\\.raw

* write fails after sp, which has none of the device currents savecurrents
* asks for, so the sp vectors are exported with wrdata only
sp lin 101 100G 200G 0

let s11_dB = db(S_1_1)
let s11_deg = cph(S_1_1) * 180/pi
let zin_re = real(z0 * (1 + S_1_1) / (1 - S_1_1))
let zin_im = imag(z0 * (1 + S_1_1) / (1 - S_1_1))
meas sp s11_dB_160G FIND s11_dB AT=160e9
meas sp zin_re_160G FIND zin_re AT=160e9
meas sp zin_im_160G FIND zin_im AT=160e9
plot s11_dB
plot zin_re zin_im

set wr_vecnames
set wr_singlescale
wrdata ../plot_simulations/data/@schname\\\\.txt
+ s11_dB s11_deg zin_re zin_im
.endc
"
}
C {devices/launcher.sym} 1780 -1360 0 0 {name=h2
descr="simulate"
tclcommand="xschem save; xschem netlist; file mkdir $netlist_dir; write_data [save_params] $netlist_dir/[file rootname [file tail [xschem get current_name]]].save; xschem simulate"
}
C {devices/launcher.sym} 1780 -1300 0 0 {name=h3
descr="annotate OP"
tclcommand="set show_hidden_texts 1; xschem annotate_op"
}
C {devices/lab_pin.sym} 1660 -920 0 1 {name=p6 sig_type=std_logic lab=out_cm}
C {devices/vsource.sym} 1080 -430 0 0 {name=Vin1 value="dc 0 ac 0 portnum 2"}
C {devices/lab_pin.sym} 1080 -480 0 0 {name=p7 sig_type=std_logic lab=rfdummy}
C {devices/gnd.sym} 1080 -380 0 0 {name=l5 lab=GND}
C {capa.sym} 1240 -430 0 0 {name=C3
m=1
value=1f}
C {devices/gnd.sym} 1240 -380 0 0 {name=l6 lab=GND}
C {spice_probe.sym} 1020 -900 0 0 {name=p8 attrs=""}
C {spice_probe.sym} 1660 -920 0 0 {name=p9 attrs=""}
C {devices/vsource.sym} 800 -650 0 0 {name=Vdd value=1.5}
C {devices/lab_pin.sym} 1560 -880 0 1 {name=p2 sig_type=std_logic lab=ref}
C {spice_probe.sym} 1560 -880 0 0 {name=p3 attrs=""}
C {capa.sym} 1660 -630 0 0 {name=C1
m=1
value=5p}
C {capa.sym} 1560 -630 0 0 {name=C2
m=1
value=5p}
C {devices/lab_pin.sym} 800 -1040 0 0 {name=p5 sig_type=std_logic lab=vdd}
C {sparx_powdet_sbd_pex.sym} 1400 -1220 0 0 {name=x2
spice_ignore=true}
C {title-3.sym} 0 0 0 0 {name=l4 author="(c) 2026 H. Pretl, ICD@JKU" rev=1.0 lock=true}
C {devices/code_shown.sym} 1710 -1460 0 0 {name=SAVE only_toplevel=true
format="tcleval( @value )"
value="
.include [file rootname [file tail [xschem get schname]]].save
"}
C {sparx_powdet_sbd.sym} 1400 -900 0 0 {name=x1
}
