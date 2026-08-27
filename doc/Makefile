# SPDX-FileCopyrightText: 2025-2026 The SPARX Team
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

all:
	quarto render index.qmd

clean: ## Delete the rendered documentation
	rm -rf .quarto _site index.pdf
.PHONY: clean

# Extra options for the sak-open.py file browser (e.g. --all to include build outputs)
# Override with: make open OPEN_ARGS=<options>
OPEN_ARGS ?=

open: ## Open the documentation sources and figures in the sak-open.py file browser (needs the VNC/X11 desktop)
	sak-open.py $(OPEN_ARGS) .
.PHONY: open
