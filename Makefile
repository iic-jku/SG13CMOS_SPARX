# Makefile for SPARX: An Automated, Programmatically Generated Frequency-Scalable Six-Port Receiver in 130-nm CMOS
#
# SPDX-FileCopyrightText: 2025-2026 The SPARX Team
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# ========================================================================

MAKEFILE_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

# Variables
TOP = sparx160_top
POWDET = sparx_powdet_sbd

.DEFAULT_GOAL := help

# PDK Guard
# Override with: make <target> REQUIRED_PDK=<pdk>, an empty value skips the check
REQUIRED_PDK ?= ihp-sg13g2

# Goals that do not read the PDK
PDK_FREE_GOALS = help clean

ifneq ($(REQUIRED_PDK),)
ifneq ($(filter-out $(PDK_FREE_GOALS),$(or $(MAKECMDGOALS),$(.DEFAULT_GOAL))),)
ifneq ($(PDK),$(REQUIRED_PDK))
$(error PDK is "$(PDK)", but this chip needs "$(REQUIRED_PDK)". Run `sak-pdk $(REQUIRED_PDK)` in this shell and retry, or pass REQUIRED_PDK= to skip this check)
endif
endif
endif
# ========================================================================


# Version for release target
# Override with: make <target> VERSION=<version>
VERSION ?= 2.0.0

# Extra options for the sak-open.py file browser (e.g. --all to include build outputs)
# Override with: make open OPEN_ARGS=<options>
OPEN_ARGS ?=

# Cell name for verification targets (default: top-level cell)
# Override with: make <target> CELL=<cellname>
CELL ?= $(TOP)

# PEX mode (1 = C-decoupled, 2 = C-coupled, 3 = full-RC)
# Override with: make <target> EXT_MODE=<1|2|3>
EXT_MODE ?= 3

# full-RC extresist threshold in mOhm (sak-pex.sh -t, only used in EXT_MODE=3; default: 1000 = 1 Ohm)
# Override with: make <target> THRESHOLD=<mOhm>
THRESHOLD ?= 1000

# full-RC extresist minres in mOhm (sak-pex.sh -r, only used in EXT_MODE=3; default: 100 = 0.1 Ohm)
# Override with: make <target> MINRES=<mOhm>
MINRES ?= 100

# full-RC extresist mindelay in ps (sak-pex.sh -y, only used in EXT_MODE=3; default: 0, gate by resistance)
# Override with: make <target> MINDELAY=<ps>
MINDELAY ?= 0

# KLayout DRC level: precheck, macro, or regular (sak-drc.sh -l, only used by klayout-drc; default: macro)
# Override with: make <target> DRC_LEVEL=<precheck|macro|regular>
DRC_LEVEL ?= macro

# Supply pins that the flat PEX extraction merges into one node, they are dropped from the generated <CELL>_pex.sym so it matches the extracted netlist.
# Empty by default: the power detector keeps vdd and vss as separate ports in both the Magic and the KPEX extraction. Pads that repeat a pin name are dropped down to one pin the same way, only the pin boxes go and the labels stay.
# Override with: make <target> PEX_MERGED_PINS="<pin> <pin> ..."
PEX_MERGED_PINS ?=

# Floating-point precision (significant digits) for Xschem's ev function
# Override with: make <target> EV_PRECISION=<digits>
EV_PRECISION ?= 5

# Power-detector design variant for the VACASK testbenches that instantiate the detector, the receiver bench
# sparx_top_le_tb_rx_vacask included, rewritten from the emitted netlist by scripts/powdet_variant.py: m1 (as
# fabricated, the default), m16 (Schottky diodes with 16 parallel cells), m1_pex (the fabricated design with its
# Magic full-RC parasitics, netlist/pex/<CELL>_magic_pex_3.spice). A variant runs in simulations/<VARIANT>/ and its
# plots and data files carry the variant as a suffix.
# Override with: make sim-xschem TB=sparx_powdet_sbd_tb_pss_vacask VARIANT=<m16|m1_pex>
VARIANT ?=

# Design frequency in GHz (default: 160)
# Override with: make build-layout FREQ=<frequency_in_GHz>
FREQ ?= 160

# Metal fill options for build-layout (0 = fill enabled, 1 = fill disabled)
# Override with: make build-layout NO_FILL=1 NO_FILL_M5=1
NO_FILL ?= 0
NO_FILL_M5 ?= 0

# Port settings for the EM simulation, passed to palace_sim.py.
# These describe the structures as scripts/six_port_gen.py builds them and must
# match signal_cross_section, ground_cross_section and Z0 there.
# Override with: make sim-blc-em SIGNAL_CROSS_SECTION=<metal> GROUND_CROSS_SECTION=<metal> Z0=<Ohms>
SIGNAL_CROSS_SECTION ?= TM2
GROUND_CROSS_SECTION ?= M5
Z0 ?= 50

# Palace number of processors for EM simulation
# Override with: make sim-blc-em NP=<num_processors>
NP ?= 4

# Frequency sweep in GHz
# Override with: make build-layout-sweep START_FREQ=<GHz> STOP_FREQ=<GHz> STEP_FREQ=<GHz>
START_FREQ ?= 60
STOP_FREQ ?= 300
STEP_FREQ ?= 20

# Base names of the EM structures that build-layout writes to verification/em/layout,
# and of every Palace output derived from them. Only the design frequency is encoded,
# so re-parametrizing a structure in scripts/six_port_gen.py does not rename anything.
# These must stay in sync with the write_em_gds() calls in scripts/six_port_gen.py.
BLC_EM_NAME  := sparx$(FREQ)_blc
WPD_EM_NAME  := sparx$(FREQ)_wpd
BPF_EM_NAME  := sparx$(FREQ)_bpf
CORE_EM_NAME := sparx$(FREQ)_core

