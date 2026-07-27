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

# Version for release target
# Override with: make <target> VERSION=<version>
VERSION ?= 2.0.0

# Cell name for verification targets (default: top-level cell)
# Override with: make <target> CELL=<cellname>
CELL ?= $(TOP)

# PEX mode (1 = C-decoupled, 2 = C-coupled, 3 = full-RC)
# Override with: make <target> EXT_MODE=<1|2|3>
EXT_MODE ?= 3

# full-RC extresist threshold in mOhm (sak-pex.sh -t, only used in EXT_MODE=3; default: 10000 = 10 Ohm)
# Override with: make <target> THRESHOLD=<mOhm>
THRESHOLD ?= 10000

# full-RC extresist minres in mOhm (sak-pex.sh -r, only used in EXT_MODE=3; default: 1000 = 1 Ohm)
# Override with: make <target> MINRES=<mOhm>
MINRES ?= 1000

# full-RC extresist mindelay in ps (sak-pex.sh -y, only used in EXT_MODE=3; default: 1; 0 = gate by resistance)
# Override with: make <target> MINDELAY=<ps>
MINDELAY ?= 1

# KLayout DRC level: precheck, macro, or regular (sak-drc.sh -l, only used by klayout-drc; default: macro)
# Override with: make <target> DRC_LEVEL=<precheck|macro|regular>
DRC_LEVEL ?= macro

# Floating-point precision (significant digits) for Xschem's ev function
# Override with: make <target> EV_PRECISION=<digits>
EV_PRECISION ?= 5

# Design frequency in GHz (default: 160)
# Override with: make build-layout FREQ=<frequency_in_GHz>
FREQ ?= 160

# Metal fill options for build-layout (0 = fill enabled, 1 = fill disabled)
# Override with: make build-layout NO_FILL=1 NO_FILL_M5=1
NO_FILL ?= 0
NO_FILL_M5 ?= 0

# Characteristic impedance and substrate parameters for EM simulation
# Override with: make sim-blc-em FREQ=<GHz> SIGNAL_CROSS_SECTION=<metal> GROUND_CROSS_SECTION=<metal> Z0=<Ohms> E_R=<relative_permittivity>
SIGNAL_CROSS_SECTION ?= TM2
GROUND_CROSS_SECTION ?= M5
Z0 ?= 50
E_R ?= 4.1

# BPF-specific filter parameters for EM simulation
# Override with: make sim-bpf-em BANDWIDTH=<GHz> FILTER_TYPE=<butter|cheby|ellip> FILTER_ORDER=<N> RIPPLE_DB=<dB>
BANDWIDTH ?= 1
FILTER_TYPE ?= butter
FILTER_ORDER ?= 3
RIPPLE_DB ?= 3

# Additional config parameter for the WPD simulation (C or U)
# Override with: make sim-wpd-em FREQ=<GHz> SIGNAL_CROSS_SECTION=<metal> GROUND_CROSS_SECTION=<metal> Z0=<Ohms> E_R=<relative_permittivity> CONFIG=<config_name>
CONFIG ?= U

# Palace number of processors for EM simulation
# Override with: make sim-blc-em NP=<num_processors>
NP ?= 4

# Frequency sweep in GHz
# Override with: make build-layout-sweep START_FREQ=<GHz> STOP_FREQ=<GHz> STEP_FREQ=<GHz>
START_FREQ ?= 60
STOP_FREQ ?= 300
STEP_FREQ ?= 20

# S-parameter to lumped element netlist conversion with snp2le (always the de-embedded EM result)
# Override with: make snp2le SNP=<file.sNp> ORDER=<N> LE_FORMAT=<spice|spectre> LE_OUT=<output_path>
SNP ?= verification/em/s-parameter/sparx_bpf_f_160GHz_bw_1GHz_sig_TM2_gnd_M5_z0_50Ohm_er_4_1_butter_ord_3_deembedded.s2p
ORDER ?= 13
LE_FORMAT ?= spice
LE_OUT ?= netlist/spice/sparx_bpf_le.spice

