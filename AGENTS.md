# Repository conventions

Guidance for coding agents and contributors working in this repo (SPARX, a programmatically generated six-port receiver chip in IHP SG13G2).

## Reference template

The repo root follows the structure and tooling of the template https://github.com/iic-jku/ihp-sg13g2-ams-chip-template, extended with a GDSFactory layout generator and AWS Palace EM simulation. The template tutorial (https://iic-jku.github.io/ihp-sg13g2-ams-chip-template/index.html) explains the folder layout and the Makefile.
When adding a flow or a folder, mirror the template layout and its `Makefile` conventions.

## Environment

- Run every flow inside the IIC-OSIC-TOOLS container (https://github.com/iic-jku/IIC-OSIC-TOOLS), tag `2026.10` or later (`README.md`). CI uses `hpretl/iic-osic-tools:latest`.
- The PDK is `ihp-sg13g2`. `.designinit` exports `PDK` and the related variables, and `sak-pdk ihp-sg13g2` switches a running shell.
- The `Makefile` checks `$PDK` when it is parsed: every target except `help` and `clean` aborts if it is not `ihp-sg13g2`. Fix the PDK instead of passing `REQUIRED_PDK=`.
- `make build-pdk` clones the GDSFactory PDK add-on (`IHP-GDSFactory-Addon`) into `IHP/` and installs it into `.venv/` (both git-ignored). `build-layout` and the EM targets run in that `.venv`, so run `build-pdk` (or `build-top`) once first.

## Repository layout

| Path | Contents |
| --- | --- |
| `Makefile`, `README.md` | The single flow for the whole chip. `README.md` documents every target. |
| `scripts/` | `six_port_gen.py` (GDSFactory generator of the full layout), `powdet_variant.py`, `prune_pex_symbol.py`, `check_pex_ports.py`, `tie_pex_substrate.py`, `img2lay.py`, logo `assets/` |
| `layout/` | Generated GDS: `sparx<FREQ>_top.gds` for 60 to 300 GHz and the power detector `sparx_powdet_sbd.gds` |
| `schematic/xschem/` | Power detector and six-port schematics and symbols, symbols of the lumped-element (LE) models |
| `testbenches/xschem/` | ngspice and VACASK testbenches, `plot_simulations/` scripts with their `data/` and `figures/` |
| `netlist/` | `schematic`, `layout`, `pex` (power detector), `spice` and `spectre` (LE models from snp2le) |
| `verification/drc/`, `verification/lvs/` | DRC and LVS run folders |
| `verification/em/` | `layout/` (EM structures from `build-layout`), `metal_model/` (surface versus volume metal, the check and its scripts), `palace_model/` (Palace runs), `s-parameter/` (Touchstone files), `scripts/` (Palace drivers), `stackups/` (stackup notes) |
| `render/`, `release/v.<version>/`, `doc/` | Renders, published releases, Quarto documentation site |
| `sscs-ose-code-a-chip/` | ISSCC'27 Code-a-Chip notebook with its own copies of GDS and assets, not driven by the `Makefile` |
| `measurements/` | Lab measurement notes |

## Makefiles

- The root `Makefile` drives every flow, and `README.md` documents each target. Read it before changing a flow.
- It sets `.DEFAULT_GOAL := help`, and `make help` lists every target from its `## ` comment. Give every new target a `## ` comment.
- Variables are set with `?=` and overridden on the command line, for example `FREQ=<GHz>`, `CELL=<cell>`, `TB=<testbench>`, `VARIANT=<m16|m1_pex>`, `NP=<procs>`.
- There is no RTL and no cocotb testbench in this repo.
- Each folder with schematics has its own `xschemrc`, and the targets pass it with `--rcfile`. See "Xschem Configuration" in `README.md`.
- `doc/fig/targets_overview/targets_overview.drawio` draws the call tree of `make all` ("Makefile Structure" in `README.md`, `@fig-targets` in the documentation). After a change to `all`, `build-top`, the verify targets, `sparx-core` or `sim-all`, update the drawio and re-export the PNG, SVG and PDF together. The PDF render of the documentation uses the PDF next to the SVG, so a stale PDF ships even when the SVG is current.

## Build, simulate, verify

Run from the repo root. These are the narrow targets for checking a change. `make all` runs the Palace EM solves of the three blocks. `make sparx-core` (seven-port EM) is long enough that `all` runs it only with `WITH_CORE=1` (default `0`).

```sh
make help                                        # targets of the Makefile
make build-top                                   # build-pdk, build-layout at 160 GHz, render-gds
make build-layout FREQ=77 NO_FILL=1              # layout at another frequency, no metal fill
make klayout-verify CELL=sparx_powdet_sbd        # KLayout DRC, LVS, PEX
make magic-verify CELL=sparx_powdet_sbd          # Magic DRC, Netgen LVS, Magic PEX
make klayout-drc                                 # top cell at DRC_LEVEL=macro
make sim-wpd-em                                  # Palace EM of the WPD (sim-blc-em, sim-bpf-em likewise)
make copy-sparam SPARAM=sparx160_wpd             # Palace output to verification/em/s-parameter/
make snp2le SNP=verification/em/s-parameter/sparx160_wpd_deembedded.s3p ORDER=10 LE_FORMAT=spice LE_OUT=netlist/spice/sparx_wpd_le.spice
make sim-xschem TB=sparx_wpd_le_tb_acsp_vacask   # one testbench, simulator from the name suffix
make regression                                  # tool/flow smoke test, reuses the committed WPD EM result
```

## CI

- `.github/workflows/license-check.yml` runs `reuse lint` on pushes and pull requests to `main`.
- `.github/workflows/regression.yml` runs `make regression-nightly` (the regression plus the WPD Palace solve) at the repo root inside `hpretl/iic-osic-tools:latest`, nightly at 02:00 UTC if `main` has a commit from the last 25 h, and on manual dispatch. It is a tool/flow smoke test, not sign-off. "Regression" in `README.md` lists what it covers.
- `.github/workflows/quarto-publish.yml` renders `doc/` and publishes it to `gh-pages` on every push to `main`.

## Design conventions

- `scripts/six_port_gen.py` holds every structure parameter (filter, divider shape `wpd_shape`, substrate permittivity). Change it there, rerun `build-layout`, then rerun the EM target. The EM targets solve the structures `build-layout` wrote to `verification/em/layout/`, so layout and EM stay consistent. The `sparx_core_le_tb_acsp_*` and `sparx_top_le_tb_*` benches read the committed full-core fit, which only `make sparx-core` or `make all WITH_CORE=1` regenerates.
- EM file names encode only the frequency (`sparx<FREQ>_blc`, `_wpd`, `_bpf`, `_core`). `BLC_EM_NAME` and the other `*_EM_NAME` variables in the `Makefile` must stay in sync with the `write_em_gds()` calls in `six_port_gen.py`.
- The EM port settings `SIGNAL_CROSS_SECTION`, `GROUND_CROSS_SECTION` and `Z0` are passed to `palace_sim.py`, not read from the layout. They must match `signal_cross_section`, `ground_cross_section` and `Z0` in `six_port_gen.py`.
- The Palace process stackup comes from the PDK (`$PDK_ROOT/$PDK/libs.tech/palace/XML_stackup/legacy/`, or `workflow/` in PDKs that pin a gds2palace from before 2026-09-26) and is not vendored here. The drivers look in both folders. `verification/em/stackups/README.md` describes the options.
- The EM drivers use gds2palace's surface metal model (no `filled_metals`, no `External` on the `Conductivity` boundaries). `verification/em/metal_model/README.md` records why and what it costs in accuracy. Read it before changing either setting.
- snp2le fits the raw EM results (`sparx<FREQ>_<block>.sNp`, not `*_deembedded.sNp`), the full core in `sparx-core` with `LE_NOISE=thermal` (the core's thermal noise). The fit orders in use are in the `all` and `sparx-core` targets (BPF 13, WPD 10, BLC 6, core 24). The models only need to be passive inside the fitted 80 to 240 GHz band: the WPD fit reaches σ_max 1.618 at 679 GHz, and that is accepted.
- Testbench names end in `_ngspice` or `_vacask`, which selects the netlist format and the simulator in `sim-xschem`. VACASK runs with `-sp`, so `sim-xschem` calls the postprocess scripts itself by name pattern: a new kind of `_vacask` testbench needs its line there.
- Power-detector variants (`VARIANT=m16`, `VARIANT=m1_pex`) are rewritten from the emitted netlist by `scripts/powdet_variant.py` and run in `testbenches/xschem/simulations/<VARIANT>/`.
- ngspice runs headless with `-b`, so `plot` commands in a `.control` block do nothing. Testbenches export their results to `testbenches/xschem/plot_simulations/data/`, and `make sim-view-xschem SCRIPT=<script>` plots them.
- Keep `spectre_format` on every symbol. Without it the Spectre netlister drops the instances from VACASK netlists without a warning.
- `<cell>_pex.sym` is regenerated from `<cell>.sym` before every extraction. Edit `<cell>.sym`, never the generated copy.

## Traps

- Most build outputs are committed (GDS, netlists, Palace results, Touchstone files, reports, renders). Targets overwrite them, and `make clean` deletes them, `layout/` included. Check `git status` after a run, commit only what the change needs, and `git restore` the rest.
- After `make clean`, `make regression` fails at `copy-sparam` until the WPD Palace result is restored or regenerated with `make sim-wpd-em`. The seven-port core result only comes back with `make sparx-core`.
- `make snp2le` without `LE_OUT=` writes to `netlist/spice/sparx_bpf_le.spice`, whatever `SNP` is. Pass `LE_OUT=<path>`, or `LE_OUT=` (empty) for a name derived from the input.
- `make release` defaults to `VERSION=2.0.0` and overwrites the committed `release/v.2.0.0/`. Never run it without an explicit new `VERSION`.
- `make klayout-drc-regular` reports antenna violations that IHP waived for the tapeout (`KNOWN_ISSUES.md`). Top-level LVS is open (`ToDo.md`), so the regression verifies only `sparx_powdet_sbd`.
- `palace -np $(NP)` uses `NP=4` by default. Open MPI counts physical cores and aborts with "not enough slots" on smaller hosts: lower `NP` or set `OMPI_MCA_hwloc_base_use_hwthreads_as_cpus=1` as `regression.yml` does.
- The Code-a-Chip notebook downloads its runtime files from the `next_release` branch, while the copy submitted to ISSCC'27 is frozen. Do not delete `next_release`, do not move or rename the files below, and change their content only if a rerun of the notebook still gives the results its text quotes:
  - `sscs-ose-code-a-chip/SPARX_JKU_ISSCC2027.ipynb` (the Colab badge opens it) and `sscs-ose-code-a-chip/assets/`
  - the `.spectre` and `.save` netlists of `sparx_powdet_sbd_tb_{pss,nf,tn}_vacask` and `sparx_top_le_tb_{rx,nf}_vacask` in `testbenches/xschem/netlists/`, and their `plot_simulations/plot_<testbench>.py`
  - `sparx_powdet_sbd_beta.json`, `sparx_powdet_sbd_nf.json` and `sparx_top_le_rx.json` in `testbenches/xschem/plot_simulations/data/`
  - `netlist/spectre/sparx_core_le.inc`, `netlist/pex/sparx_powdet_sbd_magic_pex_3.spice`, `scripts/powdet_variant.py` and `verification/em/s-parameter/sparx160_core.s7p`
  - linked from the text: the headings 1, 3.2 to 3.5, 4.1 and 4.2 of `testbenches/xschem/README.md` (anchors), `sparx_powdet_sbd_nf_lo_compare.png` and `sparx_top_le_nf_compare.png` in `plot_simulations/figures/`, `KNOWN_ISSUES.md`, and `layout/sparx160_top.gds`
  - the folders of its sparse checkout: `testbenches/xschem/`, `netlist/`, `scripts/` and `verification/em/s-parameter/`

  `make clean`, `sim-xschem`, `sim-all`, `sparx-core`, `magic-pex` (or `magic-verify CELL=sparx_powdet_sbd`) and `build-layout` after a generator change rewrite some of them. `git restore` them unless the same change updates the notebook.

## License headers

The repo is licensed under the Solderpad Hardware License v2.1 (`LICENSE`), SPDX expression `Apache-2.0 WITH SHL-2.1`, and `reuse lint` must pass.

- Source files (Python, Makefiles, workflows) start with an SPDX header in `#` comments, below the shebang if there is one:

  ```
  # SPDX-FileCopyrightText: 2026 The SPARX Team
  # SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
  # Description: <one line>
  ```

- Team headers use `2026` or `2025-2026` as the year. The `Description:` line is what newer files carry (for example `scripts/check_pex_ports.py`). Do not paste the long Apache-2.0 boilerplate.
- Code derived from third-party sources keeps the original notice next to ours (`scripts/img2lay.py`).
- Files without a header (Markdown, notebooks, schematics, layouts, netlists, data, figures) are covered by path annotations in `REUSE.toml`. A new file without a header in a path no annotation covers fails `reuse lint`, so extend `REUSE.toml` in the same change.

## Writing style

These rules apply to documentation, code comments, commit messages, and pull request descriptions in this repo.

- No em-dashes, no double-hyphen dashes, and no semicolons in prose. Code is exempt. Use commas, colons, periods, or parentheses, and split long sentences instead.
- Plain, factual tone: numbers, paths, and verdicts over adjectives, no filler.
- Never hard-wrap prose at a fixed column. Put each sentence or paragraph on one line and let the editor wrap it. When editing, never reflow neighboring lines.
- Keep comments short and accurate: say what is non-obvious and why, never restate what the code already shows.
- Commits and pull requests carry no AI attribution: no `Co-Authored-By` trailers and no "generated with" lines for any coding agent.