# S-parameter to lumped element netlist conversion with snp2le (always the de-embedded EM result)
# Override with: make snp2le SNP=<file.sNp> ORDER=<N> LE_FORMAT=<spice|spectre> LE_OUT=<output_path>
SNP ?= $(EM_SPARAM_DIR)/$(BPF_EM_NAME)_deembedded.s2p
ORDER ?= 13
LE_FORMAT ?= spice
LE_OUT ?= netlist/spice/sparx_bpf_le.spice

# EM run name for the copy-sparam target (base name of the GDS/Touchstone files)
# Override with: make copy-sparam SPARAM=<em_run_name>
SPARAM ?= $(BLC_EM_NAME)

# Folder structure
XSCHEM_SCH_DIR  	:= schematic/xschem
LAY_DIR     		:= layout
SCRIPTS_DIR     	:= scripts
XSCHEM_TB_DIR   	:= testbenches/xschem
SIM_PLOT_DIR    	:= testbenches/xschem/plot_simulations
RELEASE_DIR			:= release
RENDER_IMG_DIR  	:= render/img
NET_SCH_DIR 		:= netlist/schematic
NET_LAY_DIR 		:= netlist/layout
NET_PEX_DIR 		:= netlist/pex
NET_SPICE_DIR 		:= netlist/spice
NET_SPECTRE_DIR 	:= netlist/spectre
LVS_RPT_DIR 		:= verification/lvs
DRC_RPT_DIR 		:= verification/drc
EM_RPT_DIR 			:= verification/em
EM_LAY_DIR 			:= verification/em/layout
EM_SPARAM_DIR 		:= verification/em/s-parameter
PALACE_SCRIPTS_DIR 	:= $(PDK_ROOT)/$(PDK)/libs.tech/palace/scripts


# Help Target
help: ## Show this help message
	@echo 'Usage: make <target> [CELL=<cellname>] [EXT_MODE=<1|2|3>] [THRESHOLD=<mOhm>] [MINRES=<mOhm>] [MINDELAY=<ps>] [DRC_LEVEL=<precheck|macro|regular>] [PEX_MERGED_PINS="<pin> ..."] [EV_PRECISION=<digits>] [FREQ=<GHz>] [START_FREQ=<GHz>] [STOP_FREQ=<GHz>] [STEP_FREQ=<GHz>] [NO_FILL=0|1] [NO_FILL_M5=0|1] [TB=<testbenchname>] [SCRIPT=<scriptname>] [VERSION=<version>] [OPEN_ARGS=<options>]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z0-9_.-]+:.*## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ''
	@echo 'CELL defaults to $(TOP). Override to verify subcells.'
	@echo 'EXT_MODE defaults to 3 (full-RC). 1=C-decoupled, 2=C-coupled.'
	@echo 'The extracted netlists carry the mode as suffix: netlist/pex/<CELL>_magic_pex_<EXT_MODE>.spice and <CELL>_klayout_pex_<EXT_MODE>.spice.'
	@echo 'THRESHOLD/MINRES/MINDELAY are full-RC (EXT_MODE=3) extresist settings for magic-pex (defaults 1000 mOhm / 100 mOhm / 0 ps, gating by resistance, the Magic defaults are 10000 / 1000 / 1).'
	@echo 'DRC_LEVEL defaults to macro. Sets the KLayout DRC level for klayout-drc (precheck|macro|regular).'
	@echo 'PEX_MERGED_PINS is empty by default. Lists the supply pins that the flat extraction merges, they are dropped from the generated PEX symbol.'
	@echo 'FREQ defaults to 160 (GHz). Override for build-layout.'
	@echo 'NO_FILL defaults to 0 (fill enabled). Set to 1 to disable metal fill.'
	@echo 'NO_FILL_M5 defaults to 0 (M5 fill enabled). Set to 1 to disable M5 ground fill.'
	@echo 'START_FREQ, STOP_FREQ, STEP_FREQ default to 60, 300, and 20 (GHz) for build-layout-sweep.'
	@echo 'EV_PRECISION defaults to 5 significant digits for Xschem ev function.'
	@echo 'TB selects the Xschem testbench for sim-xschem (default: sparx_bpf_le_tb_acsp_ngspice).'
	@echo 'SCRIPT selects the plotting script for sim-view-xschem (default: plot_n_port_tb_acsp_ngspice).'
	@echo 'VARIANT selects a power-detector design variant for sim-xschem (m16, m1_pex), empty runs the design as fabricated.'
	@echo 'snp2le: SNP=<file.sNp> ORDER=<N> LE_FORMAT=<spice|spectre> LE_OUT=<path>.'
	@echo 'EM sim: solves the structures written by build-layout to $(EM_LAY_DIR), so run build-layout first.'
	@echo 'EM sim: NP=<procs> Z0=<Ohms> SIGNAL_CROSS_SECTION=<metal> GROUND_CROSS_SECTION=<metal> are the port settings of the solve.'
	@echo 'view-em-sim: FILE_NAME=<name_with_extension>. copy-sparam: SPARAM=<em_run_name>. release: VERSION=<version>.'
	@echo 'regression is the fast tool/flow smoke test (committed EM result). regression-nightly also runs the WPD AWS Palace EM solve.'
	@echo 'VERSION defaults to $(VERSION). Used by the release target.'
	@echo 'OPEN_ARGS passes extra options to sak-open.py for the open target (e.g. --all).'
	@echo 'REQUIRED_PDK defaults to $(REQUIRED_PDK). Every target except help and clean aborts if $$PDK differs.'
.PHONY: help
# ================================================================================================


# Open Target
open: ## Open the design files of this folder in the sak-open.py file browser (needs the VNC/X11 desktop)
	sak-open.py $(OPEN_ARGS) .
.PHONY: open
# ================================================================================================