# EM run name for the copy-sparam target (base name of the GDS/Touchstone files)
# Override with: make copy-sparam SPARAM=<em_run_name>
SPARAM ?= sparx_blc_$(FREQ)GHz_$(Z0)Ohm_$(SIGNAL_CROSS_SECTION)_$(GROUND_CROSS_SECTION)_e_r_$(subst .,_,$(E_R))

# Folder structure
SCH_DIR     		:= schematic
LAY_DIR     		:= layout
SCRIPTS_DIR     	:= scripts
XSCHEM_TB_DIR   	:= testbenches
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
EM_SPARAM_DIR 		:= verification/em/s-parameter
PALACE_SCRIPTS_DIR 	:= $(PDK_ROOT)/$(PDK)/libs.tech/palace/scripts


# Help target
help: ## Show this help message
	@echo 'Usage: make <target> [CELL=<cellname>] [EXT_MODE=<1|2|3>] [THRESHOLD=<mOhm>] [MINRES=<mOhm>] [MINDELAY=<ps>] [DRC_LEVEL=<precheck|macro|regular>] [EV_PRECISION=<digits>] [FREQ=<GHz>] [START_FREQ=<GHz>] [STOP_FREQ=<GHz>] [STEP_FREQ=<GHz>] [NO_FILL=0|1] [NO_FILL_M5=0|1]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ''
	@echo 'CELL defaults to $(TOP). Override to verify subcells.'
	@echo 'EXT_MODE defaults to 3 (full-RC). 1=C-decoupled, 2=C-coupled.'
	@echo 'THRESHOLD/MINRES/MINDELAY are full-RC (EXT_MODE=3) extresist settings for magic-pex (defaults 10000 mOhm / 1000 mOhm / 1 ps).'
	@echo 'DRC_LEVEL defaults to macro. Sets the KLayout DRC level for klayout-drc (precheck|macro|regular).'
	@echo 'FREQ defaults to 160 (GHz). Override for build-layout.'
	@echo 'NO_FILL defaults to 0 (fill enabled). Set to 1 to disable metal fill.'
	@echo 'NO_FILL_M5 defaults to 0 (M5 fill enabled). Set to 1 to disable M5 ground fill.'
	@echo 'START_FREQ, STOP_FREQ, STEP_FREQ default to 60, 300, and 20 (GHz) for build-layout-sweep.'
	@echo 'EV_PRECISION defaults to 5 significant digits for Xschem ev function.'
	@echo 'TB selects the Xschem testbench for sim-xschem (e.g. sparx_bpf_le_tb_acsp_ngspice).'
	@echo 'snp2le: SNP=<file.sNp> ORDER=<N> LE_FORMAT=<spice|spectre> LE_OUT=<path>.'
	@echo 'EM sim: NP=<procs> Z0=<Ohms> E_R=<e_r> SIGNAL_CROSS_SECTION=<metal> GROUND_CROSS_SECTION=<metal>.'
	@echo 'sim-bpf-em: BANDWIDTH=<GHz> FILTER_TYPE=<butter|cheby|ellip> FILTER_ORDER=<N> RIPPLE_DB=<dB>. sim-wpd-em: CONFIG=<C|U>.'
	@echo 'view-em-sim: FILE_NAME=<name_with_extension>. copy-sparam: SPARAM=<em_run_name>. release: VERSION=<version>.'
	@echo 'regression is the fast tool/flow smoke test (committed EM result). regression-nightly also runs the WPD AWS Palace EM solve.'
.PHONY: help
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
render-gds: ## Render an image from the GDS of the TOP cell (usage: make render-gds [FREQ=<GHz>])
	mkdir -p $(RENDER_IMG_DIR)/
	python3 $(SCRIPTS_DIR)/lay2img.py $(LAY_DIR)/sparx$(FREQ)_top.gds $(RENDER_IMG_DIR)/sparx$(FREQ)_top.png --width 2048 --oversampling 4
