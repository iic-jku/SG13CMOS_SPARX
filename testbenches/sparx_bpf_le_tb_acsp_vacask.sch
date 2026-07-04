v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
B 4 960 -880 1100 -700 {fill = false}
B 4 1380 -880 1520 -700 {fill = false}
T {VACASK Testbench for AC S-parameter analysis - Bandpass Filter} 360 -1715 0 0 1 1 {}
T {Port 1} 965 -875 0 0 0.3 0.3 {}
T {Port 2} 1515 -875 0 1 0.3 0.3 {}
N 1060 -900 1140 -900 {lab=v1}
N 1060 -800 1060 -780 {lab=#net1}
N 1060 -720 1060 -680 {lab=GND}
N 1060 -900 1060 -860 {lab=v1}
N 980 -900 1060 -900 {lab=v1}
N 1420 -800 1420 -780 {lab=#net2}
N 1420 -720 1420 -680 {lab=GND}
N 1420 -900 1420 -860 {lab=v2}
N 1340 -900 1420 -900 {lab=v2}
N 1420 -900 1500 -900 {lab=v2}
C {devices/lab_pin.sym} 980 -900 0 0 {name=lvin sig_type=std_logic lab=v1}
C {devices/lab_pin.sym} 1500 -900 0 1 {name=lvout sig_type=std_logic lab=v2}
C {devices/res.sym} 1060 -830 0 1 {name=R1 value=50}
C {devices/gnd.sym} 1060 -680 0 0 {name=g1 lab=GND}
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
  analysis sp1 acsp ports=[\\"V1\\", \\"R1\\", \\"V2\\", \\"R2\\"] from=f_min to=f_max mode=\\"lin\\" points=1001

  postprocess(PYTHON, \\"../../scripts/n_port_acsp_vacask_eval.py\\")
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
include \\"../../netlist/spectre/sparx_bpf_le.inc\\"
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
C {vsource.sym} 1060 -750 0 1 {name=V1 value="dc=0 mag=1" savecurrent=false}
C {devices/res.sym} 1420 -830 0 0 {name=R2 value=50}
C {devices/gnd.sym} 1420 -680 0 1 {name=g3 lab=GND}
C {vsource.sym} 1420 -750 0 0 {name=V2 value="dc=0 mag=1" savecurrent=false}
C {sparx_bpf_le.sym} 1240 -900 0 0 {name=x1}