# Build Targets
build-pdk: ## Clone and install the GDSFactory PDK add-on (usage: make build-pdk)
	rm -rf IHP/
	git clone --depth 1 -b main https://github.com/iic-jku/IHP-GDSFactory-Addon.git IHP
	rm -rf .venv/
	/usr/bin/python3 -m venv --system-site-packages .venv
	. .venv/bin/activate && cd IHP && pip install .
.PHONY: build-pdk

build-layout: ## Build the six-port layout for a specific frequency (usage: make build-layout [FREQ=<GHz>] [NO_FILL=0|1] [NO_FILL_M5=0|1])
	. .venv/bin/activate && python3 $(SCRIPTS_DIR)/six_port_gen.py \
		$(LAY_DIR)/sparx$(FREQ)_top.gds $(LAY_DIR)/sparx_powdet_sbd.gds \
		--frequency $(FREQ)e9 \
		$(if $(filter 1,$(NO_FILL)),--no-fill) \
		$(if $(filter 1,$(NO_FILL_M5)),--no-fill-m5)
	rm -rf build/
.PHONY: build-layout

build-layout-sweep: ## Build frequency-scalable six-port layouts over a sweep (usage: make build-layout-sweep [START_FREQ=<GHz>] [STOP_FREQ=<GHz>] [STEP_FREQ=<GHz>] [NO_FILL=0|1] [NO_FILL_M5=0|1])
	bash -lc ' \
		for ghz in $$(seq $(START_FREQ) $(STEP_FREQ) $(STOP_FREQ)); do \
			echo "=== Running make build-layout for $${ghz} GHz ==="; \
			$(MAKE) build-layout FREQ=$${ghz} NO_FILL=$(NO_FILL) NO_FILL_M5=$(NO_FILL_M5); \
		done'
	rm -rf build/
.PHONY: build-layout-sweep

build-top: ## Build TOP cell (usage: make build-top [FREQ=<GHz>])
	$(MAKE) build-pdk
	$(MAKE) build-layout FREQ=$(FREQ)
	$(MAKE) render-gds FREQ=$(FREQ)
.PHONY: build-top
# ================================================================================================


# Rendering Target
render-gds: ## Render images from the GDS of the TOP cell using sak-render.py (usage: make render-gds [FREQ=<GHz>])
	mkdir -p $(RENDER_IMG_DIR)/
	sak-render.py -t ihp-sg13g2 -w 2048 -s 4 -o $(RENDER_IMG_DIR)/sparx$(FREQ)_top $(LAY_DIR)/sparx$(FREQ)_top.gds
	sak-render.py -t ihp-sg13g2 -w 2048 -s 4 -b black -l tm2,tv2,TopMetal2.filler,passiv -o $(RENDER_IMG_DIR)/sparx$(FREQ)_top_black_TM2 $(LAY_DIR)/sparx$(FREQ)_top.gds
.PHONY: render-gds
# ================================================================================================


# DRC Targets
klayout-drc-regular: ## Run regular DRC of the TOP cell (usage: make klayout-drc-regular)
	mkdir -p $(DRC_RPT_DIR)
	sak-drc.sh -d -k -l regular -w $(DRC_RPT_DIR) $(LAY_DIR)/$(TOP).gds
.PHONY: klayout-drc-regular

klayout-drc: ## Run KLayout DRC of the CELL cell (usage: make klayout-drc [CELL=<cellname>] [DRC_LEVEL=<precheck|macro|regular>])
	mkdir -p $(DRC_RPT_DIR)
	sak-drc.sh -d -k -l $(DRC_LEVEL) -w $(DRC_RPT_DIR) $(LAY_DIR)/$(CELL).gds
.PHONY: klayout-drc

magic-drc: ## Run Magic DRC of the CELL cell (usage: make magic-drc [CELL=<cellname>])
	mkdir -p $(DRC_RPT_DIR)
	sak-drc.sh -d -m -f "*" -w $(DRC_RPT_DIR) $(LAY_DIR)/$(CELL).gds
.PHONY: magic-drc
# ================================================================================================


# LVS Targets
klayout-lvs-netlist: ## Export CDL schematic netlist from Xschem for KLayout LVS (usage: make klayout-lvs-netlist [CELL=<cellname>] [EV_PRECISION=<digits>])
	mkdir -p $(NET_SCH_DIR)
	xschem -s -r -x -q --rcfile $(XSCHEM_SCH_DIR)/xschemrc --command ' \
		set spiceprefix 1; \
		set lvs_netlist 1; \
		set top_is_subckt 1; \
		set lvs_ignore 1; \
		set ev_precision $(EV_PRECISION); \
		set netlist_dir $(NET_SCH_DIR); \
		xschem set netlist_name [file tail [file rootname [xschem get current_name]]]_klayout.cdl; \
		xschem netlist \
	' $(XSCHEM_SCH_DIR)/$(CELL).sch
.PHONY: klayout-lvs-netlist

klayout-lvs: ## Run KLayout LVS of the CELL cell (usage: make klayout-lvs [CELL=<cellname>])
	$(MAKE) klayout-lvs-netlist CELL=$(CELL)
	mkdir -p $(LVS_RPT_DIR)
	mkdir -p $(NET_LAY_DIR)
	sak-lvs.sh -d -k -w $(LVS_RPT_DIR) -s $(NET_SCH_DIR)/$(CELL)_klayout.cdl -l $(LAY_DIR)/$(CELL).gds -c $(CELL)
	mv $(LVS_RPT_DIR)/$(CELL).klayout.lvs/$(CELL)_extracted.cir $(NET_LAY_DIR)/$(CELL)_klayout.cir
.PHONY: klayout-lvs