.PHONY: render-gds
# ================================================================================================


# LVS Targets
klayout-lvs-netlist: ## Export CDL schematic netlist from Xschem for KLayout LVS (usage: make klayout-lvs-netlist [CELL=<cellname>] [EV_PRECISION=<digits>])
	mkdir -p $(NET_SCH_DIR)
	xschem -s -r -x -q --rcfile $(SCH_DIR)/xschemrc --command ' \
		set spiceprefix 1; \
		set lvs_netlist 1; \
		set top_is_subckt 1; \
		set lvs_ignore 1; \
		set ev_precision $(EV_PRECISION); \
		set netlist_dir $(NET_SCH_DIR); \
		xschem set netlist_name [file tail [file rootname [xschem get current_name]]]_klayout.cdl; \
		xschem netlist \
	' $(SCH_DIR)/$(CELL).sch
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
	xschem -s -r -x -q --rcfile $(SCH_DIR)/xschemrc --command ' \
		set spiceprefix 1; \
		set lvs_netlist 0; \
		set top_is_subckt 1; \
		set lvs_ignore 1; \
		set ev_precision $(EV_PRECISION); \
		set netlist_dir $(NET_SCH_DIR); \
		xschem set netlist_name [file tail [file rootname [xschem get current_name]]]_magic.spice; \
		xschem netlist \
	' $(SCH_DIR)/$(CELL).sch
.PHONY: magic-lvs-netlist

magic-lvs: ## Run Magic + Netgen LVS of the CELL cell (usage: make magic-lvs [CELL=<cellname>])
	mkdir -p $(LVS_RPT_DIR)
	mkdir -p $(NET_LAY_DIR)
	$(MAKE) magic-lvs-netlist CELL=$(CELL)
	sak-lvs.sh -d -w $(LVS_RPT_DIR) -s $(NET_SCH_DIR)/$(CELL)_magic.spice -l $(LAY_DIR)/$(CELL).gds -c $(CELL)
	mv $(LVS_RPT_DIR)/$(CELL).magic.lvs/$(CELL).ext.spc $(NET_LAY_DIR)/$(CELL)_magic.ext.spc
.PHONY: magic-lvs
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


# PEX Targets
klayout-pex: ## Run Parasitic Extraction with KPEX of the CELL cell (usage: make klayout-pex [CELL=<cellname>] [EXT_MODE=<1|2|3>])
	mkdir -p $(NET_PEX_DIR)
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
	--schematic $(SCH_DIR)/$(CELL).sch \
	--gds $(LAY_DIR)/$(CELL).gds \
	--magic \
	--magic_mode $$KPEX_MODE \
	--out_dir $(NET_PEX_DIR) \
	--out_spice $(NET_PEX_DIR)/$(CELL)_klayout_pex.spice
#	--2.5D
#	--mode $$KPEX_MODE
	sed -i 's/$(CELL)/$(CELL)_pex/g' $(NET_PEX_DIR)/$(CELL)_klayout_pex.spice
	rm -rf $(NET_PEX_DIR)/$(CELL)__$(CELL)
	rm -f $(CELL).nodes $(CELL).sim $(NET_PEX_DIR)/$(CELL).nodes $(NET_PEX_DIR)/$(CELL).sim
	rm -f $(NET_PEX_DIR)/$(CELL).ext $(NET_PEX_DIR)/$(CELL).res.ext
	@if [ -f $(SCH_DIR)/$(CELL)_pex.sym ]; then \
		echo "Reordering pins in $(CELL)_klayout_pex.spice to match $(CELL)_pex.sym..."; \
		python3 $(SCRIPTS_DIR)/reorder_spice_pins.py $(SCH_DIR)/$(CELL)_pex.sym $(NET_PEX_DIR)/$(CELL)_klayout_pex.spice; \
	else \
		echo "No symbol $(SCH_DIR)/$(CELL)_pex.sym found, skipping pin reorder."; \
	fi
.PHONY: klayout-pex

