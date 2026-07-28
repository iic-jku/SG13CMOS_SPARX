# SPDX-FileCopyrightText: 2026 The SPARX Team
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# Description: Plot the S-parameter tables of the ngspice acsp testbenches.
#
# plot_n_port_tb_acsp_ngspice.py [testbenchname]
#
# In batch mode (ngspice -b, see the sim-xschem Makefile target) the `plot` commands in a
# testbench's .control block are a no-op, so nothing is displayed during the run.  Every
# ngspice acsp (AC S-parameter) testbench instead exports its results with wrdata to
# data/<TB>.txt (`wr_vecnames` + `wr_singlescale`: a header line with vector names, then
# a frequency column plus s..._db and s..._deg columns).  Like the VACASK sibling
# plot_n_port_tb_acsp_vacask.py, this one script serves every port count: it reads the
# header to discover the exported vectors (loaded with ngspice2python.loadngspicecol) and
# reproduces the .control block's plots with matplotlib, magnitude and phase over
# frequency in one figure per testbench.
#
# Without an argument (the sim-view-xschem Makefile target) every *_tb_acsp_ngspice table
# in data/ is plotted; with a testbench name only that one.  Each figure is written to
# figures/<TB>.png and the plot windows are opened when a display is available (i.e. the
# container's X/VNC session; headless, only the PNGs are written).
import glob
import os
import sys

import ngspice2python as ng

# Data and output paths relative to this script (testbenches/plot_simulations)
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(SCRIPT_DIR, "data")
FIGURES_DIR = os.path.join(SCRIPT_DIR, "figures")


def plot_table(tb, plt):
    table = os.path.join(DATA_DIR, tb + ".txt")
    if not os.path.isfile(table):
        sys.exit(f"{table} not found - run `make sim-xschem TB={tb}` first")
    with open(table) as fh:                     # header line holds the vector names
        names = fh.readline().split()
    if not names or names[0].lower() != "frequency":
        sys.exit(f"{table} has scale column '{names[0] if names else ''}', not "
                 "'frequency' - use plot_n_port_tb_tran_ngspice.py for transient tables")

    fghz = ng.loadngspicecol(table, names[0]) / 1e9
    db_names = [n for n in names[1:] if n.endswith("_db")]
    deg_names = [n for n in names[1:] if n.endswith("_deg")]

    fig, (ax_mag, ax_phase) = plt.subplots(2, 1, figsize=(8, 7), sharex=True)
    for n in db_names:
        ax_mag.plot(fghz, ng.loadngspicecol(table, n), label=n[:-3].upper())
    for n in deg_names:
        ax_phase.plot(fghz, ng.loadngspicecol(table, n), label=n[:-4].upper())
    ncol = max(1, min(7, (len(db_names) + 6) // 7))
    ax_mag.set_title(f"{tb} - ngspice acsp S-parameters")
    ax_mag.set_ylabel("magnitude (dB)")
    ax_mag.grid(True, alpha=0.3)
    ax_mag.legend(ncol=ncol, fontsize=6)
    ax_phase.set_ylabel("phase (deg)")
    ax_phase.set_xlabel("frequency (GHz)")
    ax_phase.grid(True, alpha=0.3)
    fig.tight_layout()

    png = os.path.join(FIGURES_DIR, tb + ".png")
    fig.savefig(png, dpi=130)
    print(f"plot: wrote {png}")


def main():
    if len(sys.argv) > 2:
        sys.exit(f"usage: {os.path.basename(sys.argv[0])} [testbenchname]")

    if len(sys.argv) == 2:
        tbs = [sys.argv[1]]
    else:                                       # all acsp ngspice result tables
        tbs = sorted(os.path.splitext(os.path.basename(t))[0] for t in
                     glob.glob(os.path.join(DATA_DIR, "*_tb_acsp_ngspice.txt")))
        if not tbs:
            sys.exit(f"no *_tb_acsp_ngspice.txt tables in {DATA_DIR} - "
                     "run `make sim-xschem TB=<testbenchname>` first")

    os.makedirs(FIGURES_DIR, exist_ok=True)
    import matplotlib.pyplot as plt
    for tb in tbs:
        plot_table(tb, plt)
    plt.show()


if __name__ == "__main__":
    main()
