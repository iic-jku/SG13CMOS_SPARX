# Measurements

How SPARX is measured on the lab's wafer prober, and with which equipment.

- The LO and RF pads are probed on the wafer prober with GSG probes.
- The supply and power detector pads are bonded to the probe board in [`pcb/`](../pcb/), and the detector outputs are read with a differential probe on the board or through its SMAs on an oscilloscope. [`pcb/README.md`](../pcb/README.md) is the board contract.

## Equipment

| Function | Equipment | Key data |
| --- | --- | --- |
| VNA that drives the converters | R&S ZVT20 | 10 MHz to 20 GHz, up to six ports and three internal sources (options) |
| LO source | R&S ZTXR170 mmWave transceiver | up to 170 GHz, WM-1651 test port, +9 dBm typical output |
| RF source | OML V06VNA2-T/R VNA extension module (two) | 110 to 170 GHz, WR-06 (UG-387/U-M) test port, −15 to −10 dBm output |
| Receiver | RPG ZRX170 mmWave receiver | 110 to 170 GHz, WM-1651 (WR-6.5) test port, for transmission measurements with a converter or transceiver as source |
| GSG probes for SPARX | GGB Picoprobe 170-GSG-100-BT-M (two) | 110 to 170 GHz, WR-6 input, GSG at 100 µm pitch, bias-T |
| Other probes | MPI TITAN T145MA-GSG0100 and T145MS-GSGSG0100 | DC to 145 GHz, 0.8 mm connector, GSG and GSGSG at 100 µm pitch, below the SPARX band |

Data sheets: [R&S ZVT](https://scdn.rohde-schwarz.com/ur/pws/dl_downloads/dl_common_library/dl_brochures_and_datasheets/pdf_1/ZVT_dat-sw_en_0758-0651-22_v1300.pdf), [R&S ZTXRxxx](https://www.rohde-schwarz.com/us/products/test-and-measurement/mmwave-converters/rs-ztxrxxx-mmwave-transceivers_334322.html), [RPG ZRXxxx](https://scdn.rohde-schwarz.com/ur/pws/dl_downloads/dl_common_library/dl_brochures_and_datasheets/pdf_1/ZRXxxx_dat-sw_en_3683-3865-22_v0200.pdf), [OML VxxVNA2](https://www.omlinc.com/images/pdf/VxxVNA2/OML-VxxVNA2_Brochure.pdf), [GGB Model 170](https://ggb.com/products/model-170/) with its [drawing](https://ggb.com/wp-content/uploads/2025/04/mod170.pdf), [MPI TITAN mmW probes](https://www.mpi-corporation.com/wp-content/uploads/ASTPDF/MPI-TITAN%E2%84%A2-Probe-Family-for-mmWave-Applications-Data-Sheet.pdf).
The OML output power is taken from a distributor listing of OML's brochure, and GGB publishes no loss figure for the Model 170.

## Probes on the SPARX pads

- Only the GGB probes reach the 160 GHz of the taped-out chip. The MPI probes stop at 145 GHz.
- The SPARX GSG pads have 125 µm pitch, the probes 100 µm. In the taped-out GDS (`release/v.1.0.0/gds/RFFE6027.gds`) the passivation openings measure 60.8 × 60.8 µm for the signal pad and 80.8 × 115.8 µm (LO) or 80.8 × 120.8 µm (RF) for the ground pads. The ground tips therefore land about 33 µm inside the inner edge of the ground openings, and the signal tip has about ±30 µm.
- Calibrate at the probe tips on a 100 µm pitch substrate. The pads then add only their own parasitics.
- The GGB probe body is a block 30.5 mm wide, 1.2 mm above the tip at its bottom. The probe board keeps every part below it, see the clearance table in [`pcb/README.md`](../pcb/README.md).
- The probes are fragile. Look at the tips under the prober's microscope before each session, and note which probe took which data.

## LO and RF drive

- +12 dBm at the LO pad places each detector at about −6 dBm, the operating point the detector was characterized at. The LO path through filter, divider and coupler loses 17.3 to 18.6 dB ([`testbenches/xschem/README.md`](../testbenches/xschem/README.md)).
- The IF output falls with the LO drive. Post-layout, at 2 GHz IF and over the four outputs, it is 1.6 to 1.9 dB below its value at +12.1 dBm on the LO pad at +9.3 dBm, 3.9 to 4.5 dB at +6.4 dBm, 10.6 to 11.3 dB at −0.3 dBm and 15.5 to 16.1 dB at −5.1 dBm, the lowest point simulated (`testbenches/xschem/plot_simulations/data/sparx_top_le_rx_lo_m1_pex.csv`).
- So the ZTXR170 drives LO: its +9 dBm minus the probe loss lands a few dB below the design point. An OML extender drives RF, where the receiver benches use −20 dBm at the pad.
- LO and RF run an IF apart, below 2 GHz, so the VNA drives the two converters from separate sources.

## Readout

- The off-chip capacitor on each detector output, 2.7 pF on the board plus the probe input, sets the IF bandwidth.
- With the differential probe on the board's probe pads the 0 Ω SMA links stay out. With the links fitted, the 50 Ω oscilloscope inputs cost 6.6 dB of `OUT − REF` at low IF.
- The DC monitor headers in the board's bottom corners give the detector operating points through 10 kΩ taps.