magic-pex: ## Run Parasitic Extraction with Magic of the CELL cell (usage: make magic-pex [CELL=<cellname>] [EXT_MODE=<1|2|3>] [THRESHOLD=<mOhm>] [MINRES=<mOhm>] [MINDELAY=<ps>])
	mkdir -p $(NET_PEX_DIR)
	sak-pex.sh -d -m $(EXT_MODE) -n $(CELL)_pex -t $(THRESHOLD) -r $(MINRES) -y $(MINDELAY) -w $(NET_PEX_DIR) $(LAY_DIR)/$(CELL).gds
	mv $(NET_PEX_DIR)/$(CELL).pex.spice $(NET_PEX_DIR)/$(CELL)_magic_pex.spice
	rm -f $(NET_PEX_DIR)/pex_$(CELL).tcl
	@if [ -f $(SCH_DIR)/$(CELL)_pex.sym ]; then \
		echo "Reordering pins in $(CELL)_magic_pex.spice to match $(CELL)_pex.sym..."; \
		python3 $(SCRIPTS_DIR)/reorder_spice_pins.py $(SCH_DIR)/$(CELL)_pex.sym $(NET_PEX_DIR)/$(CELL)_magic_pex.spice; \
	else \
		echo "No symbol $(SCH_DIR)/$(CELL)_pex.sym found, skipping pin reorder."; \
	fi
.PHONY: magic-pex
# ================================================================================================


# Verify Targets
klayout-verify: ## Verify the CELL cell with KLayout (usage: make klayout-verify [CELL=<cellname>])
	$(MAKE) klayout-lvs CELL=$(CELL)
	$(MAKE) klayout-drc CELL=$(CELL)
	$(MAKE) klayout-pex CELL=$(CELL)
.PHONY: klayout-verify

magic-verify: ## Verify the CELL cell with Magic (usage: make magic-verify [CELL=<cellname>])
	$(MAKE) magic-lvs CELL=$(CELL)
	$(MAKE) magic-drc CELL=$(CELL)
	$(MAKE) magic-pex CELL=$(CELL)
.PHONY: magic-verify
# ================================================================================================


# EM Simulation Targets
sim-blc-em: ## Run the BLC EM simulation with AWS Palace (usage: make sim-blc-em [FREQ=<GHz>] [SIGNAL_CROSS_SECTION=<metal>] [GROUND_CROSS_SECTION=<metal>] [Z0=<Ohms>] [E_R=<e_r>] [NP=<num_processors>])
	BLC_GDS_FILENAME=sparx_blc_$(FREQ)GHz_$(Z0)Ohm_$(SIGNAL_CROSS_SECTION)_$(GROUND_CROSS_SECTION)_e_r_$(subst .,_,$(E_R)); \
	. .venv/bin/activate && \
		python3 $(EM_RPT_DIR)/scripts/sparx_blc_em_sim.py \
			--frequency $(FREQ)e9 \
			--signal_cross_section $(SIGNAL_CROSS_SECTION) \
			--ground_cross_section $(GROUND_CROSS_SECTION) \
			--Z0 $(Z0) \
			--e_r $(E_R) && \
		python3 $(EM_RPT_DIR)/scripts/palace_sim.py ../layout/$$BLC_GDS_FILENAME.gds && \
		cd $(EM_RPT_DIR)/palace_model/$${BLC_GDS_FILENAME}_data && \
		palace -np $(NP) config.json && \
		python3 $(PALACE_SCRIPTS_DIR)/combine_extend_snp.py
.PHONY: sim-blc-em

