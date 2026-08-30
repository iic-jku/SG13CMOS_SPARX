# SPARX: An Open-Source, Automated, Programmatically Generated, Frequency-Scalable Six-Port Receiver in 130-nm CMOS

[![License: Solderpad Hardware License v2.1](https://img.shields.io/badge/License-Solderpad%20Hardware%20License%20v2.1-blue.svg)](LICENSE)
[![Quarto Publish](https://github.com/iic-jku/SG13CMOS_SPARX/actions/workflows/quarto-publish.yml/badge.svg?branch=main)](https://github.com/iic-jku/SG13CMOS_SPARX/actions/workflows/quarto-publish.yml)
[![Regression](https://github.com/iic-jku/SG13CMOS_SPARX/actions/workflows/regression.yml/badge.svg)](https://github.com/iic-jku/SG13CMOS_SPARX/actions/workflows/regression.yml)
[![License Check](https://github.com/iic-jku/SG13CMOS_SPARX/actions/workflows/license-check.yml/badge.svg)](https://github.com/iic-jku/SG13CMOS_SPARX/actions/workflows/license-check.yml)
[![Documentation](https://img.shields.io/badge/Documentation-online-orange?logo=quarto)](https://iic-jku.github.io/SG13CMOS_SPARX/index.html)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.19654232.svg)](https://doi.org/10.5281/zenodo.19654232)

(c) 2025-2026 Simon Dorrer, David Kellerer-Pirklbauer, and Harald Pretl

Institute for Integrated Circuits and Quantum Computing, Johannes Kepler University (JKU), Linz, Austria

> [!IMPORTANT]
> This repository requires the [IIC-OSIC-TOOLS](https://github.com/iic-jku/IIC-OSIC-TOOLS) container with tag `2026.08` or later.

> [!TIP]
> This repository is based on the [ihp-sg13g2-ams-chip-template](https://github.com/iic-jku/ihp-sg13g2-ams-chip-template) template repository and has been extended with electromagnetic (EM) simulations using the tool AWS Palace. For a better understanding of the folder structure, how to use the Makefiles, and how to implement your own designs, it is recommended to go through this [tutorial](https://iic-jku.github.io/ihp-sg13g2-ams-chip-template/index.html).

> [!NOTE]
> SPARX stands for **S**ix-**P**ort **A**utomated Receiver (**RX**). The name also carries a subtle double meaning: *SPARX* sounds like *spark*, which translates to *Funken* in German. Fittingly, the German verb *funken* also means to communicate via radio, a subtle nod to the wireless world this receiver was designed for.

<p align="center">
  <a href="doc/fig/sparx160/sparx160_top_black_pinout.png">
    <img src="doc/fig/sparx160/sparx160_top_black_pinout.png" alt="Chip render of the ihp-sg13cmos six-port receiver for 160 GHz with M5 GND plane and pinout (1 mm × 1.4 mm)" width=70%>
  </a>
  <br>
  <em>Chip render of the ihp-sg13cmos six-port receiver for 160 GHz with M5 GND plane and pinout (1 mm × 1.4 mm).</em>
</p>


## Chip Specifications

| Parameter           | Value                                                                             |
| ------------------- | --------------------------------------------------------------------------------- |
| Technology          | IHP SG13CMOS (130 nm CMOS)                                                        |
| Die Area            | 1000 × 1400 µm (1.4 mm²)                                                          |
| Supply Voltage      | 1.5 V                                                                             |


## Documentation

> [!IMPORTANT]
> This work has been submitted to the IEEE for possible publication. Copyright may be transferred without notice, after which this version may no longer be accessible.

The full documentation of SPARX is available [here](https://iic-jku.github.io/SG13CMOS_SPARX/index.html) (WIP).


## Overview

The complete layout is generated in Python using self-made RF devices as a GDSFactory IHP PDK add-on. S-parameter simulation of the passive RF structures (BPF, WPD, and BLC) is performed with AWS Palace. The de-embedded EM results are then fitted to passivity-enforced lumped element models with [snp2le](https://github.com/iic-jku/snp2le), in both SPICE and Spectre dialects, and resimulated in Xschem testbenches with ngspice and VACASK. The six-port core is verified in two ways: as a single fitted model of the full-core EM simulation and as a composition of the individual BPF, WPD, and BLC models. With KLayout, Magic, and Netgen, a complete DRC, LVS, and PEX verification flow is implemented. The SBD-based power detector is designed in Xschem and simulated with ngspice and VACASK. This repository is controlled by a Makefile. Just clone it and run `make all` to build the six-port receiver at 160 GHz, verify it, run the EM simulations, extract the lumped element models, and simulate all testbenches. To generate a frequency-scalable layout at a different target frequency, for example 77 GHz, run `make build-layout FREQ=77`. A nightly [regression](#regression) exercises the complete tool flow in GitHub Actions inside the IIC-OSIC-TOOLS container. The following video demonstrates the generation of six-port receivers from 60 GHz to 300 GHz in under one minute.

**Index Terms:** Branch-line coupler, frequency-scalable layout, GDSFactory, hairpin coupled-line bandpass filter, IHP Open-PDK, mmWave, open-source EDA, power detector, programmatic layout, Schottky barrier diode, six-port receiver, Wilkinson power divider.

https://github.com/user-attachments/assets/a1e6cacb-4a70-4f2c-9b7a-f4b6fbb5a47a
<p align="center">
  <em>Generation of Six-Port Receivers from 60 GHz to 300 GHz.</em>
</p>


## References
To understand the principle of six-port receivers and their architectures, it is recommended to read the following references:
- A. Koelpin, G. Vinci, B. Laemmle, D. Kissinger and R. Weigel, "The Six-Port in Modern Society," in IEEE Microwave Magazine, vol. 11, no. 7, pp. 35-43, Dec. 2010, doi: 10.1109/MMM.2010.938584: https://ieeexplore.ieee.org/document/5590352
- T. Hentschel, "The six-port as a communications receiver," in IEEE Transactions on Microwave Theory and Techniques, vol. 53, no. 3, pp. 1039-1047, March 2005, doi: 10.1109/TMTT.2005.843507: https://ieeexplore.ieee.org/document/1406309
- M. Mailand, "System Analysis of Six-Port-Based RF-Receivers," in IEEE Transactions on Circuits and Systems I: Regular Papers, vol. 65, no. 1, pp. 319-330, Jan. 2018, doi: 10.1109/TCSI.2017.2734922: https://ieeexplore.ieee.org/document/8011483


## Requirements

To build this six-port receiver, the following tools and their respective dependencies are required:
- GDSFactory: https://github.com/gdsfactory/gdsfactory
- IHP Open-PDK GDSFactory Addon: https://github.com/iic-jku/IHP-GDSFactory-Addon
- IHP Open-PDK: https://github.com/iic-jku/IHP-Open-PDK
- snp2le (S-parameter to lumped element netlist conversion): https://github.com/iic-jku/snp2le, available on PyPI: https://pypi.org/project/snp2le/

GDSFactory, the IHP Open-PDK, and snp2le are already installed in the IIC-OSIC-TOOLS container.

The updated IHP Open-PDK GDSFactory version contains all self-made RF devices and wraps existing PCells provided by the IHP Open-PDK, allowing them to be used directly within the GDSFactory framework. We choose this approach because it requires very little maintenance. If IHP changes the layout of a cell, no wrapper update is necessary. Only interface changes to a PCell function require updates on our side.


## Block Diagram
- Six-Port
  - Branch Line Coupler (BLC)
  - Wilkinson Power Divider (WPD)
  - Hairpin Coupled-Line Bandpass Filter (BPF)
- Power Detector (PD)
  - Schottky Barrier Diode (SBD)
- Metal Stack
  - TopMetal2 (TM2): RF traces
  - Metal5 (M5): GND plane

<p align="center">
  <a href="doc/fig/sparx_blockdiagram/sparx_blockdiagram.png">
    <img src="doc/fig/sparx_blockdiagram/sparx_blockdiagram.png" alt="Block Diagram of the Six-Port Receiver" width=75%>
  </a>
  <br>
  <em>Block diagram of the six-port receiver.</em>
</p>


## Schematic of SBD-based Power Detector

<p align="center">
  <a href="doc/fig/sparx_powdet_sbd/sparx_powdet_sbd_circuit.png">
    <img src="doc/fig/sparx_powdet_sbd/sparx_powdet_sbd_circuit.png" alt="Schematic of SBD-based Power Detector" width=100%>
  </a>
  <br>
  <em>Schematic of the SBD-based power detector with replica circuit for fully-differential measurements. The supply and bias voltages are decoupled on-chip by MIM capacitors. The filtering capacitor is placed off-chip.</em>
</p>


## Design Flow

An overview of the open-source design flow for SPARX is shown below. The flow covers schematic entry, circuit simulation, parameterized layout generation, physical verification, post-layout simulation, EM simulation and resimulation of fitted lumped element models. All required tools and the IHP Open-PDK run inside the IIC-OSIC-TOOLS Docker image. The complete design flow is automated with Makefile targets, which are explained below.

<p align="center">
  <a href="doc/fig/design_flow/design_flow.png">
    <img src="doc/fig/design_flow/design_flow.png" alt="Design flow of SPARX" width=80%>
  </a>
  <br>
  <em>Overview of the open-source design flow for SPARX.</em>
</p>


## Directory Structure

<details>
<summary>Show Directory Structure</summary>

```text
📁 SG13CMOS_SPARX/
├─ 📁 .github/
│  └─ 📁 workflows/
│     ├─ license-check.yml
│     ├─ quarto-publish.yml
│     └─ regression.yml
├─ 📁 doc/
│  ├─ 📁 fig/
│  ├─ 📁 videos/
│  ├─ _quarto.yml
│  ├─ index.qmd
│  ├─ requirements.txt
│  └─ Makefile
├─ 📁 LICENSES/
│  ├─ Apache-2.0.txt
│  └─ SHL-2.1.txt
├─ 📁 layout/
│  ├─ sparx60_top.gds
│  ├─ ...
│  ├─ sparx160_top.gds
│  ├─ ...
│  ├─ sparx300_top.gds
│  └─ sparx_powdet_sbd.gds
├─ 📁 measurements/
├─ 📁 netlist/
│  ├─ 📁 layout/
│  │  ├─ sparx_powdet_sbd_klayout.cir
│  │  └─ sparx_powdet_sbd_magic.ext.spc
│  ├─ 📁 pex/
│  │  ├─ sparx_powdet_sbd_klayout_pex_3.spice
│  │  └─ sparx_powdet_sbd_magic_pex_3.spice
│  ├─ 📁 schematic/
│  │  ├─ sparx_powdet_sbd_klayout.cdl
│  │  └─ sparx_powdet_sbd_magic.spice
│  ├─ 📁 spectre/
│  │  ├─ sparx_blc_le.inc
│  │  ├─ sparx_bpf_le.inc
│  │  ├─ sparx_core_le.inc
│  │  └─ sparx_wpd_le.inc
│  └─ 📁 spice/
│     ├─ sparx_blc_le.spice
│     ├─ sparx_bpf_le.spice
│     ├─ sparx_core_le.spice
│     └─ sparx_wpd_le.spice
├─ 📁 release/
│  ├─ 📁 v.1.0.0/
│  │  ├─ 📁 gds/
│  │  ├─ 📁 img/
│  │  └─ ReleaseNote.md
│  └─ 📁 v.2.0.0/
│     ├─ 📁 gds/
│     ├─ 📁 img/
│     └─ 📁 netlist/
├─ 📁 render/
│  ├─ 📁 blender/
│  └─ 📁 img/
│     ├─ sparx160_top_black.png
│     ├─ sparx160_top_black_TM2.png
│     └─ sparx160_top_white.png
├─ 📁 schematic/
│  └─ 📁 xschem/
│     ├─ sparx_blc_le.sym
│     ├─ sparx_bpf_le.sym
│     ├─ sparx_core.sch
│     ├─ sparx_core.sym
│     ├─ sparx_core_le.sym
│     ├─ sparx_powdet_sbd.sch
│     ├─ sparx_powdet_sbd.sym
│     ├─ sparx_powdet_sbd_pex.sym
│     ├─ sparx_top.sch
│     ├─ sparx_top.sym
│     ├─ sparx_top_le.sch
│     ├─ sparx_top_le.sym
│     ├─ sparx_top_lvs.sch
│     ├─ sparx_wpd_le.sym
│     └─ xschemrc
├─ 📁 scripts/
│  ├─ 📁 assets/
│  ├─ check_pex_ports.py
│  ├─ img2lay.py
│  ├─ prune_pex_symbol.py
│  ├─ six_port_gen.py
│  └─ sparx_powdet_sbd_circuit.ipynb
├─ 📁 sscs-ose-code-a-chip/
│  ├─ 📁 assets/
│  ├─ README.md
│  └─ SPARX_JKU_VLSI2026.ipynb
├─ 📁 testbenches/
│  └─ 📁 xschem/
│     ├─ 📁 plot_simulations/
│     │  ├─ 📁 data/
│     │  ├─ 📁 figures/
│     │  ├─ ngspice2python.py
│     │  ├─ plot_n_port_tb_acsp_ngspice.py
│     │  ├─ plot_n_port_tb_acsp_vacask.py
│     │  ├─ plot_n_port_tb_tran_ngspice.py
│     │  ├─ plot_sparx_powdet_sbd_tb_hb_V-W_vacask.py
│     │  ├─ plot_sparx_powdet_sbd_tb_hb_dBV-dBV_vacask.py
│     │  ├─ plot_sparx_powdet_sbd_tb_nf_vacask.py
│     │  ├─ plot_sparx_powdet_sbd_tb_pss_vacask.py
│     │  ├─ plot_sparx_powdet_sbd_tb_tn_vacask.py
│     │  └─ sparam_plot.py
│     ├─ sparx_blc_le_tb_acsp_ngspice.sch
│     ├─ ...
│     ├─ sparx_core_tb_acsp_ngspice.sch
│     ├─ ...
│     ├─ sparx_powdet_sbd_tb_ngspice.sch
│     ├─ ...
│     ├─ sparx_top_tb_tran_ngspice.sch
│     ├─ sim_range.inc
│     ├─ sim_range.spice
│     └─ xschemrc
├─ 📁 verification/
│  ├─ 📁 drc/
│  │  ├─ 📁 sparx160_top.klayout.drc/
│  │  ├─ 📁 sparx160_top.magic.drc/
│  │  ├─ 📁 sparx_powdet_sbd.klayout.drc/
│  │  └─ 📁 sparx_powdet_sbd.magic.drc/
│  ├─ 📁 em/
│  │  ├─ 📁 layout/
│  │  ├─ 📁 palace_model/
│  │  ├─ 📁 s-parameter/
│  │  ├─ 📁 scripts/
│  │  └─ 📁 stackups/
│  └─ 📁 lvs/
│     ├─ 📁 sparx_powdet_sbd.klayout.lvs/
│     └─ 📁 sparx_powdet_sbd.magic.lvs/
├─ .gitattributes
├─ .gitignore
├─ CITATION.cff
├─ KNOWN_ISSUES.md
├─ LICENSE
├─ Makefile
├─ README.md
└─ REUSE.toml
```

</details>


## Xschem Configuration

Xschem reads exactly one `xschemrc` at start-up, and that file decides which symbol libraries are visible and where netlists and simulation output are written. This repository ships one per folder that holds schematics:

| `xschemrc` | Belongs to |
| --- | --- |
| [`schematic/xschem/xschemrc`](schematic/xschem/xschemrc) | the six-port and power detector schematics and symbols |
| [`testbenches/xschem/xschemrc`](testbenches/xschem/xschemrc) | the ngspice and VACASK testbenches |


### What Every File Does

Both run the same four steps, in this order:

1. **Pick the PDK.** `PDK_ROOT` is probed in the usual install locations if the environment does not set it, and `PDK` falls back to `ihp-sg13g2`. The container already exports `PDK_ROOT`, and [`.designinit`](.designinit) exports `PDK`, so this step is only a safety net for an Xschem started outside that environment.
2. **Source the PDK `xschemrc`.** `$PDK_ROOT/$PDK/libs.tech/xschem/xschemrc` brings in the IHP device symbols, the ngspice and VACASK model paths and the IHP menu. It is guarded by `[info exists PDK]` so it is read once even when the two project files are chained.
3. **Add the project library paths.** `append_xschem_library_path_unique` appends a folder to `XSCHEM_LIBRARY_PATH` only if it is not already there, so the same folder never appears twice no matter how the files are chained. [`schematic/xschem/xschemrc`](schematic/xschem/xschemrc) puts itself and `testbenches/xschem/` on the path. [`testbenches/xschem/xschemrc`](testbenches/xschem/xschemrc) adds none of its own and gets both from the file it sources.
4. **Pin the netlist directory.** `pin_netlist_dir` decides where `xschem netlist` and the simulators write.

Both helper procedures are defined behind an `[info commands ...]` guard, so sourcing one file from the other is harmless and the order does not matter.


### How the Files Are Chained

The testbench file pulls in the schematic file:

```text
testbenches/xschem/xschemrc
└─ source schematic/xschem/xschemrc
```

Either file therefore sees both folders, which is what lets a testbench instantiate `sparx_powdet_sbd.sym` or one of the `sparx_*_le.sym` lumped element symbols, and what lets you open a testbench from a session started in `schematic/xschem/`.


### Where Netlists and Simulation Output Go

`pin_netlist_dir` maps the folder of the schematic being netlisted to a `simulations/` folder:

| Schematic lives in | `netlist_dir` |
| --- | --- |
| `testbenches/xschem` | `testbenches/xschem/simulations` |
| `schematic/xschem` | `testbenches/xschem/simulations` |
| anywhere else (a PDK example) | left at the value the `xschemrc` pinned |

It runs twice: once while the `xschemrc` is read, using that file's own folder, and again through Xschem's `load_file_postprocess` hook for every schematic that is opened afterwards. The second call keeps the netlist next to its own schematic tree no matter where the session was started, so the relative includes of the testbenches, such as `.include ../../../netlist/spice/sparx_bpf_le.spice` or `.include ../../../netlist/pex/sparx_powdet_sbd_magic_pex_3.spice`, always resolve from `testbenches/xschem/simulations/`.

A `set netlist_dir` passed on the Xschem command line still wins, because `--command` runs after the file is loaded. The LVS netlist targets rely on this to write into `netlist/schematic/`, and `sim-xschem` to write into `testbenches/xschem/simulations/`.

Both `simulations/` folders are generated and git-ignored.


### Which File Is Used

- The Makefile targets always name one explicitly with `--rcfile`, so a target behaves the same from any working directory.
- Starting Xschem from within one of the two folders picks up that folder's file, which is the normal interactive case.
- `make open` starts Xschem in the file's own directory, so the same rule applies to every button of the file browser, see [Open the Design Files](#open-the-design-files).


## Makefile Targets

### Show Available Targets

The default Make target is `help`, so running `make` prints usage and all available targets with short descriptions.

```sh
make
make help
```

### Open the Design Files

Opens a file browser for this folder with `sak-open.py` from the [IIC-OSIC-TOOLS](https://github.com/iic-jku/IIC-OSIC-TOOLS), one button per design file, grouped by directory:

```sh
make open
```

Clicking a button launches the matching tool in the file's own directory, so Xschem finds its `simulations/` folder and KLayout the layouts where they belong:

| File type | Tool |
| --- | --- |
| `.sch`, `.sym` | Xschem |
| `.gds`, `.gds.gz`, `.oas`, `.oas.gz` | KLayout in edit mode |
| `.mag` | Magic |
| `.vcd`, `.fst`, `.gtkw` | GTKWave |
| `.raw` | gaw (ngspice rawfile) |
| `.png`, `.pdf` | the desktop's handler (`xdg-open`) |
| `.sv`, `.svh`, `.v`, `.vh`, `.vhd`, `.vhdl`, `.spice`, `.cir`, `.sp`, `.cdl`, `.sdc`, `.lef`, `.lib`, `.tcl`, `.mk`, `.yaml`, `.json`, `.py`, `.qmd`, `.tex`, `.md` and `Makefile` | gvim |

Only these types get a button. Files with any other extension (`.sh`, `.svg`, `.save`, `.inc`, `.sNp`, `.txt`, `.csv` and so on) are not listed.

Schematics and symbols that belong to one design unit share a single tabbed Xschem instance instead of one process per click. The unit is the nearest ancestor holding a `Makefile`, so the whole design is one unit and the documentation under [`doc/`](doc/) another. Every tab then writes its netlists to the folder the `xschemrc` pins, see [Xschem Configuration](#xschem-configuration).

The tree is rescanned every 15 s, so files a running flow produces appear on their own and are highlighted for a minute. Generated directories are skipped by default: `runs/`, `sim_build/`, `obj_dir/`, `simulations/`, `__pycache__/`, `_freeze/` and `.git/`. The Xschem `simulations/` folder is one of them, so the `.raw` files show up only with `--all`. Pass extra options with `OPEN_ARGS`:

```sh
make open OPEN_ARGS=--all                      # include the simulation outputs
make open OPEN_ARGS="--prune palace_model"     # skip one more directory name
```

At most 400 buttons are drawn at once, because each one is an X window, and what is left out is stated at the end of the list. That cap is easy to hit with `--all`, which also pulls in the Palace meshes under `verification/em/palace_model/` and every simulation output, so narrow it with `--prune` rather than scrolling. The same target exists in [`doc/`](doc/) for the documentation sources and figures.

> [!NOTE]
> This target needs a display. Run it inside the container's VNC/noVNC desktop or over X11 forwarding. In a shell-only container it stops with `cannot open a window`. The `.png` and `.pdf` buttons hand the file to the desktop's registered handler, so those two need the full VNC/noVNC session and do not work over a bare X forward.

### Build PDK

Clones and installs the GDSFactory PDK add-on (`IHP-GDSFactory-Addon`):

```sh
make build-pdk
```

### Build SPARX Layout

Generates the six-port layout GDS files for a specific frequency (e.g. `layout/sparx160_top.gds` and `layout/sparx_powdet_sbd.gds` for the default 160 GHz, or `layout/sparx77_top.gds` and `layout/sparx_powdet_sbd.gds` for 77 GHz) by calling `six_port_gen.py`:

```sh
make build-layout
make build-layout FREQ=77
make build-layout FREQ=77 NO_FILL=1
make build-layout FREQ=77 NO_FILL_M5=1
```

The `FREQ` parameter sets the design frequency in GHz (default: `160`). `NO_FILL=1` disables metal fill (faster for layout preview). `NO_FILL_M5=1` disables only the Metal5 ground fill.

> [!NOTE]
> `build-layout` also writes the EM sub-structures of the design (BLC, WPD, BPF, and the blank six-port core, each with the Palace port markers on layers 201..207) to `verification/em/layout/`. The EM simulation targets solve exactly these files, so the EM results always match the structures instantiated in the top-level layout.

### Build Frequency Sweep Automatically

Builds a frequency sweep by repeatedly calling `build-layout` for each frequency from `START_FREQ` to `STOP_FREQ` using `STEP_FREQ`.

```sh
make build-layout-sweep
make build-layout-sweep START_FREQ=60 STOP_FREQ=300 STEP_FREQ=20
make build-layout-sweep START_FREQ=60 STOP_FREQ=300 STEP_FREQ=20 NO_FILL=1
make build-layout-sweep START_FREQ=60 STOP_FREQ=300 STEP_FREQ=20 NO_FILL_M5=1
```

Default sweep settings are `START_FREQ=60`, `STOP_FREQ=300`, and `STEP_FREQ=20` (all in GHz). `NO_FILL` and `NO_FILL_M5` are forwarded to each `build-layout` run.

### Build Top Cell

Builds the top-level cell by running `build-pdk`, `build-layout`, and `render-gds`:

```sh
make build-top
```

### Render Top Layout

Renders the top-level GDS `layout/sparx<FREQ>_top.gds` with `sak-render.py` from the [IIC-OSIC-TOOLS](https://github.com/iic-jku/IIC-OSIC-TOOLS):

```sh
make render-gds
make render-gds FREQ=77
```

Three images are written to the `render/img/` folder:

- `sparx<FREQ>_top_white.png` and `sparx<FREQ>_top_black.png`: all physical mask layers, on a white and on a black background.
- `sparx<FREQ>_top_black_TM2.png`: only `TopMetal2`, `TopVia2`, the `TopMetal2` filler and `Passiv` on a black background, which shows the six-port RF structures and the pads without the Metal5 ground plane underneath.

All three images are 2048 px wide and rendered with 4x oversampling. `sak-render.py` reads the layer colours from the PDK's own KLayout layer properties and crops to the drawn geometry, so the images have no border margin.

### Design Rule Check (DRC)

Runs DRC on the GDS layout in `layout/`. Both flows use `sak-drc.sh` and write their reports into per-cell run folders: `verification/drc/<CELL>.magic.drc/` (Magic) and `verification/drc/<CELL>.klayout.drc/` (KLayout, `.lyrdb`). The run folders are wiped at the start of each run, so they always reflect the latest run only.

The `DRC_LEVEL` parameter selects the KLayout DRC level (`sak-drc.sh -l`). It is ignored by `magic-drc`, since Magic has no selectable rule decks and always runs the full rule set compiled into the PDK's Magic tech file:

- `precheck` = core FEOL + BEOL manufacturing rules only (fast iteration)
- `macro` = block-in-isolation sign-off: `precheck` plus off-grid, zero-area, and pin/label checks (default)
- `regular` = full-chip sign-off: all checks, including density and antenna

| Check | `precheck` | `macro` _(default)_ | `regular` |
| --- | :---: | :---: | :---: |
| FEOL + BEOL core rules | ✓ | ✓ | ✓ |
| Off-grid / angle | – | ✓ | ✓ |
| Zero-area / geometry | – | ✓ | ✓ |
| Pin / label | – | ✓ | ✓ |
| Recommended / extra rules | – | – | ✓ |
| Density (full-chip fill) | – | – | ✓ |
| Antenna | – | – | ✓ |

**KLayout DRC (regular)** runs a full (`regular`) KLayout DRC on the top-level cell:

```sh
make klayout-drc-regular
```

**KLayout DRC** runs a KLayout DRC at the selected `DRC_LEVEL`:

```sh
make klayout-drc
make klayout-drc CELL=sparx_powdet_sbd
make klayout-drc CELL=sparx_powdet_sbd DRC_LEVEL=regular
```

**Magic DRC** runs a Magic DRC with all subcells flattened (`sak-drc.sh -f "*"`):

```sh
make magic-drc
make magic-drc CELL=sparx_powdet_sbd
```

> [!NOTE]
> `make klayout-drc` (`macro` level) is clean. `make klayout-drc-regular` reports antenna violations that were waived by IHP for the tapeout. See [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md) for the full breakdown.

### Export Schematic Netlist for LVS

Exports the schematic netlist for LVS from Xschem and places it in `netlist/schematic/`.

The `EV_PRECISION` parameter sets the number of significant digits used by Xschem's `ev` function when calculating device properties (default: 5). Increase this to avoid LVS mismatches caused by floating-point rounding differences between Xschem and KLayout (see [xschem#465](https://github.com/StefanSchippers/xschem/issues/465)).

The `ntap` and `ptap` substrate contacts are ignored during LVS in both flows. `sak-lvs.sh` runs KLayout LVS with the `--disable_tap_extraction` option so it does not extract `ntap` and `ptap` devices from the layout (matching Magic + Netgen LVS).

KLayout uses CDL netlists, while Magic uses SPICE netlists. Accordingly, `klayout-lvs-netlist` uses the Xschem commands `set spiceprefix 1`, `set lvs_netlist 1`, `set top_is_subckt 1`, and `set lvs_ignore 1`, while `magic-lvs-netlist` uses `set spiceprefix 1`, `set lvs_netlist 0`, `set top_is_subckt 1`, and `set lvs_ignore 1`. Hence, switching between CDL and SPICE netlists can be done with `lvs_netlist`.

To extract a CDL schematic netlist for KLayout LVS, use the following target:
```sh
make klayout-lvs-netlist
make klayout-lvs-netlist CELL=sparx_powdet_sbd
make klayout-lvs-netlist EV_PRECISION=5
```

To extract a SPICE schematic netlist for Magic + Netgen LVS, use the following target:
```sh
make magic-lvs-netlist
make magic-lvs-netlist CELL=sparx_powdet_sbd
make magic-lvs-netlist EV_PRECISION=5
```

### Layout Versus Schematic (LVS)

Exports the schematic netlist from Xschem, then runs LVS. Compares the GDS layout in `layout/` against the schematic netlist in `netlist/schematic/`. Both flows use `sak-lvs.sh` and write their reports into per-cell run folders: `verification/lvs/<CELL>.magic.lvs/` (Magic + Netgen) and `verification/lvs/<CELL>.klayout.lvs/` (KLayout, `.lvsdb`). The run folders are wiped at the start of each run, so they always reflect the latest run only. The extracted layout netlist is moved to `netlist/layout/`.

**KLayout LVS** uses `sak-lvs.sh` (KLayout mode `-k`), which wraps `run_lvs.py` from the IHP Open-PDK:

```sh
make klayout-lvs
make klayout-lvs CELL=sparx_powdet_sbd
```

**Magic + Netgen LVS** uses `sak-lvs.sh` (Magic + Netgen mode `-m`, the default), which extracts the layout netlist with Magic and compares it against the schematic netlist with Netgen, using the Netgen setup from the IHP Open-PDK:

```sh
make magic-lvs
make magic-lvs CELL=sparx_powdet_sbd
```

### Build Xschem PEX Symbol

Builds the Xschem symbol the PEX flow needs, `schematic/xschem/<CELL>_pex.sym`, from the regular cell symbol `schematic/xschem/<CELL>.sym`:

```sh
make symbol-pex CELL=sparx_powdet_sbd
```

The generated symbol is a copy of `<CELL>.sym` with two changes: `type=subcircuit` becomes `type=primitive`, and the pin boxes the extracted netlist has no port for are dropped. Everything else (the remaining pin boxes and their order, every text label, `format`, `spectre_format`, `template`, graphics) is inherited, which is exactly what the PEX flow needs:

- **`type=primitive`** stops Xschem from descending into a schematic of the same name. There is no `<CELL>_pex.sch`, so the instance line is emitted as it stands and the subcircuit comes from the `.include`d PEX netlist instead.
- **`format="@name @pinlist @symname"`** makes the instance reference `@symname`, which resolves to `<CELL>_pex`, exactly the `.subckt` name the PEX flow writes.
- **The pin order** is what `sak-pin-reorder.py` reorders the extracted netlist to, so it has to be that of the cell symbol.

`PEX_MERGED_PINS` names the supply pins that the extraction does not report as ports of their own. It is empty by default: the power detector keeps `vdd` and `vss` as separate ports in both the Magic and the KPEX extraction, so nothing is dropped and `sparx_powdet_sbd_pex.sym` carries the same five pins as `sparx_powdet_sbd.sym`. Set it for a cell whose supplies come out of the flat extraction as one node, for example two ground pins that both tap the substrate: `make magic-pex CELL=<cellname> PEX_MERGED_PINS="<pin> ..."`.

[`scripts/prune_pex_symbol.py`](scripts/prune_pex_symbol.py) drops those pins and, for the same reason, every repeat of a pin name after the first: a `.subckt` port list holds one entry per net, so pads that share a supply share a port. Only the pin boxes go and every text label stays, so the generated symbol still reads as the full cell while carrying exactly the pins the netlist has a port for.

`symbol-pex` runs automatically at the start of `klayout-pex` and `magic-pex`, so the symbol is rebuilt from the current `<CELL>.sym` before every extraction and cannot go stale when a pin is added, removed or renamed. Calling it by hand is only needed to refresh the symbol without re-running an extraction. Anything added to the generated file by hand is lost at the next extraction, so make the change in `<CELL>.sym` instead.

If `<CELL>.sym` does not exist, the target prints a note and does nothing, which leaves the PEX targets running without a pin reorder just as before. That is the case for the default `CELL`, the generated six-port top cell `sparx160_top`, which has no hand-drawn symbol. It fails only when `<CELL>.sym` declares neither `type=subcircuit` nor `type=primitive`.

> [!NOTE]
> Every symbol in this project also carries `spectre_format="@name ( @pinlist ) @symname"`. Xschem writes that line itself whenever a symbol is built from a schematic's pin list (key `a`, `make_sym.awk`), and it is read **only** by the Spectre netlister, which is also the one that drives VACASK (`xschem.tcl` configures `vacask "$N"` as the default simulator for `netlist_type spectre`). The SPICE netlister used for ngspice ignores it, so it has no effect on the ngspice testbenches.
> Do not strip it: without it, instances of the symbol are **silently dropped** from a Spectre/VACASK netlist and the `subckt` line of the symbol itself comes out with an empty port list, with no warning at all. Every `_vacask` testbench in this repository depends on it.

### Parasitic Extraction (PEX)

Runs parasitic extraction on the GDS layout in `layout/`. The extracted SPICE netlist is written to `netlist/pex/`, with the extraction mode as suffix, so the three modes sit next to each other without overwriting one another:

- `klayout-pex` writes `netlist/pex/<CELL>_klayout_pex_<EXT_MODE>.spice`
- `magic-pex` writes `netlist/pex/<CELL>_magic_pex_<EXT_MODE>.spice`

The committed netlists of the power detector are the full-RC ones, `sparx_powdet_sbd_magic_pex_3.spice` and `sparx_powdet_sbd_klayout_pex_3.spice`. The Magic one is what the `.include` in the ngspice testbench `sparx_powdet_sbd_tb_ngspice.sch` and the `m1_pex` variant of the VACASK power-detector testbenches (`scripts/powdet_variant.py`) read.

The `EXT_MODE` parameter selects the extraction mode:
- `1` = C-decoupled
- `2` = C-coupled
- `3` = full-RC (default)

> [!NOTE]
> For `klayout-pex`, `EXT_MODE=1` (C-decoupled) is not yet supported by kpex and automatically falls back to `EXT_MODE=2` (C-coupled) with a warning.

The `.subckt` name in the extracted SPICE file is `<CELL>_pex`: `magic-pex` sets it directly via the `sak-pex.sh` option `-n <CELL>_pex`, while for `klayout-pex` it is automatically renamed from `<CELL>` (kpex).

Both targets start by running `symbol-pex` (see above), so `schematic/xschem/<CELL>_pex.sym` always reflects the current cell symbol. If it exists, the `.subckt` pin order in the extracted SPICE file is then reordered with `sak-pin-reorder.py` (installed in the IIC-OSIC-TOOLS container) to match that symbol's pin positions. This ensures the PEX netlist can be used directly with the corresponding Xschem symbol for simulation regardless of the selected `EXT_MODE`.

Both targets finish by running [`scripts/check_pex_ports.py`](scripts/check_pex_ports.py) on the netlist they just wrote. It verifies that every pin of the `.subckt` really reaches the circuit, and fails the target otherwise. Two cases are caught:

- A port that is declared in the `.subckt` line but referenced by no element at all. Whatever is wired to that pin from outside is then left floating.
- A port whose net was split into `<port>.t<n>` and `<port>.n<n>` fragments by `extresist` (`EXT_MODE=3`), where none of the fragments is connected back to the port. The pin is then dangling even though the fragments themselves are wired up.

Both produce a netlist that ngspice reads without a single warning while the cell behaves completely differently in simulation, so the check is worth the two seconds it costs. It can also be run by hand on any SPICE netlist:

```sh
python3 scripts/check_pex_ports.py netlist/pex/sparx_powdet_sbd_magic_pex_3.spice
python3 scripts/check_pex_ports.py -v netlist/pex/*.spice     # -v also prints the size of each subcircuit
```

**KLayout PEX** uses `kpex` with the Magic extraction engine (the 2.5D engine is work in progress):

```sh
make klayout-pex
make klayout-pex CELL=sparx_powdet_sbd
make klayout-pex CELL=sparx_powdet_sbd EXT_MODE=3
```

**Magic PEX** uses `sak-pex.sh`, which extracts the parasitics with Magic (C-decoupled, C-coupled, or full-RC):

```sh
make magic-pex
make magic-pex CELL=sparx_powdet_sbd
make magic-pex CELL=sparx_powdet_sbd EXT_MODE=3
```

For full-RC extraction (`EXT_MODE=3`), `magic-pex` additionally exposes the `sak-pex.sh` `extresist` tuning parameters. They are ignored in `EXT_MODE=1`/`2`:

- `THRESHOLD` - extresist threshold in mOhm (`-t`, default `10000` = 10 Ohm)
- `MINRES` - extresist minimum resistance in mOhm (`-r`, default `1000` = 1 Ohm)
- `MINDELAY` - extresist minimum delay in ps (`-y`, default `1`; `0` = gate by resistance)

```sh
make magic-pex CELL=sparx_powdet_sbd EXT_MODE=3 THRESHOLD=5000 MINRES=500 MINDELAY=2
```

### Verify a Specific Cell

Runs DRC, LVS, and PEX for a specific cell (e.g. `sparx_powdet_sbd`):

```sh
make klayout-verify CELL=sparx_powdet_sbd
make magic-verify CELL=sparx_powdet_sbd
```

### Verify Top Cell

Runs DRC, LVS, and PEX for the top cell:

```sh
make klayout-verify
make magic-verify
```


### EM Simulation

Runs full-wave electromagnetic (EM) simulation of the passive RF structures with AWS Palace. The structures themselves are generated by `build-layout` into `verification/em/layout/` (see [Build SPARX Layout](#build-sparx-layout)). Each EM target picks the matching GDS from there, builds the Palace model, runs the EM solve, and writes the combined Touchstone S-parameter files (raw and de-embedded) to `verification/em/palace_model/`. Use the `copy-sparam` target afterwards to copy the results to `verification/em/s-parameter/`.

Run `make build-layout FREQ=<GHz>` before the EM targets. The GDS files, and every Palace output derived from them, are named `sparx<FREQ>_<structure>` and encode nothing but the design frequency (`sparx160_blc`, `sparx160_wpd`, `sparx160_bpf`, `sparx160_core`), so re-parametrizing a structure in `scripts/six_port_gen.py` does not rename anything. If the file for the requested frequency does not exist, the target aborts with a hint to run `build-layout` first.

The following parameters are shared by all EM simulation targets:
- `FREQ` selects the structure to simulate by its design frequency in GHz (default: `160`).
- `SIGNAL_CROSS_SECTION` sets the signal metal layer of the ports (default: `TM2`).
- `GROUND_CROSS_SECTION` sets the ground metal layer of the ports (default: `M5`).
- `Z0` sets the reference impedance of the ports in Ohms (default: `50`).
- `NP` sets the number of processors used by Palace (default: `4`).

`FREQ` is the only one that `build-layout` also takes as an argument. The other three are the port settings that the targets pass to `palace_sim.py`; they are not derived from the layout, so they must match `signal_cross_section`, `ground_cross_section`, and `Z0` in `scripts/six_port_gen.py`. Everything else about the structures (substrate permittivity, filter type, order, bandwidth, ripple, divider shape) is hardcoded in `scripts/six_port_gen.py`: change it there, rerun `build-layout`, and rerun the EM target.

The process stackup that turns the GDS into a 3D model (materials, dielectric stack, GDS layer to z-range map) comes from the PDK, at `$PDK_ROOT/$PDK/libs.tech/palace/workflow/`, so it always matches the `gds2palace` that reads it. It is not vendored here. Both simulation targets default to `SG13G2_nosub.xml`, because the solid Metal5 plane under the TopMetal2 traces shields the silicon, so leaving the substrate out of the model costs almost nothing in accuracy and saves a lot of mesh. Pass `--stackup <name-or-path>` to use a different one. `verification/em/stackups/` holds the [documentation](verification/em/stackups/README.md): what each stackup is, where to find it, the XML format including the schemaVersion 3.0 and 3.1 additions, and how to check the reader version before using a 3.x file.

**Branch-Line Coupler (BLC):**

```sh
make build-layout && make sim-blc-em
make build-layout FREQ=77 && make sim-blc-em FREQ=77
make sim-blc-em FREQ=77 NP=8
```

**Wilkinson Power Divider (WPD):**

The routing shape of the divider (`wpd_shape`, `C` or `U`) is set in `scripts/six_port_gen.py`.

```sh
make build-layout && make sim-wpd-em
make build-layout FREQ=77 && make sim-wpd-em FREQ=77
```

**Hairpin Coupled-Line Bandpass Filter (BPF):**

The filter parameters (`bandwidth`, `filter_type`, `order`, `ripple_dB`, and the 10 µm connection pieces at the filter ports) are set in `scripts/six_port_gen.py`, so that the simulated filter is the one built into the chip.

```sh
make build-layout && make sim-bpf-em
make build-layout FREQ=77 && make sim-bpf-em FREQ=77
```

**Six-Port Core:**

Simulates the assembled six-port core from `verification/em/layout/sparx<FREQ>_core.gds` (the six-port network with the seven Palace port markers, written by `build-layout`).

Like the sub-structures, the core reflects the chip layout, so all its parameters come from `scripts/six_port_gen.py`.

```sh
make build-layout && make sim-sparx-core-em
make build-layout FREQ=77 && make sim-sparx-core-em FREQ=77
```

> [!NOTE]
> The seven-port full-core EM simulation has a very long runtime. It is therefore not part of `make all`. See the `sparx-core` target below for the complete core EM flow.

### View EM Simulation Results

Plots the first-column S-parameters (magnitude and phase) of a Touchstone file from `verification/em/palace_model/` using `plot_snp.py`.

```sh
make view-em-sim
make view-em-sim FILE_NAME=sparx160_blc.s4p
```

The `FILE_NAME` parameter is the Touchstone file name including its extension (default: the BLC result for the current parameters).


### Copy EM S-Parameter Results

Copies both Touchstone files of an EM simulation run, the raw result and the de-embedded version (`*_deembedded.sNp`), from the Palace output folder `verification/em/palace_model/<name>_data/output/<name>/` to `verification/em/s-parameter/`, where the snp2le conversion expects them.

- `SPARAM` is the EM run name, i.e. the GDS/Touchstone base name without extension (default: the BLC run for the current EM parameters).

```sh
make copy-sparam SPARAM=sparx160_bpf
make copy-sparam SPARAM=sparx160_wpd
make copy-sparam SPARAM=sparx160_blc
```


### S-Parameter to Lumped Element Netlist Conversion

Converts an S-parameter Touchstone file into a lumped element (LE) netlist with [snp2le](https://github.com/iic-jku/snp2le). The conversion performs a universal rational fit of the given order and writes a passivity-enforced `.subckt` model that can be resimulated in place of the full EM S-parameter model. The de-embedded EM results (`*_deembedded.sNp`, see `copy-sparam`) are always used as input.

- `SNP` is the input Touchstone file (default: the de-embedded BPF EM result `verification/em/s-parameter/sparx160_bpf_deembedded.s2p`).
- `ORDER` sets the maximum model order (number of poles) of the universal fit (default: `13`).
- `LE_FORMAT` selects the output dialect: `spice` (ngspice, `.spice`) or `spectre` (VACASK, `.inc`) (default: `spice`).
- `LE_OUT` sets the output netlist path, which also names the `.subckt` (default: `netlist/spice/sparx_bpf_le.spice`). If set to an empty value, it falls back to `netlist/spice/<name>_le.spice` for `spice` or `netlist/spectre/<name>_le.inc` for `spectre`, where `<name>` is the input file name without its Touchstone extension.

Running `make snp2le` without arguments reproduces the BPF conversion (first example below). The commands used to generate the LE netlists in `netlist/spice/` are:

```sh
make snp2le SNP=verification/em/s-parameter/sparx160_bpf_deembedded.s2p ORDER=13 LE_FORMAT=spice LE_OUT=netlist/spice/sparx_bpf_le.spice
make snp2le SNP=verification/em/s-parameter/sparx160_wpd_deembedded.s3p ORDER=10 LE_FORMAT=spice LE_OUT=netlist/spice/sparx_wpd_le.spice
make snp2le SNP=verification/em/s-parameter/sparx160_blc_deembedded.s4p ORDER=6 LE_FORMAT=spice LE_OUT=netlist/spice/sparx_blc_le.spice
make snp2le SNP=verification/em/s-parameter/sparx160_core_deembedded.s7p ORDER=24 LE_FORMAT=spice LE_OUT=netlist/spice/sparx_core_le.spice
```


### Six-Port Core EM Flow

Runs the complete six-port core EM flow in one target: EM simulation of the core (`sim-sparx-core-em`), copying of the raw and de-embedded S-parameters (`copy-sparam`), lumped element fitting with snp2le (`ORDER=24`, in both SPICE and Spectre dialects), and AC S-parameter simulation of the six-port core testbenches (`sparx_core_tb_acsp_ngspice` and `sparx_core_tb_acsp_vacask`).

This target is intentionally not part of `make all` because the seven-port full-core EM simulation has a very long runtime. It starts from `verification/em/layout/sparx<FREQ>_core.gds`, so run `build-layout` for the target frequency first (the 160 GHz core is committed to the repository).

```sh
make sparx-core
make build-layout FREQ=77 && make sparx-core FREQ=77
```


### Xschem Testbench Simulation

Runs a single Xschem testbench in batch mode (no display): it saves the schematic, exports the netlist to `testbenches/xschem/simulations/`, and runs the simulator. The testbench is selected with the `TB` variable, given without the `.sch` extension (default: `sparx_bpf_le_tb_acsp_ngspice`). The netlist format and simulator are derived automatically from the testbench name: names ending in `_ngspice` are netlisted as SPICE and simulated with ngspice, while names ending in `_vacask` are netlisted as Spectre and simulated with VACASK.

The target netlists with `xschem netlist` and then invokes the simulator directly in batch mode (`ngspice -b` for the `.spice` benches, `vacask -qp -sp` for the `.spectre` benches) instead of `xschem simulate`. For ngspice, `xschem simulate` would launch an interactive ngspice in a terminal detached from make (`$terminal -e 'ngspice -i ...'`): the target would return while ngspice waits at its prompt, the result would never be checked, and the process (with its X server) would leak. Running the simulator directly makes `make` block until the run finishes and see its exit status.

VACASK is run with `-qp` (quiet progress, appropriate for a batch run) and `-sp` (skip postprocessing): the postprocess scripts that the VACASK testbenches declare are run by the Makefile right after the simulation instead. This bypasses VACASK's own subprocess launcher, which aborts with a `boost::asio` "Bad file descriptor" error on hosts whose kernel or container runtime blocks the syscalls it uses to spawn and await a child process. The `postprocess(PYTHON, ...)` lines stay in the testbenches, so running them from the Xschem GUI still postprocesses as usual.

`sim-xschem` also writes the FET operating-point save file `simulations/<TB>.save` (`write_data [save_params]`) while netlisting, for every testbench. That file lists the operating-point parameters of every transistor (`ids`, `gm`, `gds`, `vth` and so on), which the `annotate_fet_params` symbols and the `Annotate OP` launcher read back from the raw file. The testbenches that contain transistors pull it in by its bare file name, so it resolves inside `testbenches/xschem/simulations/`, where the simulator runs: the ngspice benches of the power detector and of the two top-level transient simulations through a `SAVE` code block (`.include <TB>.save`), the VACASK benches of the power detector through `include "<TB>.save"` in their control block. The `Simulate` launcher of every testbench writes the same file before it starts the simulator, so the file always matches the devices currently in the schematic, no `.save` file is tracked by git, and a fresh clone needs no manual export. Xschem's **IHP > Create FET .save file** menu entry writes the same file by hand.

```sh
make sim-xschem                                  # run the default testbench (sparx_bpf_le_tb_acsp_ngspice)
make sim-xschem TB=sparx_bpf_le_tb_acsp_ngspice
make sim-xschem TB=sparx_bpf_le_tb_acsp_vacask
make sim-xschem TB=sparx_powdet_sbd_tb_ngspice
make sim-xschem TB=sparx_powdet_sbd_tb_hb_vacask
```

Because `sim-xschem` runs headless, ngspice runs in batch mode (`ngspice -b`), where the `plot` commands in a testbench's `.control` block are a no-op, so no plot windows appear. Every testbench instead exports its result table to `testbenches/xschem/plot_simulations/data/`. The VACASK testbenches additionally write PNG plots to `testbenches/xschem/plot_simulations/figures/` during `sim-xschem` via their postprocess scripts.

### View Xschem Testbench Results

To view a testbench's results on screen, use `sim-view-xschem` after running the simulation with `sim-xschem`. It runs a plotting script from `testbenches/xschem/plot_simulations/` (`SIM_PLOT_DIR`), selected with the `SCRIPT` variable, given without the `.py` extension (default: `plot_n_port_tb_acsp_ngspice`), and reproduces the plots of the testbenches' `.control` blocks with matplotlib from the exported data in `xschem/plot_simulations/data/`, following the `plot_simulations` structure of the [ihp-sg13g2-ams-chip-template](https://github.com/iic-jku/ihp-sg13g2-ams-chip-template):

```sh
make sim-view-xschem                             # run the default plotting script (plot_n_port_tb_acsp_ngspice)
make sim-view-xschem SCRIPT=plot_n_port_tb_acsp_ngspice
make sim-view-xschem SCRIPT=plot_n_port_tb_tran_ngspice
```

- `plot_n_port_tb_acsp_ngspice.py` serves every acsp (AC S-parameter) testbench regardless of port count: it reads the wrdata tables `xschem/plot_simulations/data/*_tb_acsp_ngspice.txt` that the testbenches export and plots every S-parameter as magnitude/phase over frequency, one figure per testbench. An N-port testbench has N x N S-parameters (49 for the six-port core), which is unreadable in a single pair of axes, so the figure is **split by excitation port**: one column of axes per driven port j, magnitude on top and phase below, leaving only N traces per panel. The color encodes the receiving port i and is the same in every panel, so one legend serves the whole figure. Columns that are not a plain S(i,j), such as the differential combinations of the six-port core, are drawn in one extra panel on the right. The layout lives in `sparam_plot.py` and is shared with the VACASK script, so both flows are directly comparable.
- `plot_n_port_tb_tran_ngspice.py` serves the tran testbenches analogously, plotting every exported voltage over time.

Both load the wrdata columns with `ngspice2python.py` (the same helper module the [ihp-sg13g2-ams-chip-template](https://github.com/iic-jku/ihp-sg13g2-ams-chip-template) plotting scripts use), and both accept an optional testbench name to plot a single bench instead of all of them (e.g. `python3 testbenches/xschem/plot_simulations/plot_n_port_tb_acsp_ngspice.py sparx_wpd_le_tb_acsp_ngspice`). The VACASK counterparts (`plot_n_port_tb_acsp_vacask.py` and the `plot_sparx_powdet_sbd_tb_hb_*_vacask.py` scripts) need no separate call to produce their figures: `sim-xschem` already runs them right after the VACASK simulation (see above), but **headless**, so they only write the PNGs. Selecting them here is what actually opens the plot windows on screen, because `sim-view-xschem` runs the script with `SHOW_PLOTS=1`:

```sh
make sim-view-xschem SCRIPT=plot_n_port_tb_acsp_vacask
make sim-view-xschem SCRIPT=plot_sparx_powdet_sbd_tb_hb_dBV-dBV_vacask
```

Every script writes its figures to `testbenches/xschem/plot_simulations/figures/`. Run through `sim-view-xschem`, the plot windows additionally open when a display is available (i.e. the container's X/VNC session). Headless, only the PNGs are written.

### Simulate All Testbenches

Runs all Xschem testbench simulations sequentially by invoking `sim-xschem` for each testbench:

```sh
make sim-all
```

The following testbenches are simulated:

- `sparx_bpf_le_tb_acsp_ngspice` / `sparx_bpf_le_tb_acsp_vacask`: bandpass filter LE model, AC S-parameter
- `sparx_wpd_le_tb_acsp_ngspice` / `sparx_wpd_le_tb_acsp_vacask`: Wilkinson power divider LE model, AC S-parameter
- `sparx_blc_le_tb_acsp_ngspice` / `sparx_blc_le_tb_acsp_vacask`: branch-line coupler LE model, AC S-parameter
- `sparx_core_le_tb_acsp_ngspice` / `sparx_core_le_tb_acsp_vacask`: six-port core LE model, AC S-parameter
- `sparx_core_tb_acsp_ngspice` / `sparx_core_tb_acsp_vacask`: six-port core built from the BPF, WPD, and BLC LE models, AC S-parameter
- `sparx_powdet_sbd_tb_ngspice`: SBD-based power detector (ngspice)
- `sparx_powdet_sbd_tb_hb_vacask`: SBD-based power detector, harmonic balance (VACASK)
- `sparx_powdet_sbd_tb_pss_vacask`: SBD-based power detector, single-tone periodic steady state (VACASK), fits the responsivity that the noise figure bench turns into an NEP
- `sparx_powdet_sbd_tb_nf_vacask`: SBD-based power detector, noise figure and NEP (VACASK), runs after the PSS bench


### Build, Simulate, and Verify All

Runs the complete design flow end to end:

1. `build-top` builds the PDK, generates the six-port layout, and renders the top-level GDS.
2. Verification of the SBD-based power detector cell with both flows, KLayout DRC, LVS, and PEX as well as Magic DRC, Magic + Netgen LVS, and Magic PEX, followed by KLayout DRC and Magic DRC of the top-level six-port.
3. EM simulation of the passive RF structures with AWS Palace (`sim-bpf-em`, `sim-wpd-em`, `sim-blc-em`).
4. Copying of the raw and de-embedded EM S-parameter results to `verification/em/s-parameter/` (`copy-sparam` for BPF, WPD, and BLC).
5. De-embedded S-parameter to lumped element netlist conversion with snp2le, in both SPICE and Spectre netlists, for the BPF, WPD, and BLC.
6. All Xschem testbench simulations (`sim-all`).

```sh
make all
```

> [!NOTE]
> This target runs the full-wave EM simulations and therefore has a long runtime. The snp2le conversions read the de-embedded Touchstone files in `verification/em/s-parameter/`, which are copied there from the Palace output by `copy-sparam`.

### Release

Copies the final top-level GDS from `layout/` to `release/v.<VERSION>/gds/`, the generated netlists into `release/v.<VERSION>/netlist/`, and the rendered images into `release/v.<VERSION>/img/`.

The following folders are exported:

- `layout/<TOP>.gds` -> `release/v.<VERSION>/gds/<TOP>.gds`
- `netlist/schematic` -> `release/v.<VERSION>/netlist/schematic`
- `netlist/layout` -> `release/v.<VERSION>/netlist/layout`
- `render/img/<TOP>_black.png` -> `release/v.<VERSION>/img/<TOP>_black.png`
- `render/img/<TOP>_white.png` -> `release/v.<VERSION>/img/<TOP>_white.png`
- `render/img/<TOP>_black_TM2.png` -> `release/v.<VERSION>/img/<TOP>_black_TM2.png`

Run with default version (`2.0.0`):

```sh
make release
```

Run with a custom version:

```sh
make release VERSION=2.1.0
```


### Regression

The `regression` target is the project's smoke test for the [IIC-OSIC-TOOLS](https://github.com/iic-jku/IIC-OSIC-TOOLS) environment. Its goal is to exercise **as many tools and flows** as possible with a short runtime. It is a tool/flow regression, not a design sign-off. The target is self-contained. It installs the GDSFactory PDK add-on itself (`build-top` runs `build-pdk` first), so a plain IIC-OSIC-TOOLS container is all it needs.

```sh
make regression
```

The default `regression` is run manually and as part of the IIC-OSIC-TOOLS release regression tests ([`_tests/22`](https://github.com/iic-jku/IIC-OSIC-TOOLS/tree/next_release/_tests/22)), which validate each IIC-OSIC-TOOLS release against real designs.

By default (`NIGHTLY_REGRESSION=0`), `regression` reuses the committed WPD Palace results and does not re-run the slow full-wave EM solve. The `regression-nightly` target is the full variant: it runs everything `regression` does **plus** the WPD AWS Palace EM solve (`sim-wpd-em`), so the copy, snp2le, and Xschem steps run on freshly generated EM data. Internally, `regression-nightly` just calls `regression` with `NIGHTLY_REGRESSION=1`, so `make regression-nightly` and `make regression NIGHTLY_REGRESSION=1` are equivalent.

```sh
make regression-nightly
```

This project's own continuous integration runs the full variant: the [`regression`](.github/workflows/regression.yml) GitHub Actions workflow runs `make regression-nightly` (including the EM solve) inside the `hpretl/iic-osic-tools` container nightly (and on manual dispatch), and its status is shown by the *Regression* badge at the top of this README. The scheduled run is gated so it only executes when there have been changes since the previous night.

To keep the runtime low while still covering most of the toolchain, the regression makes the following trade-offs:

- Only the small `sparx_powdet_sbd` power-detector cell is verified, not the full six-port top cell. KLayout DRC, KLayout LVS, and KLayout PEX are run. Magic DRC, Magic + Netgen LVS, and Magic PEX are run.
- The full-wave EM solve is not re-run by the default `regression`. The AWS Palace EM simulation of the Wilkinson power divider (WPD) is the slowest step, so `regression` reuses the committed WPD Palace results and only exercises the downstream flow: S-parameter copy and lumped-element conversion (SPICE and Spectre). Use `regression-nightly` (or `make sim-wpd-em`) to regenerate the EM results.
- Only one ngspice and one VACASK testbench are simulated (the Wilkinson power divider AC S-parameter benches).
- The layout is generated at a single frequency (160 GHz). No frequency sweep is run.
- Top-level LVS is not run (work in progress).

The following tools and flows are checked:

| Tool / flow | Where it is exercised |
| --- | --- |
| GDSFactory PDK add-on build (git clone + pip install) | `build-pdk` (via `build-top`) |
| GDSFactory (programmatic six-port layout generation) | `build-layout` (via `build-top`) |
| `sak-render.py` (GDS-to-image rendering) | `render-gds` (via `build-top`) |
| Xschem netlisting, KLayout DRC, KLayout LVS, KLayout PEX | `klayout-verify CELL=sparx_powdet_sbd` |
| Xschem netlisting, Magic DRC, Magic + Netgen LVS, Magic PEX | `magic-verify CELL=sparx_powdet_sbd` |
| GDSFactory + gds2palace meshing + AWS Palace EM solve | `sim-wpd-em` (`regression-nightly` only) |
| S-parameter result copy (raw + de-embedded) | `copy-sparam SPARAM=sparx160_wpd` |
| snp2le (de-embedded S-parameter to lumped element, SPICE + Spectre) | `snp2le SNP=..._deembedded.s3p ...` |
| Xschem netlisting + ngspice | `sim-xschem TB=sparx_wpd_le_tb_acsp_ngspice` |
| Xschem netlisting + VACASK | `sim-xschem TB=sparx_wpd_le_tb_acsp_vacask` |


### Clean

`make clean` deletes everything the targets of this Makefile generate. The sources stay untouched: the layout generator and helper scripts, the schematics, symbols and testbenches, the EM model scripts and the stackup documentation under `verification/em/`, the plotting scripts, the documentation sources and the notebook. Deleted are:

- `build/` (the GDSFactory scratch folder of `build-layout`)
- `layout/` (the six-port layouts of every frequency and the power detector)
- `verification/em/layout/`, `verification/em/palace_model/` and `verification/em/s-parameter/` (the EM structures, the Palace meshes and results, and the copied Touchstone files)
- `netlist/` (the schematic, layout and PEX netlists of the power detector, and the SPICE and Spectre lumped element netlists)
- `render/img/` (the chip renders)
- `verification/drc/` and `verification/lvs/`
- `schematic/xschem/simulations/`, `testbenches/xschem/simulations/` and the `plot_simulations/` outputs (`data/`, `figures/`, `__pycache__/`)
- the `__pycache__` folders under `scripts/` and `verification/em/scripts/`, and the kpex leftovers `*.nodes` and `*.sim` in the repository root

The GDSFactory PDK add-on (`IHP/` and `.venv/`, both git-ignored) is a tool installation rather than a build product, so `clean` keeps it and `build-pdk` replaces it anyway. The rendered documentation has its own target, `make -C doc clean`.

```sh
make clean
```

[`release/`](release/) is never deleted, so published versions survive a clean. Every target recreates the folders it writes to, so a full rebuild from a clean tree is:

```sh
make clean
make all
```

> [!WARNING]
> Most of these outputs are committed in this repository, so `make clean` leaves a large deletion set in `git status`. Run `git restore .` to get the tracked ones back if you did not mean to remove them. This includes the Palace results under `verification/em/palace_model/`: `make all` regenerates the BPF, WPD and BLC solves, but the seven-port core solve only comes back with `make sparx-core`, and the default `make regression` reuses the committed WPD result, so after a clean it fails at `copy-sparam` until that result is restored or regenerated with `make sim-wpd-em`.


## Cite This Work

```
@misc{2026_SPARX,
  author = {Dorrer, Simon and Kellerer-Pirklbauer, David and Pretl, Harald},
  month = apr,
  year = {2026},
  title = {{GitHub Repository for SPARX: An Open-Source, Automated, Programmatically Generated, Frequency-Scalable Six-Port Receiver in 130-nm CMOS}},
  url = {https://github.com/iic-jku/SG13CMOS_SPARX},
  doi = {10.5281/zenodo.19654232}
}
```


## Acknowledgements

This project is funded by the JKU/SAL [IWS Lab](https://research.jku.at/de/projects/jku-lit-sal-intelligent-wireless-systems-lab-iws-lab/), a collaboration of [Johannes Kepler University](https://jku.at) and [Silicon Austria Labs](https://silicon-austria-labs.com).

<table width="100%">
  <tr>
    <td align="left" width="50%">
      <a href="https://iic.jku.at" target="_blank">
        <img src="doc/fig/funding/iic-jku.svg" alt="Johannes Kepler University: Institute for Integrated Circuits and Quantum Computing" width="94%"/>
      </a>
    </td>
    <td align="right" width="50%">
      <a href="https://silicon-austria-labs.com" target="_blank">
        <img src="doc/fig/funding/silicon-austria-labs-logo.svg" alt="Silicon Austria Labs" width="94%"/>
      </a>
    </td>
  </tr>
</table>


## License

Licensed under the **Solderpad Hardware License v2.1**, see [`LICENSE`](LICENSE).