magic-lvs-netlist: ## Export SPICE schematic netlist from Xschem for Magic + Netgen LVS (usage: make magic-lvs-netlist [CELL=<cellname>] [EV_PRECISION=<digits>])
	mkdir -p $(NET_SCH_DIR)
	xschem -s -r -x -q --rcfile $(XSCHEM_SCH_DIR)/xschemrc --command ' \
		set spiceprefix 1; \
		set lvs_netlist 0; \
		set top_is_subckt 1; \
		set lvs_ignore 1; \
		set ev_precision $(EV_PRECISION); \
		set netlist_dir $(NET_SCH_DIR); \
		xschem set netlist_name [file tail [file rootname [xschem get current_name]]]_magic.spice; \
		xschem netlist \
	' $(XSCHEM_SCH_DIR)/$(CELL).sch
.PHONY: magic-lvs-netlist

magic-lvs: ## Run Magic + Netgen LVS of the CELL cell (usage: make magic-lvs [CELL=<cellname>])
	mkdir -p $(LVS_RPT_DIR)
	mkdir -p $(NET_LAY_DIR)
	$(MAKE) magic-lvs-netlist CELL=$(CELL)
	sak-lvs.sh -d -w $(LVS_RPT_DIR) -s $(NET_SCH_DIR)/$(CELL)_magic.spice -l $(LAY_DIR)/$(CELL).gds -c $(CELL)
	mv $(LVS_RPT_DIR)/$(CELL).magic.lvs/$(CELL).ext.spc $(NET_LAY_DIR)/$(CELL)_magic.ext.spc
.PHONY: magic-lvs
# ================================================================================================


# PEX Targets
symbol-pex: ## Build the Xschem PEX symbol <CELL>_pex.sym from <CELL>.sym (usage: make symbol-pex [CELL=<cellname>] [PEX_MERGED_PINS="<pin> ..."])
	@if [ ! -f $(XSCHEM_SCH_DIR)/$(CELL).sym ]; then \
		echo "No symbol $(XSCHEM_SCH_DIR)/$(CELL).sym found, skipping PEX symbol generation."; \
	else \
		sed 's/type=subcircuit/type=primitive/' $(XSCHEM_SCH_DIR)/$(CELL).sym > $(XSCHEM_SCH_DIR)/$(CELL)_pex.sym; \
		if ! grep -q 'type=primitive' $(XSCHEM_SCH_DIR)/$(CELL)_pex.sym; then \
			rm -f $(XSCHEM_SCH_DIR)/$(CELL)_pex.sym; \
			echo "ERROR: $(XSCHEM_SCH_DIR)/$(CELL).sym declares neither type=subcircuit nor type=primitive!"; \
			exit 1; \
		fi; \
		python3 $(SCRIPTS_DIR)/prune_pex_symbol.py $(XSCHEM_SCH_DIR)/$(CELL)_pex.sym --merged $(PEX_MERGED_PINS); \
		echo "Wrote $(XSCHEM_SCH_DIR)/$(CELL)_pex.sym (copy of $(CELL).sym with type=primitive)."; \
	fi
.PHONY: symbol-pex

klayout-pex: ## Run Parasitic Extraction with KPEX of the CELL cell (usage: make klayout-pex [CELL=<cellname>] [EXT_MODE=<1|2|3>])
	mkdir -p $(NET_PEX_DIR)
	$(MAKE) symbol-pex CELL=$(CELL)
	PDK_UNDERSCORED=$$(echo $$PDK | sed -e 's/-/_/g'); \
	case $(EXT_MODE) in \
		1) echo "WARNING: KPEX does not support C-decoupled (C) mode yet, using C-coupled (CC) mode instead."; KPEX_MODE=CC ;; \
		2) KPEX_MODE=CC ;; \
		3) KPEX_MODE=RC ;; \
		*) echo "Invalid EXT_MODE: $(EXT_MODE). Use 1, 2, or 3."; exit 1;; \
	esac; \
	kpex \
	--pdk $$PDK_UNDERSCORED \
	--cell $(CELL) \
	--schematic $(XSCHEM_SCH_DIR)/$(CELL).sch \
	--gds $(LAY_DIR)/$(CELL).gds \
	--magic \
	--magic_mode $$KPEX_MODE \
	--out_dir $(NET_PEX_DIR) \
	--out_spice $(NET_PEX_DIR)/$(CELL)_klayout_pex_$(EXT_MODE).spice
#	--2.5D
#	--mode $$KPEX_MODE
	sed -i 's/$(CELL)/$(CELL)_pex/g' $(NET_PEX_DIR)/$(CELL)_klayout_pex_$(EXT_MODE).spice
	rm -rf $(NET_PEX_DIR)/$(CELL)__$(CELL)
	rm -f $(CELL).nodes $(CELL).sim $(NET_PEX_DIR)/$(CELL).nodes $(NET_PEX_DIR)/$(CELL).sim
	rm -f $(NET_PEX_DIR)/$(CELL).ext $(NET_PEX_DIR)/$(CELL).res.ext
	@if [ -f $(XSCHEM_SCH_DIR)/$(CELL)_pex.sym ]; then \
		echo "Reordering pins in $(CELL)_klayout_pex_$(EXT_MODE).spice to match $(CELL)_pex.sym..."; \
		sak-pin-reorder.py $(XSCHEM_SCH_DIR)/$(CELL)_pex.sym $(NET_PEX_DIR)/$(CELL)_klayout_pex_$(EXT_MODE).spice --format spice; \
	else \
		echo "No symbol $(XSCHEM_SCH_DIR)/$(CELL)_pex.sym found, skipping pin reorder."; \
	fi
	python3 $(SCRIPTS_DIR)/check_pex_ports.py $(NET_PEX_DIR)/$(CELL)_klayout_pex_$(EXT_MODE).spice
.PHONY: klayout-pex