sim-wpd-em: ## Run the WPD EM simulation with AWS Palace (usage: make sim-wpd-em [FREQ=<GHz>] [SIGNAL_CROSS_SECTION=<metal>] [GROUND_CROSS_SECTION=<metal>] [Z0=<Ohms>] [E_R=<e_r>] [CONFIG=<C|U>] [NP=<num_processors>])
	WPD_GDS_FILENAME=sparx_wpd_$(FREQ)GHz_$(Z0)Ohm_$(SIGNAL_CROSS_SECTION)_$(GROUND_CROSS_SECTION)_e_r_$(subst .,_,$(E_R))_config_$(CONFIG); \
	. .venv/bin/activate && \
		python3 $(EM_RPT_DIR)/scripts/sparx_wpd_em_sim.py \
			--frequency $(FREQ)e9 \
			--signal_cross_section $(SIGNAL_CROSS_SECTION) \
			--ground_cross_section $(GROUND_CROSS_SECTION) \
			--Z0 $(Z0) \
			--e_r $(E_R) \
			--config $(CONFIG) && \
		python3 $(EM_RPT_DIR)/scripts/palace_sim.py ../layout/$$WPD_GDS_FILENAME.gds && \
		cd $(EM_RPT_DIR)/palace_model/$${WPD_GDS_FILENAME}_data && \
		palace -np $(NP) config.json && \
		python3 $(PALACE_SCRIPTS_DIR)/combine_extend_snp.py
.PHONY: sim-wpd-em

sim-bpf-em: ## Run the BPF EM simulation with AWS Palace (usage: make sim-bpf-em [FREQ=<GHz>] [BANDWIDTH=<GHz>] [SIGNAL_CROSS_SECTION=<metal>] [GROUND_CROSS_SECTION=<metal>] [Z0=<Ohms>] [E_R=<e_r>] [FILTER_TYPE=<butter|cheby|ellip>] [FILTER_ORDER=<N>] [RIPPLE_DB=<dB>] [NP=<num_processors>])
	BPF_FILTER_TYPE_LOWER=$$(echo "$(FILTER_TYPE)" | tr '[:upper:]' '[:lower:]'); \
	if [ "$$BPF_FILTER_TYPE_LOWER" = "butter" ]; then \
		RIPPLE_TAG=""; \
	else \
		RIPPLE_DB_TAG=$$(printf '%s' "$(RIPPLE_DB)" | sed 's/\.0$$//'); \
		RIPPLE_TAG="_rip_$$(printf '%s' "$$RIPPLE_DB_TAG" | tr '.' '_')dB"; \
	fi; \
	BPF_GDS_FILENAME=sparx_bpf_f_$(FREQ)GHz_bw_$(BANDWIDTH)GHz_sig_$(SIGNAL_CROSS_SECTION)_gnd_$(GROUND_CROSS_SECTION)_z0_$(Z0)Ohm_er_$(subst .,_,$(E_R))_$(FILTER_TYPE)_ord_$(FILTER_ORDER)$$RIPPLE_TAG; \
	. .venv/bin/activate && \
		python3 $(EM_RPT_DIR)/scripts/sparx_bpf_em_sim.py \
			--frequency $(FREQ)e9 \
			--bandwidth $(BANDWIDTH)e9 \
			--signal_cross_section $(SIGNAL_CROSS_SECTION) \
			--ground_cross_section $(GROUND_CROSS_SECTION) \
			--Z0 $(Z0) \
			--e_r $(E_R) \
			--filter_type $(FILTER_TYPE) \
			--filter_order $(FILTER_ORDER) \
			--ripple_dB $(RIPPLE_DB) && \
		python3 $(EM_RPT_DIR)/scripts/palace_sim.py ../layout/$$BPF_GDS_FILENAME.gds && \
		cd $(EM_RPT_DIR)/palace_model/$${BPF_GDS_FILENAME}_data && \
		palace -np $(NP) config.json && \
		python3 $(PALACE_SCRIPTS_DIR)/combine_extend_snp.py
.PHONY: sim-bpf-em

