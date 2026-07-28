v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
B 4 1360 -700 1500 -520 {fill = false}
B 4 940 -700 1080 -520 {fill = false}
B 4 1600 -700 1740 -520 {fill = false}
B 4 700 -700 840 -520 {fill = false}
T {VACASK Testbench for AC S-parameter analysis - Branch Line Coupler} 290 -1715 0 0 1 1 {}
T {Port 3} 1495 -695 0 1 0.3 0.3 {}
T {Port 4} 945 -695 0 0 0.3 0.3 {}
T {Port 2} 1735 -695 0 1 0.3 0.3 {}
T {Port 1} 705 -695 0 0 0.3 0.3 {}
T {SPDX-FileCopyrightText: 2025-2026 The SPARX Team
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
} 1920 -220 0 0 0.4 0.4 {}
N 1400 -620 1400 -600 {lab=#net1}
N 1400 -540 1400 -500 {lab=GND}
N 1400 -720 1400 -680 {lab=v3}
N 1320 -720 1400 -720 {lab=v3}
N 1400 -720 1480 -720 {lab=v3}
N 1040 -620 1040 -600 {lab=#net2}
N 1040 -540 1040 -500 {lab=GND}
N 1040 -720 1040 -680 {lab=v4}
N 1640 -800 1720 -800 {lab=v2}
N 1640 -620 1640 -600 {lab=#net3}
N 1640 -540 1640 -500 {lab=GND}
N 1040 -720 1120 -720 {lab=v4}
N 800 -620 800 -600 {lab=#net4}
N 800 -540 800 -500 {lab=GND}
N 720 -800 800 -800 {lab=v1}
N 800 -800 800 -680 {lab=v1}
N 800 -800 1120 -800 {lab=v1}
N 960 -720 1040 -720 {lab=v4}
N 1640 -800 1640 -680 {lab=v2}
N 1320 -800 1640 -800 {lab=v2}
C {title-3.sym} 0 0 0 0 {name=l2 author="Simon Dorrer" rev=1.0 lock=true}
C {simulator_commands_shown.sym} 100 -1350 0 0 {name=Script_VACASK
simulator=vacask
only_toplevel=false
value="
control
  // User Constants
  // f_min / f_max are auto-synced to the loaded Touchstone by snp2le (sim_range.inc).
  // edit that file (or this include) for a standalone run.
  include \\"../sim_range.inc\\"

  // AC S-parameter sweep across the sim_range.
  analysis sp1 acsp ports=[\\"V1\\", \\"R1\\", \\"V2\\", \\"R2\\", \\"V3\\", \\"R3\\", \\"V4\\", \\"R4\\"] from=f_min to=f_max mode=\\"lin\\" points=1001

  postprocess(PYTHON, \\"../plot_simulations/plot_n_port_tb_acsp_vacask.py\\")
endc
"}
C {simulator_commands_shown.sym} 1640 -1330 0 0 {name=Libs_VACASK
simulator=vacask
only_toplevel=false
value="
// resistor + vsource models/loads are auto-emitted by the R1/R2/V1/V2 symbols.
// only declare the device types that appear inside the included .inc.
model capacitor capacitor
model inductor inductor
model vccs vccs
model cccs cccs
load \\"capacitor.osdi\\"
load \\"inductor.osdi\\"
include \\"../../netlist/spectre/sparx_blc_le.inc\\"
"}
C {launcher.sym} 1380 -1330 0 0 {name=h1
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
C {devices/lab_pin.sym} 1480 -720 0 1 {name=lvout sig_type=std_logic lab=v3}
C {devices/res.sym} 1400 -650 0 0 {name=R3 value=50}
C {devices/gnd.sym} 1400 -500 0 1 {name=g3 lab=GND}
C {vsource.sym} 1400 -570 0 0 {name=V3 value="dc=0 mag=1" savecurrent=false}
C {devices/lab_pin.sym} 960 -720 0 0 {name=lvout1 sig_type=std_logic lab=v4}
C {devices/res.sym} 1040 -650 0 1 {name=R4 value=50}
C {devices/gnd.sym} 1040 -500 0 0 {name=g2 lab=GND}
C {vsource.sym} 1040 -570 0 1 {name=V4 value="dc=0 mag=1" savecurrent=false}
C {devices/lab_pin.sym} 1720 -800 0 1 {name=lvout2 sig_type=std_logic lab=v2}
C {devices/res.sym} 800 -650 0 1 {name=R1 value=50}
C {devices/gnd.sym} 1640 -500 0 1 {name=g1 lab=GND}
C {vsource.sym} 800 -570 0 1 {name=V1 value="dc=0 mag=1" savecurrent=false}
C {devices/lab_pin.sym} 720 -800 0 0 {name=lvout3 sig_type=std_logic lab=v1}
C {devices/res.sym} 1640 -650 0 0 {name=R2 value=50}
C {devices/gnd.sym} 800 -500 0 0 {name=g4 lab=GND}
C {vsource.sym} 1640 -570 0 0 {name=V2 value="dc=0 mag=1" savecurrent=false}
C {sparx_blc_le.sym} 1220 -760 0 0 {name=x1}
