# SPDX-FileCopyrightText: 2025-2026 The SPARX Team
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
import argparse
from math import sqrt
from pathlib import Path

import gdsfactory as gf
import ihp
import scipy.constants
import gds2palace

ihp.PDK.activate()

DEFAULT_FREQUENCY = 160e9
DEFAULT_SIGNAL_CROSS_SECTION = "TM2"
DEFAULT_GROUND_CROSS_SECTION = "M5"
DEFAULT_Z0 = 50
DEFAULT_E_R = 4.1

GDS_DIR = Path(__file__).resolve().parent.parent / "layout"

parser = argparse.ArgumentParser(description="EM simulation of the assembled six-port core")
parser.add_argument("--frequency", type=float, default=DEFAULT_FREQUENCY, help="Frequency in Hz")
parser.add_argument("--signal_cross_section", type=str, default=DEFAULT_SIGNAL_CROSS_SECTION, help="Cross section for signal line")
parser.add_argument("--ground_cross_section", type=str, default=DEFAULT_GROUND_CROSS_SECTION, help="Cross section for ground line")
parser.add_argument("--Z0", type=float, default=DEFAULT_Z0, help="Characteristic impedance in Ohms")
parser.add_argument("--e_r", type=float, default=DEFAULT_E_R, help="Relative permittivity of the substrate")
args = parser.parse_args()

layer_dict = {
    "TM2": "topmetal2_routing",
    "TM1": "topmetal1_routing",
    "M5": "metal5_routing",
    "M4": "metal4_routing",
    "M3": "metal3_routing",
    "M2": "metal2_routing",
    "M1": "metal1_routing",
}

signal_cross_section = layer_dict[args.signal_cross_section]
ground_cross_section = layer_dict[args.ground_cross_section]


def snap_to_grid(value: float) -> float:
    """Snap a length in um down to the nearest PDK grid point."""
    return round(value - value % ihp.tech.nm, 3)


# ============================================================
# Design parameters, must match six_port_gen.py so the core
# reflects the six-port network of the actual chip layout
# ============================================================

e_r = args.e_r  # relative permittivity
Z0 = args.Z0  # characteristic impedance
f = args.frequency  # frequency

CORNER_Z_FACTOR = 1.314  # impedance scaling for tline corners

# calculate effective dielectric constant and wavelength
e_eff = ihp.cells.waveguides._calculate_effective_dielectric_constant(
    signal_cross_section=signal_cross_section, ground_cross_section=ground_cross_section, e_r=e_r
)

c0 = scipy.constants.c  # speed of light
wavelength = c0 / f * 1e6 / sqrt(e_eff)  # wavelength
wavelength_4 = wavelength / 4  # quarter wavelength

wavelength = snap_to_grid(wavelength)
wavelength_4 = snap_to_grid(wavelength_4)  # quarter wavelength snap to grid

# filter parameters
order = 3  # order of the band pass filter
bandwidth = 1e9  # 1GHz bandwidth for input band pass filter
filter_type = "butter"  # type of the band pass filter, can be "butter", "cheby",
connection_length_bpf = 10  # length of the connection piece between the band pass filter and the rest of the circuit
ripple_dB = 3  # ripple in dB for the cheby filter, ignored if the filter type is Butter

# wilkinson power divider parameters
connection_length_wpd = 0  # length of the connection piece of the wilkinson power divider ports
connection_length_bpf_wpd = (
    wavelength_4 * 3.5 / 5
)  # length of the connection piece between the branch line couplers and the rest of the circuit
connection_length_bpf_wpd = snap_to_grid(connection_length_bpf_wpd)

# branch line coupler parameters
connection_length_blc = 0  # length of the connection piece between the branch line couplers and the rest of the circuit


# ============================================================
# Six-port network assembly (as in six_port_gen.py)
# ============================================================

c = gf.Component("sparx_core_em_sim")

blc = ihp.cells.branch_line_coupler(
    frequency=f,
    connection_length=connection_length_blc,
    signal_cross_section=signal_cross_section,
    ground_cross_section=ground_cross_section,
    Z0=Z0,
    e_r=e_r,
)

blc_1_ref = c.add_ref(blc)

blc_2_ref = c.add_ref(blc)

blc_3_ref = c.add_ref(blc)

corner = ihp.cells.tline_corner(
    signal_cross_section=signal_cross_section,
    ground_cross_section=ground_cross_section,
    Z0=Z0 * CORNER_Z_FACTOR,
)

corner_top_ref = c.add_ref(corner)
corner_bot_ref = c.add_ref(corner)

blc_3_ref.center = (0, 0)
corner_top_ref.connect("e1", blc_3_ref.ports["e1"], allow_width_mismatch=True)