magic-pex: ## Run Parasitic Extraction with Magic of the CELL cell (usage: make magic-pex [CELL=<cellname>] [EXT_MODE=<1|2|3>] [THRESHOLD=<mOhm>] [MINRES=<mOhm>] [MINDELAY=<ps>])
	mkdir -p $(NET_PEX_DIR)
	$(MAKE) symbol-pex CELL=$(CELL)
	sak-pex.sh -d -m $(EXT_MODE) -n $(CELL)_pex -t $(THRESHOLD) -r $(MINRES) -y $(MINDELAY) -w $(NET_PEX_DIR) $(LAY_DIR)/$(CELL).gds
	mv $(NET_PEX_DIR)/$(CELL).pex.spice $(NET_PEX_DIR)/$(CELL)_magic_pex_$(EXT_MODE).spice
	rm -f $(NET_PEX_DIR)/pex_$(CELL).tcl
	@if [ -f $(XSCHEM_SCH_DIR)/$(CELL)_pex.sym ]; then \
		echo "Reordering pins in $(CELL)_magic_pex_$(EXT_MODE).spice to match $(CELL)_pex.sym..."; \
		sak-pin-reorder.py $(XSCHEM_SCH_DIR)/$(CELL)_pex.sym $(NET_PEX_DIR)/$(CELL)_magic_pex_$(EXT_MODE).spice --format spice; \
	else \
		echo "No symbol $(XSCHEM_SCH_DIR)/$(CELL)_pex.sym found, skipping pin reorder."; \
	fi
	python3 $(SCRIPTS_DIR)/check_pex_ports.py $(NET_PEX_DIR)/$(CELL)_magic_pex_$(EXT_MODE).spice
.PHONY: magic-pex
# ================================================================================================


# Verify Targets
klayout-verify: ## Verify the CELL cell with KLayout (usage: make klayout-verify [CELL=<cellname>])
	$(MAKE) klayout-drc CELL=$(CELL)
	$(MAKE) klayout-lvs CELL=$(CELL)
	$(MAKE) klayout-pex CELL=$(CELL)
.PHONY: klayout-verify

magic-verify: ## Verify the CELL cell with Magic (usage: make magic-verify [CELL=<cellname>])
	$(MAKE) magic-drc CELL=$(CELL)
	$(MAKE) magic-lvs CELL=$(CELL)
	$(MAKE) magic-pex CELL=$(CELL)
.PHONY: magic-verify
# ================================================================================================


# EM Simulation Targets
# All EM structures (BLC, WPD, BPF and six-port core, each with the Palace port
# markers on layers 201..207) are written to verification/em/layout by build-layout,
# so the simulation targets below only mesh and solve the existing GDS. This keeps
# the EM runs consistent with the structures instantiated in the top-level layout.
# The GDS file names encode only the design frequency, so the port settings of the
# EM solve are passed to palace_sim.py explicitly.
# $(1) = base name of the GDS in verification/em/layout (without the .gds suffix)
# $(2) = simulation script in verification/em/scripts (default: palace_sim.py)
define run-em-sim
	@test -f $(EM_LAY_DIR)/$(1).gds || { \
		echo "ERROR: $(EM_LAY_DIR)/$(1).gds not found. Run 'make build-layout FREQ=$(FREQ)' first."; \
		exit 1; \
	}
	. .venv/bin/activate && \
		python3 $(EM_RPT_DIR)/scripts/$(if $(2),$(2),palace_sim.py) $(abspath $(EM_LAY_DIR)/$(1).gds) \
			--f_center $(FREQ)e9 \
			--signal_cross_section $(SIGNAL_CROSS_SECTION) \
			--ground_cross_section $(GROUND_CROSS_SECTION) \
			--Z0 $(Z0) && \
		cd $(EM_RPT_DIR)/palace_model/$(1)_data && \
		palace -np $(NP) config.json && \
		python3 $(PALACE_SCRIPTS_DIR)/combine_extend_snp.py
endef

sim-blc-em: ## Run the BLC EM simulation with AWS Palace (usage: make sim-blc-em [FREQ=<GHz>] [SIGNAL_CROSS_SECTION=<metal>] [GROUND_CROSS_SECTION=<metal>] [Z0=<Ohms>] [NP=<num_processors>])
	$(call run-em-sim,$(BLC_EM_NAME))
.PHONY: sim-blc-em

sim-wpd-em: ## Run the WPD EM simulation with AWS Palace (usage: make sim-wpd-em [FREQ=<GHz>] [SIGNAL_CROSS_SECTION=<metal>] [GROUND_CROSS_SECTION=<metal>] [Z0=<Ohms>] [NP=<num_processors>])
	$(call run-em-sim,$(WPD_EM_NAME))
.PHONY: sim-wpd-em

sim-bpf-em: ## Run the BPF EM simulation with AWS Palace (usage: make sim-bpf-em [FREQ=<GHz>] [SIGNAL_CROSS_SECTION=<metal>] [GROUND_CROSS_SECTION=<metal>] [Z0=<Ohms>] [NP=<num_processors>])
	$(call run-em-sim,$(BPF_EM_NAME))
.PHONY: sim-bpf-em

sim-sparx-core-em: ## Run the six-port core EM simulation with AWS Palace (usage: make sim-sparx-core-em [FREQ=<GHz>] [SIGNAL_CROSS_SECTION=<metal>] [GROUND_CROSS_SECTION=<metal>] [Z0=<Ohms>] [NP=<num_processors>])
	$(call run-em-sim,$(CORE_EM_NAME),six_port_core_palace_sim.py)
.PHONY: sim-sparx-core-em
# ================================================================================================


# View EM Simulation Results Target
FILE_NAME ?= $(BLC_EM_NAME).s4p
view-em-sim: ## View EM simulation results with s-parameter plots (usage: make view-em-sim FILE_NAME=<name_with_extension>)
	cd $(EM_RPT_DIR)/palace_model && python3 ../scripts/plot_snp.py $$(find . -type f -name "$(FILE_NAME)")
.PHONY: view-em-sim
# ================================================================================================


