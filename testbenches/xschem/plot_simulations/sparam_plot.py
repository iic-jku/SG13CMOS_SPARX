# SPDX-FileCopyrightText: 2026 The SPARX Team
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# Description: Shared S-parameter figure layout for the acsp plotting scripts.
#
# Both plot_n_port_tb_acsp_ngspice.py and plot_n_port_tb_acsp_vacask.py draw their
# figures through this module, so the ngspice and VACASK results are directly
# comparable side by side.
#
# An N-port testbench has N x N S-parameters, which is unreadable in a single pair of
# axes (the six-port core alone has 49).  The figure is therefore split by excitation
# port: one column of axes per driven port j, magnitude on top and phase below, so each
# panel holds only the N traces that belong to one excitation.  The color encodes the
# receiving port i and is the same in every panel, so a single legend serves the whole
# figure.  Derived columns that are not a plain S(i,j) (e.g. the differential
# combinations of the six-port core) are drawn in one extra column on the right.
import os


def set_style(plt):
    """Matplotlib settings shared by all acsp plots."""
    plt.rcParams.update({
        "font.family": "serif",
        "mathtext.fontset": "cm",
        "font.size": 10,
        "axes.titlesize": 10,
        "axes.axisbelow": True,
        "grid.linestyle": "--",
        "grid.alpha": 0.45,
        "legend.handlelength": 1.8,
    })


def plot_sgrid(plt, png, title, fghz, n, mag, phase, extra=()):
    """Write the S-parameter figure.

    mag(i, j) / phase(i, j) return the magnitude in dB / phase in deg of S(i,j), or None
    if that parameter is missing.  extra is a sequence of (label, magnitude, phase) for
    columns that are not a plain S(i,j).
    """
    ncols = n + (1 if extra else 0)
    fig, axes = plt.subplots(2, ncols, figsize=(2.7 * ncols + 1.4, 6.4),
                             sharex=True, sharey="row", squeeze=False)
    cmap = plt.get_cmap("turbo")
    colors = [cmap((i - 0.5) / n) for i in range(1, n + 1)]

    for j in range(1, n + 1):                   # one column per excitation port
        ax_mag, ax_phase = axes[0][j - 1], axes[1][j - 1]
        for i in range(1, n + 1):
            m, p = mag(i, j), phase(i, j)
            if m is not None:
                ax_mag.plot(fghz, m, color=colors[i - 1], linewidth=1.3,
                            label=f"port {i}" if j == 1 else None)
            if p is not None:
                ax_phase.plot(fghz, p, color=colors[i - 1], linewidth=1.3)
        ax_mag.set_title(rf"excite port {j}  ($S_{{i{j}}}$)")

    if extra:                                   # derived / combined responses
        ax_mag, ax_phase = axes[0][-1], axes[1][-1]
        styles = ["-", "--", "-.", ":"]
        for k, (label, m, p) in enumerate(extra):
            color = cmap((k + 0.5) / max(1, len(extra)))
            style = styles[k % len(styles)]
            if m is not None:
                ax_mag.plot(fghz, m, color=color, linestyle=style, linewidth=1.3,
                            label=label)
            if p is not None:
                ax_phase.plot(fghz, p, color=color, linestyle=style, linewidth=1.3)
        ax_mag.set_title("combinations")
        ax_mag.legend(fontsize=7, frameon=False)

    axes[0][0].set_ylabel(r"$|S_{ij}|$ (dB)")
    axes[1][0].set_ylabel(r"$\angle S_{ij}$ (deg)")
    for row in axes:
        for ax in row:
            ax.grid(visible=True, which="major")
            ax.margins(x=0)
            ax.tick_params(labelsize=8)
    fig.supxlabel(r"$f$ (GHz)", fontsize=10)
    fig.suptitle(title)
    fig.tight_layout()

    # One legend for the whole figure: the color means the same receiving port i in
    # every panel, so labelling it once is enough.  Anchored just below the figure (in
    # figure coordinates) so it clears the x-label; bbox_inches="tight" grows the canvas.
    fig.legend(*axes[0][0].get_legend_handles_labels(), loc="upper center",
               ncol=n, fontsize=9, frameon=False, bbox_to_anchor=(0.5, 0.0))

    os.makedirs(os.path.dirname(png), exist_ok=True)
    fig.savefig(png, dpi=150, bbox_inches="tight")   # grows to fit the legend
    return png
