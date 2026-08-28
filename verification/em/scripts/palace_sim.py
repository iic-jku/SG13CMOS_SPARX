# SPDX-FileCopyrightText: 2025-2026 The SPARX Team
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
import os
import re
import sys
import subprocess
from gds2palace import *
import gdspy
import argparse


def _parse_args():
    """Parse the command line.

    The EM parameters are normally derived from the GDS file name, which is
    written by scripts/six_port_gen.py. Structures whose file name does not
    encode them (e.g. the six-port core) pass them explicitly instead.
    """
    parser = argparse.ArgumentParser(description="Build and run a Palace model from a GDSII file")
    parser.add_argument("gds_filename", help="GDSII file with the geometry and the port markers")
    parser.add_argument("--f_center", type=float, default=None, help="Center frequency in Hz (default: from the file name)")
    parser.add_argument("--signal_cross_section", type=str, default=None, help="Signal layer name, e.g. TM2 (default: from the file name)")
    parser.add_argument("--ground_cross_section", type=str, default=None, help="Ground layer name, e.g. M5 (default: from the file name)")
    parser.add_argument("--Z0", type=float, default=None, help="Reference impedance of the ports in Ohms (default: from the file name)")
    parser.add_argument("--stackup", type=str, default="SG13G2_nosub.xml",
                        help="Stackup XML, either a bare name resolved against the PDK's "
                             "libs.tech/palace/workflow, or a path (default: SG13G2_nosub.xml)")
    return parser.parse_args()


def _resolve_stackup(stackup):
    """Resolve the stackup XML, preferring an explicit path over the PDK's copy.

    The stackup files are not vendored in this repository. They ship with the PDK,
    in the gds2palace submodule the container installs, so the model always uses the
    same stackup as the gds2palace that reads it. See verification/em/stackups/README.md.
    """
    if os.path.sep in stackup or (os.path.altsep and os.path.altsep in stackup):
        path = os.path.abspath(stackup)
        if not os.path.isfile(path):
            raise SystemExit(f"ERROR: stackup not found: {path}")
        return path

    pdk_root = os.environ.get("PDK_ROOT")
    if not pdk_root:
        raise SystemExit(
            "ERROR: PDK_ROOT is not set, so the stackup cannot be resolved. Run inside "
            "IIC-OSIC-TOOLS, or pass a path with --stackup."
        )
    pdk = os.environ.get("PDK", "ihp-sg13g2")
    path = os.path.join(pdk_root, pdk, "libs.tech", "palace", "workflow", stackup)
    if not os.path.isfile(path):
        raise SystemExit(
            f"ERROR: stackup not found: {path}" + os.linesep
            + "       The PDK ships them in libs.tech/palace/workflow. "
              "Check PDK_ROOT/PDK, or pass a path with --stackup."
        )
    return path


def _get_number_of_ports(gds_filename):
    """Get the number of ports from a GDSII file by counting layers with layer number > 200."""
    lib = gdspy.GdsLibrary()
    lib.read_gds(gds_filename)
    cell = lib.top_level()[0]
    layers = _get_layers(cell)
    return sum(1 for layer, _ in layers if layer > 200)


def _get_ghz_from_filename(gds_filename):
    """Extract the integer GHz value from a filename like 'tline_l4_for_10GHz.gds'."""
    base_name = os.path.basename(gds_filename)
    match = re.search(r"(\d+(?:\.\d+)?)\s*GHz", base_name, re.IGNORECASE)
    if not match:
        raise ValueError(f"No GHz value found in filename: {gds_filename}")
    ghz_value = float(match.group(1))
    if not ghz_value.is_integer():
        raise ValueError(f"GHz value must be an integer: {gds_filename}")
    return int(ghz_value)


def _get_layer_names_from_filename(gds_filename):
    """Extract signal and ground layer names from filename.
    
    Returns:
        tuple: (signal_layer, ground_layer) e.g., ('TM2', 'M5')
    
    Raises:
        ValueError: If layer names are not found in filename
    """
    base_name = os.path.basename(gds_filename)
    layer_options = ['TM2', 'TM1', 'M5', 'M4', 'M3', 'M2', 'M1']
    
    # Find all layer names in the filename
    found_layers = []
    for layer in layer_options:
        if layer in base_name:
            found_layers.append(layer)
    
    if len(found_layers) < 2:
        raise ValueError(f"Could not extract both signal and ground layer names from: {gds_filename}")
    
    # First occurrence is signal layer, second is ground layer
    signal_layer = found_layers[0]
    ground_layer = found_layers[1]
    
    return signal_layer, ground_layer


def _get_impedance_from_filename(gds_filename):
    """Extract the impedance value from filename.
    
    The impedance is expected to appear directly before 'Ohm'.
    Example: 'blc_160GHz_50Ohm_TM2_M5_...' extracts 50
    
    Returns:
        float: Impedance value in Ohms
    
    Raises:
        ValueError: If impedance value is not found in filename
    """
    base_name = os.path.basename(gds_filename)
    match = re.search(r"(\d+(?:\.\d+)?)\s*Ohm", base_name, re.IGNORECASE)
    if not match:
        raise ValueError(f"No impedance value found in filename: {gds_filename}")
    impedance = float(match.group(1))
    return impedance