# Copy S-Parameter Target
copy-sparam: ## Copy the raw and de-embedded Touchstone files of an EM run to verification/em/s-parameter (usage: make copy-sparam SPARAM=<em_run_name>)
	mkdir -p $(EM_SPARAM_DIR)/
	cp -f $(EM_RPT_DIR)/palace_model/$(SPARAM)_data/output/$(SPARAM)/$(SPARAM).s*p $(EM_SPARAM_DIR)/
	cp -f $(EM_RPT_DIR)/palace_model/$(SPARAM)_data/output/$(SPARAM)/$(SPARAM)_deembedded.s*p $(EM_SPARAM_DIR)/
.PHONY: copy-sparam
# ================================================================================================


# Netlist Conversion Target
snp2le: ## Convert an S-parameter Touchstone file to a lumped element netlist via a universal fit (usage: make snp2le SNP=<file.sNp> [ORDER=<N>] [LE_FORMAT=<spice|spectre>] [LE_OUT=<path>])
	@if [ -z "$(SNP)" ]; then echo "ERROR: set the input Touchstone file, e.g. make snp2le SNP=verification/em/s-parameter/sparx160_blc_deembedded.s4p"; exit 1; fi
	case "$(LE_FORMAT)" in \
		spice)   SNP2LE_FORMAT=ngspice; DEFAULT_OUT=$(NET_SPICE_DIR)/$$(basename $(SNP) | sed -E 's/\.s[0-9]+p$$//I')_le.spice ;; \
		spectre) SNP2LE_FORMAT=vacask;  DEFAULT_OUT=$(NET_SPECTRE_DIR)/$$(basename $(SNP) | sed -E 's/\.s[0-9]+p$$//I')_le.inc ;; \
		*) echo "Invalid LE_FORMAT: $(LE_FORMAT). Use spice or spectre."; exit 1 ;; \
	esac; \
	OUT="$(LE_OUT)"; \
	if [ -z "$$OUT" ]; then OUT="$$DEFAULT_OUT"; fi; \
	mkdir -p "$$(dirname "$$OUT")"; \
	snp2le -b convert $(SNP) --mode universal --order $(ORDER) --format $$SNP2LE_FORMAT -o "$$OUT"
.PHONY: snp2le
# ================================================================================================


# Xschem Simulation Targets
# Testbench for sim-xschem (default: the bandpass filter AC S-parameter bench, the same block the snp2le default converts)
# Override with: make <target> TB=<testbenchname>
TB ?= sparx_bpf_le_tb_acsp_ngspice
# Plotting script for sim-view-xschem (default: the script that serves every acsp ngspice bench)
# Override with: make <target> SCRIPT=<scriptname>
SCRIPT ?= plot_n_port_tb_acsp_ngspice

sim-xschem: ## Run a testbench simulation with Xschem in batch mode (usage: make sim-xschem [TB=<testbenchname>])
	mkdir -p $(XSCHEM_TB_DIR)/simulations
	mkdir -p $(SIM_PLOT_DIR)/data
	cd $(XSCHEM_TB_DIR) && xschem -r -x -q --rcfile xschemrc --command ' \
		xschem set netlist_type $(if $(findstring _vacask,$(TB)),spectre,spice); \
		set netlist_dir $(abspath $(XSCHEM_TB_DIR)/simulations); \
		xschem save; \
		write_data [save_params] $(abspath $(XSCHEM_TB_DIR)/simulations)/$(TB).save; \
		xschem netlist \
	' $(TB).sch
# 	With VARIANT set, the emitted netlist is rewritten into the design variant and run in its own directory.
	$(if $(VARIANT),python3 $(SCRIPTS_DIR)/powdet_variant.py --variant $(VARIANT) $(XSCHEM_TB_DIR)/simulations/$(TB).spectre $(XSCHEM_TB_DIR)/simulations/$(VARIANT)/$(TB).spectre && cp $(XSCHEM_TB_DIR)/simulations/$(TB).save $(XSCHEM_TB_DIR)/simulations/$(VARIANT)/)
	cd $(XSCHEM_TB_DIR)/simulations/$(VARIANT) && $(if $(findstring _vacask,$(TB)),vacask -qp -sp $(TB).spectre </dev/null,ngspice -b $(TB).spice)
# 	VACASK runs with -sp, so its postprocess scripts are run here instead.
#	POWDET_VARIANT tells the power-detector scripts which directory to read and which suffix to write.
	$(if $(findstring _acsp_vacask,$(TB)),python3 $(SIM_PLOT_DIR)/plot_n_port_tb_acsp_vacask.py)
	$(if $(findstring _hb_vacask,$(TB)),python3 $(SIM_PLOT_DIR)/plot_sparx_powdet_sbd_tb_hb_dBV-dBV_vacask.py)
	$(if $(findstring _hb_vacask,$(TB)),python3 $(SIM_PLOT_DIR)/plot_sparx_powdet_sbd_tb_hb_V-W_vacask.py)
	$(if $(findstring _pss_vacask,$(TB)),POWDET_VARIANT=$(VARIANT) python3 $(SIM_PLOT_DIR)/plot_sparx_powdet_sbd_tb_pss_vacask.py)
	$(if $(findstring _nf_vacask,$(TB)),POWDET_VARIANT=$(VARIANT) python3 $(SIM_PLOT_DIR)/plot_sparx_powdet_sbd_tb_nf_vacask.py)
	$(if $(findstring _tn_vacask,$(TB)),POWDET_VARIANT=$(VARIANT) python3 $(SIM_PLOT_DIR)/plot_sparx_powdet_sbd_tb_tn_vacask.py)
	$(if $(findstring _rx_vacask,$(TB)),POWDET_VARIANT=$(VARIANT) python3 $(SIM_PLOT_DIR)/plot_sparx_top_le_tb_rx_vacask.py)
.PHONY: sim-xschem