blc_1_ref.connect("e4", corner_top_ref.ports["e4"], allow_width_mismatch=True)

corner_bot_ref.connect("e1", blc_3_ref.ports["e4"], allow_width_mismatch=True)

blc_2_ref.connect("e1", corner_bot_ref.ports["e2"], allow_width_mismatch=True)


wpd = ihp.cells.wilkinson_power_divider(
    frequency=f,
    connection_length=connection_length_wpd,
    signal_cross_section=signal_cross_section,
    ground_cross_section=ground_cross_section,
    Z0=Z0,
    e_r=e_r,
    shape="U",
)

wpd.ports["e1"].orientation = 0
wpd_ref = c.add_ref(wpd)


connection_length_wpd_blc_one_leg = (
    blc_1_ref.ports["e1"].center[1]
    - blc_2_ref.ports["e4"].center[1]
    - (wpd_ref.ports["e2"].center[1] - wpd_ref.ports["e3"].center[1])
)


connection_wpd_blc = ihp.cells.tline(
    length=snap_to_grid(connection_length_wpd_blc_one_leg / 2) + ihp.tech.nm,  # one grid step of margin
    signal_cross_section=signal_cross_section,
    ground_cross_section=ground_cross_section,
    Z0=Z0,
)

connection_wpd_blc_top_ref = c.add_ref(connection_wpd_blc)
connection_wpd_blc_top_ref.connect("e1", blc_1_ref.ports["e1"])


wpd_ref.connect("e3", connection_wpd_blc_top_ref.ports["e2"])

connection_wpd_blc_bot_ref = c.add_ref(connection_wpd_blc)
connection_wpd_blc_bot_ref.connect("e1", blc_2_ref.ports["e4"])

wpd_ref.connect("e2", connection_wpd_blc_bot_ref.ports["e2"])

connection_bpf_wpd = c.add_ref(
    ihp.cells.tline(
        length=connection_length_bpf_wpd,
        signal_cross_section=signal_cross_section,
        ground_cross_section=ground_cross_section,
        Z0=Z0,
    )
)

connection_bpf_wpd.connect("e1", wpd_ref.ports["e1"])


bandpass_filter = c.add_ref(
    ihp.cells.hairpin_coupled_line_bandpass_filter(
        frequency=f,
        bandwidth=bandwidth,
        order=order,
        filter_type=filter_type,
        ripple_dB=ripple_dB,
        connection_length=connection_length_bpf,
        signal_cross_section=signal_cross_section,
        ground_cross_section=ground_cross_section,
        Z0=Z0,
        e_r=e_r,
    )
)

bandpass_filter.connect("e1", connection_bpf_wpd.ports["e2"])


# ============================================================
# Palace port markers (layers 201-207)
# ============================================================

port1 = c.add_ref(gf.components.rectangle(size=(0.1, bandpass_filter.ports["e2"].width), layer=(201,0)))
port1.center = (bandpass_filter.ports["e2"].center)
port1.move((0.05,0))

port2 = c.add_ref(gf.components.rectangle(size=(0.1, blc_3_ref.ports["e2"].width), layer=(202,0)))
port2.center = (blc_3_ref.ports["e2"].center)
port2.move((-0.05,0))

port3 = c.add_ref(gf.components.rectangle(size=(blc_1_ref.ports["e2"].width, 0.1), layer=(203,0)))
port3.center = (blc_1_ref.ports["e2"].center)
port3.move((0, -0.05))

port4 = c.add_ref(gf.components.rectangle(size=(blc_1_ref.ports["e3"].width, 0.1), layer=(204,0)))
port4.center = (blc_1_ref.ports["e3"].center)
port4.move((0, -0.05))

port5 = c.add_ref(gf.components.rectangle(size=(blc_2_ref.ports["e2"].width, 0.1), layer=(205,0)))
port5.center = (blc_2_ref.ports["e2"].center)
port5.move((0, 0.05))

port6 = c.add_ref(gf.components.rectangle(size=(blc_2_ref.ports["e3"].width, 0.1), layer=(206,0)))
port6.center = (blc_2_ref.ports["e3"].center)
port6.move((0, 0.05))

port7 = c.add_ref(gf.components.rectangle(size=(0.1, blc_3_ref.ports["e3"].width), layer=(207,0)))
port7.center = (blc_3_ref.ports["e3"].center)
port7.move((-0.05,0))


c.xmin = 0
c.ymin = 0
filename = f"sparx{args.frequency / 1e9:.0f}_core.gds"
gds_path = GDS_DIR / filename
# c.show()
c.write_gds(str(gds_path), with_metadata=False)