sim-sparx-core-em: ## Run the six-port core EM simulation with AWS Palace (usage: make sim-sparx-core-em [FREQ=<GHz>] [SIGNAL_CROSS_SECTION=<metal>] [GROUND_CROSS_SECTION=<metal>] [Z0=<Ohms>] [E_R=<e_r>] [NP=<num_processors>])
# 	The core GDS filename does not encode the EM parameters, so they are passed to palace_sim.py explicitly.
	CORE_GDS_FILENAME=sparx$(FREQ)_core; \
	. .venv/bin/activate && \
		python3 $(EM_RPT_DIR)/scripts/sparx_core_em_sim.py \
			--frequency $(FREQ)e9 \
			--signal_cross_section $(SIGNAL_CROSS_SECTION) \
			--ground_cross_section $(GROUND_CROSS_SECTION) \
			--Z0 $(Z0) \
			--e_r $(E_R) && \
		python3 $(EM_RPT_DIR)/scripts/palace_sim.py ../layout/$$CORE_GDS_FILENAME.gds \
			--f_center $(FREQ)e9 \
			--signal_cross_section $(SIGNAL_CROSS_SECTION) \
			--ground_cross_section $(GROUND_CROSS_SECTION) \
			--Z0 $(Z0) && \
		cd $(EM_RPT_DIR)/palace_model/$${CORE_GDS_FILENAME}_data && \
		palace -np $(NP) config.json && \
		python3 $(PALACE_SCRIPTS_DIR)/combine_extend_snp.py
.PHONY: sim-sparx-core-em
# ================================================================================================


# View EM Simulation Results Target
FILE_NAME ?= sparx_blc_$(FREQ)GHz_$(Z0)Ohm_$(SIGNAL_CROSS_SECTION)_$(GROUND_CROSS_SECTION)_e_r_$(subst .,_,$(E_R)).s4p
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
	@if [ -z "$(SNP)" ]; then echo "ERROR: set the input Touchstone file, e.g. make snp2le SNP=verification/em/s-parameter/sparx_blc_160GHz_50Ohm_TM2_M5_e_r_4_1_deembedded.s4p"; exit 1; fi
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
sim-xschem: ## Run a testbench simulation with Xschem in batch mode (usage: make sim-xschem TB=<testbenchname>)
	mkdir -p $(XSCHEM_TB_DIR)/simulations
	cd $(XSCHEM_TB_DIR) && xschem -x -q --rcfile xschemrc --command ' \
		xschem set netlist_type $(if $(findstring _vacask,$(TB)),spectre,spice); \
		set netlist_dir $(abspath $(XSCHEM_TB_DIR)/simulations); \
		xschem save; \
		xschem netlist; \
		xschem simulate \
	' $(TB).sch
.PHONY: sim-xschem

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
.PHONY: sim-all
# ================================================================================================


# Six-Port Core EM Flow Target
sparx-core: ## Run the six-port core EM flow: EM simulation, S-parameter copy, LE fit with ORDER=24, and core testbench simulation (usage: make sparx-core [FREQ=<GHz>])
	$(MAKE) sim-sparx-core-em
	$(MAKE) copy-sparam SPARAM=sparx$(FREQ)_core
	$(MAKE) snp2le SNP=$(EM_SPARAM_DIR)/sparx$(FREQ)_core_deembedded.s7p ORDER=24 LE_FORMAT=spice LE_OUT=netlist/spice/sparx_core_le.spice
	$(MAKE) snp2le SNP=$(EM_SPARAM_DIR)/sparx$(FREQ)_core_deembedded.s7p ORDER=24 LE_FORMAT=spectre LE_OUT=netlist/spectre/sparx_core_le.inc
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
	$(MAKE) copy-sparam SPARAM=sparx_bpf_f_160GHz_bw_1GHz_sig_TM2_gnd_M5_z0_50Ohm_er_4_1_butter_ord_3
	$(MAKE) copy-sparam SPARAM=sparx_wpd_160GHz_50Ohm_TM2_M5_e_r_4_1_config_U
	$(MAKE) copy-sparam SPARAM=sparx_blc_160GHz_50Ohm_TM2_M5_e_r_4_1