sim-powdet-variants: ## Run the power-detector PSS and NF testbenches for the m16 and m1_pex design variants (usage: make sim-powdet-variants)
	$(MAKE) sim-xschem TB=sparx_powdet_sbd_tb_pss_vacask VARIANT=m16
	$(MAKE) sim-xschem TB=sparx_powdet_sbd_tb_nf_vacask VARIANT=m16
	$(MAKE) sim-xschem TB=sparx_powdet_sbd_tb_pss_vacask VARIANT=m1_pex
	$(MAKE) sim-xschem TB=sparx_powdet_sbd_tb_nf_vacask VARIANT=m1_pex
.PHONY: sim-powdet-variants

sim-view-xschem: ## Plot Xschem simulation results (usage: make sim-view-xschem [SCRIPT=<scriptname>])
	SHOW_PLOTS=1 python3 $(SIM_PLOT_DIR)/$(SCRIPT).py
.PHONY: sim-view-xschem

sim-all: ## Run all Xschem testbench simulations (usage: make sim-all)
	$(MAKE) sim-xschem TB=sparx_bpf_le_tb_acsp_ngspice
	$(MAKE) sim-xschem TB=sparx_bpf_le_tb_acsp_vacask
	$(MAKE) sim-xschem TB=sparx_wpd_le_tb_acsp_ngspice
	$(MAKE) sim-xschem TB=sparx_wpd_le_tb_acsp_vacask
	$(MAKE) sim-xschem TB=sparx_blc_le_tb_acsp_ngspice
	$(MAKE) sim-xschem TB=sparx_blc_le_tb_acsp_vacask
	$(MAKE) sim-xschem TB=sparx_core_le_tb_acsp_ngspice
	$(MAKE) sim-xschem TB=sparx_core_le_tb_acsp_vacask
	$(MAKE) sim-xschem TB=sparx_core_tb_acsp_ngspice
	$(MAKE) sim-xschem TB=sparx_core_tb_acsp_vacask
	$(MAKE) sim-xschem TB=sparx_powdet_sbd_tb_ngspice
	$(MAKE) sim-xschem TB=sparx_powdet_sbd_tb_hb_vacask
# 	PSS before NF: the PSS testbench fits the responsivity that the NF testbench turns into an NEP.
#	The design variants (16 diode cells, and the fabricated design with its layout parasitics) follow the fabricated design.
	$(MAKE) sim-xschem TB=sparx_powdet_sbd_tb_pss_vacask
	$(MAKE) sim-xschem TB=sparx_powdet_sbd_tb_nf_vacask
	$(MAKE) sim-powdet-variants
# 	Receiver level: the full-core fit driving the four detectors, as fabricated and post-layout, in VACASK (HB, HBAC, two-tone HB and transient in one bench), and the two ngspice transients of the composed and the full-core model.
	$(MAKE) sim-xschem TB=sparx_top_le_tb_rx_vacask
	$(MAKE) sim-xschem TB=sparx_top_le_tb_rx_vacask VARIANT=m1_pex
	$(MAKE) sim-xschem TB=sparx_top_le_tb_tran_ngspice
	$(MAKE) sim-xschem TB=sparx_top_tb_tran_ngspice
.PHONY: sim-all
# ================================================================================================


# Six-Port Core EM Flow Target
sparx-core: ## Run the six-port core EM flow: EM simulation, S-parameter copy, LE fit with ORDER=24, and core testbench simulation (usage: make sparx-core [FREQ=<GHz>])
	$(MAKE) sim-sparx-core-em
	$(MAKE) copy-sparam SPARAM=sparx$(FREQ)_core
	$(MAKE) snp2le SNP=$(EM_SPARAM_DIR)/sparx$(FREQ)_core.s7p ORDER=24 LE_FORMAT=spice LE_OUT=netlist/spice/sparx_core_le.spice
	$(MAKE) snp2le SNP=$(EM_SPARAM_DIR)/sparx$(FREQ)_core.s7p ORDER=24 LE_FORMAT=spectre LE_OUT=netlist/spectre/sparx_core_le.inc
	$(MAKE) sim-xschem TB=sparx_core_tb_acsp_ngspice
	$(MAKE) sim-xschem TB=sparx_core_tb_acsp_vacask
.PHONY: sparx-core
# ================================================================================================


all: ## Build, verify, EM-simulate, extract LE models, and run all testbenches (usage: make all)
	$(MAKE) build-top
# 	Verification
	$(MAKE) klayout-verify CELL=$(POWDET)
	$(MAKE) magic-verify CELL=$(POWDET)
#	$(MAKE) klayout-verify
	$(MAKE) klayout-drc
#	$(MAKE) magic-verify
	$(MAKE) magic-drc
# 	EM simulation of the passive RF structures (BPF, WPD, BLC)
	$(MAKE) sim-bpf-em
	$(MAKE) sim-wpd-em
	$(MAKE) sim-blc-em
# 	Copy the raw and de-embedded S-parameter results (BPF, WPD, BLC) to verification/em/s-parameter
	$(MAKE) copy-sparam SPARAM=$(BPF_EM_NAME)
	$(MAKE) copy-sparam SPARAM=$(WPD_EM_NAME)
	$(MAKE) copy-sparam SPARAM=$(BLC_EM_NAME)
