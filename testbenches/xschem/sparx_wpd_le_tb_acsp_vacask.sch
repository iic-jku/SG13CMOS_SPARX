v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
B 4 780 -840 920 -660 {fill = false}
B 4 1440 -840 1580 -660 {fill = false}
B 4 1200 -840 1340 -660 {fill = false}
T {VACASK Testbench for AC S-parameter analysis - Wilkinson Power Divider} 270 -1715 0 0 1 1 {}
T {Port 1} 785 -835 0 0 0.3 0.3 {}
T {Port 2} 1575 -835 0 1 0.3 0.3 {}
T {Port 3} 1335 -835 0 1 0.3 0.3 {}
T {SPDX-FileCopyrightText: 2025-2026 The SPARX Team
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
} 1920 -220 0 0 0.4 0.4 {}
N 880 -900 960 -900 {lab=v1}
N 880 -760 880 -740 {lab=#net1}
N 880 -680 880 -640 {lab=GND}
N 880 -900 880 -820 {lab=v1}
N 800 -900 880 -900 {lab=v1}
N 1480 -760 1480 -740 {lab=#net2}
N 1240 -680 1240 -640 {lab=GND}
N 1240 -860 1240 -820 {lab=v3}
N 1160 -860 1240 -860 {lab=v3}
N 1240 -860 1320 -860 {lab=v3}
N 1240 -760 1240 -740 {lab=#net3}
N 1480 -680 1480 -640 {lab=GND}
N 1480 -940 1560 -940 {lab=#net4}
N 1480 -940 1480 -820 {lab=#net4}
N 1160 -940 1480 -940 {lab=#net4}
C {devices/lab_pin.sym} 800 -900 0 0 {name=lvin sig_type=std_logic lab=v1}
C {devices/lab_pin.sym} 1560 -940 0 1 {name=lvout sig_type=std_logic lab=v2}
C {devices/res.sym} 880 -790 0 1 {name=R1 value=50}
C {devices/gnd.sym} 880 -640 0 0 {name=g1 lab=GND}
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
  analysis sp1 acsp ports=[\\"V1\\", \\"R1\\", \\"V2\\", \\"R2\\", \\"V3\\", \\"R3\\"] from=f_min to=f_max mode=\\"lin\\" points=1001

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
include \\"../../../netlist/spectre/sparx_wpd_le.inc\\"
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
C {vsource.sym} 880 -710 0 1 {name=V1 value="dc=0 mag=1" savecurrent=false}
C {devices/res.sym} 1480 -790 0 0 {name=R2 value=50}
C {devices/gnd.sym} 1240 -640 0 1 {name=g3 lab=GND}
C {vsource.sym} 1480 -710 0 0 {name=V2 value="dc=0 mag=1" savecurrent=false}
C {devices/lab_pin.sym} 1320 -860 0 1 {name=lvout1 sig_type=std_logic lab=v3}
C {devices/res.sym} 1240 -790 0 0 {name=R3 value=50}
C {devices/gnd.sym} 1480 -640 0 1 {name=g2 lab=GND}
C {vsource.sym} 1240 -710 0 0 {name=V3 value="dc=0 mag=1" savecurrent=false}
C {sparx_wpd_le.sym} 1060 -900 0 0 {name=x1}