# 	De-embedded S-parameter to lumped element netlist conversion (SPICE and Spectre) for BPF, WPD, BLC
	$(MAKE) snp2le SNP=verification/em/s-parameter/sparx_bpf_f_160GHz_bw_1GHz_sig_TM2_gnd_M5_z0_50Ohm_er_4_1_butter_ord_3_deembedded.s2p ORDER=13 LE_FORMAT=spice LE_OUT=netlist/spice/sparx_bpf_le.spice
	$(MAKE) snp2le SNP=verification/em/s-parameter/sparx_bpf_f_160GHz_bw_1GHz_sig_TM2_gnd_M5_z0_50Ohm_er_4_1_butter_ord_3_deembedded.s2p ORDER=13 LE_FORMAT=spectre LE_OUT=netlist/spectre/sparx_bpf_le.inc
	$(MAKE) snp2le SNP=verification/em/s-parameter/sparx_wpd_160GHz_50Ohm_TM2_M5_e_r_4_1_config_U_deembedded.s3p ORDER=10 LE_FORMAT=spice LE_OUT=netlist/spice/sparx_wpd_le.spice
	$(MAKE) snp2le SNP=verification/em/s-parameter/sparx_wpd_160GHz_50Ohm_TM2_M5_e_r_4_1_config_U_deembedded.s3p ORDER=10 LE_FORMAT=spectre LE_OUT=netlist/spectre/sparx_wpd_le.inc
	$(MAKE) snp2le SNP=verification/em/s-parameter/sparx_blc_160GHz_50Ohm_TM2_M5_e_r_4_1_deembedded.s4p ORDER=6 LE_FORMAT=spice LE_OUT=netlist/spice/sparx_blc_le.spice
	$(MAKE) snp2le SNP=verification/em/s-parameter/sparx_blc_160GHz_50Ohm_TM2_M5_e_r_4_1_deembedded.s4p ORDER=6 LE_FORMAT=spectre LE_OUT=netlist/spectre/sparx_blc_le.inc
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
# 	KLayout LVS, DRC, and kpex PEX of the power-detector cell.
	$(MAKE) klayout-verify CELL=$(POWDET)
# 	Magic + Netgen LVS, Magic DRC, and Magic PEX of the power-detector cell.
	$(MAKE) magic-verify CELL=$(POWDET)
# 	Optional AWS Palace EM solve (WPD), run only when NIGHTLY_REGRESSION=1 (regression-nightly).
	$(if $(filter 1,$(NIGHTLY_REGRESSION)),$(MAKE) sim-wpd-em)
# 	Copy the raw and de-embedded S-parameter results (WPD): the fresh sim-wpd-em output when
# 	NIGHTLY_REGRESSION=1, otherwise the committed Palace output.
	$(MAKE) copy-sparam SPARAM=sparx_wpd_160GHz_50Ohm_TM2_M5_e_r_4_1_config_U
# 	De-embedded S-parameter to lumped-element netlist conversion (WPD).
	$(MAKE) snp2le SNP=verification/em/s-parameter/sparx_wpd_160GHz_50Ohm_TM2_M5_e_r_4_1_config_U_deembedded.s3p ORDER=10 LE_FORMAT=spice LE_OUT=netlist/spice/sparx_wpd_le.spice
	$(MAKE) snp2le SNP=verification/em/s-parameter/sparx_wpd_160GHz_50Ohm_TM2_M5_e_r_4_1_config_U_deembedded.s3p ORDER=10 LE_FORMAT=spectre LE_OUT=netlist/spectre/sparx_wpd_le.inc
# 	Xschem netlisting + one ngspice and one VACASK AC S-parameter simulation.
	$(MAKE) sim-xschem TB=sparx_wpd_le_tb_acsp_ngspice
	$(MAKE) sim-xschem TB=sparx_wpd_le_tb_acsp_vacask
.PHONY: regression

regression-nightly: ## Nightly regression test target for IIC-OSIC-TOOLS (usage: make regression-nightly)
	$(MAKE) regression NIGHTLY_REGRESSION=1
.PHONY: regression-nightly
# ================================================================================================