# 	De-embedded S-parameter to lumped element netlist conversion (SPICE and Spectre) for BPF, WPD, BLC
	$(MAKE) snp2le SNP=$(EM_SPARAM_DIR)/$(BPF_EM_NAME)_deembedded.s2p ORDER=13 LE_FORMAT=spice LE_OUT=netlist/spice/sparx_bpf_le.spice
	$(MAKE) snp2le SNP=$(EM_SPARAM_DIR)/$(BPF_EM_NAME)_deembedded.s2p ORDER=13 LE_FORMAT=spectre LE_OUT=netlist/spectre/sparx_bpf_le.inc
	$(MAKE) snp2le SNP=$(EM_SPARAM_DIR)/$(WPD_EM_NAME)_deembedded.s3p ORDER=10 LE_FORMAT=spice LE_OUT=netlist/spice/sparx_wpd_le.spice
	$(MAKE) snp2le SNP=$(EM_SPARAM_DIR)/$(WPD_EM_NAME)_deembedded.s3p ORDER=10 LE_FORMAT=spectre LE_OUT=netlist/spectre/sparx_wpd_le.inc
	$(MAKE) snp2le SNP=$(EM_SPARAM_DIR)/$(BLC_EM_NAME)_deembedded.s4p ORDER=6 LE_FORMAT=spice LE_OUT=netlist/spice/sparx_blc_le.spice
	$(MAKE) snp2le SNP=$(EM_SPARAM_DIR)/$(BLC_EM_NAME)_deembedded.s4p ORDER=6 LE_FORMAT=spectre LE_OUT=netlist/spectre/sparx_blc_le.inc
# 	Xschem testbench simulations
	$(MAKE) sim-all
.PHONY: all
# ================================================================================================


# Release Target
release: ## Copy the gds, netlist files and chip renders to the release folder (usage: make release VERSION=<version>)
	mkdir -p $(RELEASE_DIR)/v.$(VERSION)/gds
	mkdir -p $(RELEASE_DIR)/v.$(VERSION)/netlist
	mkdir -p $(RELEASE_DIR)/v.$(VERSION)/img
	cp -f $(LAY_DIR)/$(TOP).gds $(RELEASE_DIR)/v.$(VERSION)/gds/$(TOP).gds
	cp -r $(NET_SCH_DIR)/. $(RELEASE_DIR)/v.$(VERSION)/netlist/schematic
	cp -r $(NET_LAY_DIR)/. $(RELEASE_DIR)/v.$(VERSION)/netlist/layout
	cp -f $(RENDER_IMG_DIR)/$(TOP)_black.png $(RELEASE_DIR)/v.$(VERSION)/img/$(TOP)_black.png
	cp -f $(RENDER_IMG_DIR)/$(TOP)_white.png $(RELEASE_DIR)/v.$(VERSION)/img/$(TOP)_white.png
	cp -f $(RENDER_IMG_DIR)/$(TOP)_black_TM2.png $(RELEASE_DIR)/v.$(VERSION)/img/$(TOP)_black_TM2.png
.PHONY: release
# ================================================================================================


# Regression Targets
# NIGHTLY_REGRESSION toggles the WPD AWS Palace EM solve inside `regression`:
# - 0 (default) reuses the committed EM result
# - 1 runs sim-wpd-em first.
# The regression-nightly target sets it to 1.
NIGHTLY_REGRESSION ?= 0

regression: ## Regression test target for IIC-OSIC-TOOLS (usage: make regression [NIGHTLY_REGRESSION=1])
# 	GDSFactory programmatic six-port layout generation
	$(MAKE) build-top
# 	KLayout DRC, LVS, and kpex PEX of the power-detector cell.
	$(MAKE) klayout-verify CELL=$(POWDET)
# 	Magic DRC, Magic + Netgen LVS, and Magic PEX of the power-detector cell.
	$(MAKE) magic-verify CELL=$(POWDET)
# 	Optional AWS Palace EM solve (WPD), run only when NIGHTLY_REGRESSION=1 (regression-nightly).
	$(if $(filter 1,$(NIGHTLY_REGRESSION)),$(MAKE) sim-wpd-em)
# 	Copy the raw and de-embedded S-parameter results (WPD): the fresh sim-wpd-em output when
# 	NIGHTLY_REGRESSION=1, otherwise the committed Palace output.
	$(MAKE) copy-sparam SPARAM=$(WPD_EM_NAME)
# 	De-embedded S-parameter to lumped-element netlist conversion (WPD).
	$(MAKE) snp2le SNP=$(EM_SPARAM_DIR)/$(WPD_EM_NAME)_deembedded.s3p ORDER=10 LE_FORMAT=spice LE_OUT=netlist/spice/sparx_wpd_le.spice
	$(MAKE) snp2le SNP=$(EM_SPARAM_DIR)/$(WPD_EM_NAME)_deembedded.s3p ORDER=10 LE_FORMAT=spectre LE_OUT=netlist/spectre/sparx_wpd_le.inc
# 	Xschem netlisting + one ngspice and one VACASK AC S-parameter simulation.
	$(MAKE) sim-xschem TB=sparx_wpd_le_tb_acsp_ngspice
	$(MAKE) sim-xschem TB=sparx_wpd_le_tb_acsp_vacask
.PHONY: regression

regression-nightly: ## Nightly regression test target for IIC-OSIC-TOOLS (usage: make regression-nightly)
	$(MAKE) regression NIGHTLY_REGRESSION=1
.PHONY: regression-nightly
# ================================================================================================


# Clean Target
clean: ## Delete all generated files and folders (layouts, EM structures and results, netlists, render, DRC/LVS reports, simulation outputs)
	rm -rf build
	rm -rf $(LAY_DIR)
	rm -rf $(EM_LAY_DIR) $(EM_RPT_DIR)/palace_model $(EM_SPARAM_DIR)
	rm -rf $(NET_SCH_DIR) $(NET_LAY_DIR) $(NET_PEX_DIR) $(NET_SPICE_DIR) $(NET_SPECTRE_DIR)
	rm -rf $(RENDER_IMG_DIR)
	rm -rf $(DRC_RPT_DIR) $(LVS_RPT_DIR)
	rm -rf $(XSCHEM_SCH_DIR)/simulations $(XSCHEM_TB_DIR)/simulations
	rm -rf $(SIM_PLOT_DIR)/data $(SIM_PLOT_DIR)/figures $(SIM_PLOT_DIR)/__pycache__
	rm -rf $(SCRIPTS_DIR)/__pycache__ $(EM_RPT_DIR)/scripts/__pycache__
	rm -f *.nodes *.sim
.PHONY: clean
# ================================================================================================