def _get_layers(cell, layers=None):
    """Collect all (layer, datatype) pairs used in a cell, recursively."""
    if layers is None:
        layers = set()
    for poly in cell.polygons:
        for layer, datatype in zip(poly.layers, poly.datatypes):
            layers.add((int(layer), int(datatype)))
    for ref in cell.references:
        _get_layers(ref.ref_cell, layers)
    return layers


# ===================== input files and path settings =======================

args = _parse_args()

gds_filename = args.gds_filename   # geometries
# Stackup, taken from the PDK rather than vendored here, so it always matches the
# gds2palace that reads it. SG13G2_nosub is the default because the solid Metal5 plane
# under the TopMetal2 traces shields the silicon, so leaving the substrate out of the
# model costs almost nothing in accuracy and saves a lot of mesh. The resolved path is
# printed below, because it is the one model input this repository does not pin.
# See verification/em/stackups/README.md for the other stackups and for the
# schemaVersion 3.x caveat.
XML_filename = _resolve_stackup(args.stackup)
print("Stackup: ", XML_filename)

# preprocess GDSII for safe handling of cutouts/holes. No longer required since gds2palace
# redesigned cutout handling in August 2026, kept here so the flow also works with older
# gds2palace versions, where the argument still exists.
preprocess_gds = False

# merge via polygons with distance less than .. microns, set to 0 to disable via merging.
merge_polygon_size = 0

# get path for this simulation file
script_path = utilities.get_script_path(__file__)

# use script filename as model basename
model_basename = str.split(gds_filename.split('/')[-1], ".")[0]

# set and create directory for simulation output
sim_path = utilities.create_sim_path(script_path, model_basename, dirname="../palace_model/")
print('Simulation data directory: ', sim_path)

f_center = args.f_center if args.f_center is not None else _get_ghz_from_filename(gds_filename) * 1e9


# change path to models script path
modelDir = os.path.dirname(os.path.abspath(__file__))
os.chdir(modelDir)

# ======================== simulation settings ================================

settings = {}

settings['unit']   = 1e-6  # geometry is in microns
settings['margin'] = 50    # distance in microns from GDSII geometry boundary to simulation boundary 

settings['fstart']  = f_center * 0.5
settings['fstop']   = f_center * 1.5
settings['fstep']   = f_center * 0.01

settings['refined_cellsize'] = 2  # mesh cell size in conductor region
settings['cells_per_wavelength'] = 10   # how many mesh cells per wavelength, must be 10 or more

settings['meshsize_max'] = 70  # microns, override cells_per_wavelength 
settings['adaptive_mesh_iterations'] = 0

settings['no_gui'] = True  # create files without showing 3D model
# settings['no_gui'] = ('nogui' in sys.argv)  # check if nogui specified on command line, then create files without showing 3D model

# Ports from GDSII Data, polygon geometry from specified special layer
# Excitations can be switched off by voltage=0, those S-parameter will be incomplete then

simulation_ports = simulation_setup.all_simulation_ports()

num_ports = _get_number_of_ports(gds_filename)

print(f"Number of ports found: {num_ports}")

layer_dict = {
    "TM2": "TopMetal2",
    "TM1": "TopMetal1",
    "M5": "Metal5",
    "M4": "Metal4",
    "M3": "Metal3",
    "M2": "Metal2",
    "M1": "Metal1",
}
if args.signal_cross_section and args.ground_cross_section:
    signal_layer, ground_layer = args.signal_cross_section, args.ground_cross_section
else:
    signal_layer, ground_layer = _get_layer_names_from_filename(gds_filename)

port_Z0 = args.Z0 if args.Z0 is not None else _get_impedance_from_filename(gds_filename)

for portnumber in range(1, num_ports + 1):
    simulation_ports.add_port(
        simulation_setup.simulation_port(
            portnumber=portnumber,
            voltage=1,
            port_Z0=port_Z0,
            source_layernum=200 + portnumber,
            from_layername=layer_dict.get(signal_layer),
            to_layername=layer_dict.get(ground_layer),
            direction='z'
        )
    )
 

# ======================== simulation ================================

# get technology stackup data
materials_list, dielectrics_list, metals_list = stackup_reader.read_substrate(XML_filename)
# get list of layers from technology
layernumbers = metals_list.getlayernumbers()
layernumbers.extend(simulation_ports.portlayers)

# read geometries from GDSII, only purpose 0
allpolygons = gds_reader.read_gds(gds_filename, layernumbers, purposelist=[0], metals_list=metals_list, preprocess=preprocess_gds, merge_polygon_size=merge_polygon_size)


########### create model ###########

settings['simulation_ports'] = simulation_ports
settings['materials_list'] = materials_list
settings['dielectrics_list'] = dielectrics_list
settings['metals_list'] = metals_list
settings['layernumbers'] = layernumbers
settings['allpolygons'] = allpolygons
settings['sim_path'] = sim_path
settings['model_basename'] = model_basename


# list of ports that are excited (set voltage to zero in port excitation to skip an excitation!)
excite_ports = simulation_ports.all_active_excitations()
config_name, data_dir = simulation_setup.create_palace(excite_ports, settings)
