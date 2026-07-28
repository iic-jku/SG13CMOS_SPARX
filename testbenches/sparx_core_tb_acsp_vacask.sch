v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
B 4 390 -440 530 -260 {fill = false}
B 4 630 -440 770 -260 {fill = false}
B 4 870 -440 1010 -260 {fill = false}
B 4 1110 -440 1250 -260 {fill = false}
B 4 1350 -440 1490 -260 {fill = false}
B 4 1590 -440 1730 -260 {fill = false}
B 4 1830 -440 1970 -260 {fill = false}
T {VACASK Testbench for AC S-parameter analysis - Six-Port Core} 390 -1705 0 0 1 1 {}
T {Port 1} 395 -435 0 0 0.3 0.3 {}
T {Port 2} 635 -435 0 0 0.3 0.3 {}
T {Port 3} 875 -435 0 0 0.3 0.3 {}
T {Port 4} 1115 -435 0 0 0.3 0.3 {}
T {Port 5} 1355 -435 0 0 0.3 0.3 {}
T {Port 6} 1595 -435 0 0 0.3 0.3 {}
T {Port 7} 1835 -435 0 0 0.3 0.3 {}
T {SPDX-FileCopyrightText: 2025-2026 The SPARX Team
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
} 600 -60 0 0 0.4 0.4 {}
N 460 -460 460 -420 {lab=v1}
N 460 -360 460 -340 {lab=#net1}
N 460 -280 460 -240 {lab=GND}
N 700 -460 700 -420 {lab=v2}
N 700 -360 700 -340 {lab=#net2}
N 700 -280 700 -240 {lab=GND}
N 940 -460 940 -420 {lab=v3}
N 940 -360 940 -340 {lab=#net3}
N 940 -280 940 -240 {lab=GND}
N 1180 -460 1180 -420 {lab=v4}
N 1180 -360 1180 -340 {lab=#net4}
N 1180 -280 1180 -240 {lab=GND}
N 1420 -460 1420 -420 {lab=v5}
N 1420 -360 1420 -340 {lab=#net5}
N 1420 -280 1420 -240 {lab=GND}
N 1660 -460 1660 -420 {lab=v6}
N 1660 -360 1660 -340 {lab=#net6}
N 1660 -280 1660 -240 {lab=GND}
N 1900 -460 1900 -420 {lab=v7}
N 1900 -360 1900 -340 {lab=#net7}
N 1900 -280 1900 -240 {lab=GND}
N 1120 -960 1120 -920 {lab=v3}
N 1200 -960 1200 -920 {lab=v4}
N 1200 -720 1200 -680 {lab=v5}
N 1120 -720 1120 -680 {lab=v6}
N 1000 -820 1040 -820 {lab=v1}
N 1280 -860 1320 -860 {lab=v2}
N 1280 -780 1320 -780 {lab=v7}
C {title-3.sym} 0 0 0 0 {name=l2 author="Simon Dorrer" rev=1.0 lock=true}
C {simulator_commands_shown.sym} 60 -1310 0 0 {name=Script_VACASK
simulator=vacask
only_toplevel=false
value="
control
  // User Constants
  // f_min / f_max are auto-synced to the loaded Touchstone by snp2le (sim_range.inc).
  // edit that file (or this include) for a standalone run.
  include \\"../sim_range.inc\\"

  // AC S-parameter sweep across the sim_range.
  analysis sp1 acsp ports=[\\"V1\\", \\"R1\\", \\"V2\\", \\"R2\\", \\"V3\\", \\"R3\\", \\"V4\\", \\"R4\\", \\"V5\\", \\"R5\\", \\"V6\\", \\"R6\\", \\"V7\\", \\"R7\\"] from=f_min to=f_max mode=\\"lin\\" points=1001

  postprocess(PYTHON, \\"../plot_simulations/plot_n_port_tb_acsp_vacask.py\\")
endc
"}
C {simulator_commands_shown.sym} 1680 -1235 0 0 {name=Libs_VACASK
simulator=vacask
only_toplevel=false
value="
// resistor + vsource models/loads are auto-emitted by the R1..R7/V1..V7 symbols.
// only declare the device types that appear inside the included .inc.
model capacitor capacitor
model inductor inductor
model vccs vccs
model cccs cccs
load \\"capacitor.osdi\\"
load \\"inductor.osdi\\"
include \\"../../netlist/spectre/sparx_bpf_le.inc\\"
include \\"../../netlist/spectre/sparx_wpd_le.inc\\"
include \\"../../netlist/spectre/sparx_blc_le.inc\\"
"}
C {launcher.sym} 1740 -1340 0 0 {name=h1
descr="Simulate VACASK"
tclcommand="
# Setup the default simulation commands if not already set up
# for example by already launched simulations.
set_sim_defaults
puts $sim(spectre,0,cmd)

# change the simulator to be used (#0 in spectre category is VACASK)
set sim(spectre,default) 0
xschem set netlist_type spectre

# Create FET and BIP .save file
mkdir -p $netlist_dir
write_data [save_params] $netlist_dir/[file rootname [file tail [xschem get current_name]]].save

# run netlist and simulation
xschem netlist
simulate
"}
C {devices/lab_pin.sym} 460 -460 1 0 {name=lp1 sig_type=std_logic lab=v1}
C {devices/res.sym} 460 -390 0 0 {name=R1 value=50}
C {vsource.sym} 460 -310 0 0 {name=V1 value="dc=0 mag=1" savecurrent=false}
C {devices/gnd.sym} 460 -240 0 1 {name=g1 lab=GND}
C {devices/lab_pin.sym} 700 -460 1 0 {name=lp2 sig_type=std_logic lab=v2}
C {devices/res.sym} 700 -390 0 0 {name=R2 value=50}
C {vsource.sym} 700 -310 0 0 {name=V2 value="dc=0 mag=1" savecurrent=false}
C {devices/gnd.sym} 700 -240 0 1 {name=g2 lab=GND}
C {devices/lab_pin.sym} 940 -460 1 0 {name=lp3 sig_type=std_logic lab=v3}
C {devices/res.sym} 940 -390 0 0 {name=R3 value=50}
C {vsource.sym} 940 -310 0 0 {name=V3 value="dc=0 mag=1" savecurrent=false}
C {devices/gnd.sym} 940 -240 0 1 {name=g3 lab=GND}
C {devices/lab_pin.sym} 1180 -460 1 0 {name=lp4 sig_type=std_logic lab=v4}
C {devices/res.sym} 1180 -390 0 0 {name=R4 value=50}
C {vsource.sym} 1180 -310 0 0 {name=V4 value="dc=0 mag=1" savecurrent=false}
C {devices/gnd.sym} 1180 -240 0 1 {name=g4 lab=GND}
C {devices/lab_pin.sym} 1420 -460 1 0 {name=lp5 sig_type=std_logic lab=v5}
C {devices/res.sym} 1420 -390 0 0 {name=R5 value=50}
C {vsource.sym} 1420 -310 0 0 {name=V5 value="dc=0 mag=1" savecurrent=false}
C {devices/gnd.sym} 1420 -240 0 1 {name=g5 lab=GND}
C {devices/lab_pin.sym} 1660 -460 1 0 {name=lp6 sig_type=std_logic lab=v6}
C {devices/res.sym} 1660 -390 0 0 {name=R6 value=50}
C {vsource.sym} 1660 -310 0 0 {name=V6 value="dc=0 mag=1" savecurrent=false}
C {devices/gnd.sym} 1660 -240 0 1 {name=g6 lab=GND}
C {devices/lab_pin.sym} 1900 -460 1 0 {name=lp7 sig_type=std_logic lab=v7}
C {devices/res.sym} 1900 -390 0 0 {name=R7 value=50}
C {vsource.sym} 1900 -310 0 0 {name=V7 value="dc=0 mag=1" savecurrent=false}
C {devices/gnd.sym} 1900 -240 0 1 {name=g7 lab=GND}
C {devices/lab_pin.sym} 1000 -820 0 0 {name=lv1 sig_type=std_logic lab=v1}
C {devices/lab_pin.sym} 1320 -860 0 1 {name=lv2 sig_type=std_logic lab=v2}
C {devices/lab_pin.sym} 1120 -960 1 0 {name=lv3 sig_type=std_logic lab=v3}
C {devices/lab_pin.sym} 1200 -960 1 0 {name=lv4 sig_type=std_logic lab=v4}
C {devices/lab_pin.sym} 1200 -680 3 0 {name=lv5 sig_type=std_logic lab=v5}
C {devices/lab_pin.sym} 1120 -680 3 0 {name=lv6 sig_type=std_logic lab=v6}
C {devices/lab_pin.sym} 1320 -780 0 1 {name=lv7 sig_type=std_logic lab=v7}
C {sparx_core.sym} 1160 -820 0 0 {name=x1}
