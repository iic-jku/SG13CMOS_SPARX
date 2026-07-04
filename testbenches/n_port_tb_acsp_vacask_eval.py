# n_port_tb_acsp_vacask_eval.py
#
# Universal VACASK postprocessing script for the acsp (AC S-parameter) testbenches.  One
# script serves the 2-, 3- and 4-port testbenches: it reads VACASK's raw output, discovers
# the port count from the s(i,j) vector names, and processes the full N x N S-matrix.  Each
# testbench calls it with postprocess(PYTHON, "../n_port_tb_acsp_vacask_eval.py").
#
# It then:
#   * writes sim_data/<TB>.txt with a frequency column plus s{i}{j}_db and s{i}{j}_deg for
#     every port pair (the same column naming the ngspice testbench uses), which snp2le
#     imports, and
#   * plots every |S(i,j)| in dB and its phase to a PNG.
#
# VACASK ships rawfile.py on the postprocess Python path (the IIC reference scripts also do
# `from rawfile import rawread`).
import os
import sys
import glob
import numpy as np

from rawfile import rawread

# The result and the abort marker are named after the testbench, so a run of
# three_port_tb_acsp_vacask.sch writes sim_data/three_port_tb_acsp_vacask.txt.  This one
# script is shared by every N-port testbench, so the name comes from the running netlist
# (<TB>.spectre in the netlist dir), not from this generic file name.
try:
    HERE = os.path.dirname(os.path.abspath(__file__))
except NameError:                              # exec'd without __file__
    HERE = os.getcwd()
_spec = (glob.glob(os.path.join(os.getcwd(), "*.spectre"))
         or glob.glob(os.path.join(HERE, "simulations", "*.spectre"))
         or glob.glob(os.path.join(HERE, "*.spectre")))
TB = (os.path.splitext(os.path.basename(max(_spec, key=os.path.getmtime)))[0]
      if _spec else "n_port_tb_acsp_vacask")


def _abort_marker():
    repo = os.path.abspath(os.path.join(HERE, "..", ".."))
    return os.path.join(repo, "sim_data", TB + ".aborted")


def mark_aborted(reason):
    """Leave a marker so snp2le's GUI can report 'aborted!' (the analysis ran but produced
    no usable data, e.g. a singular matrix) rather than a generic 'failed!'."""
    try:
        os.makedirs(os.path.dirname(_abort_marker()), exist_ok=True)
        with open(_abort_marker(), "w") as fh:
            fh.write(reason + "\n")
    except OSError:
        pass


def find_raw():
    """Newest .raw VACASK wrote (cwd is the netlist dir during the run)."""
    cands = []
    for d in (os.getcwd(), os.path.join(HERE, "simulations"), HERE):
        cands += glob.glob(os.path.join(d, "*.raw"))
    cands = [c for c in cands if os.path.isfile(c)]
    if not cands:
        mark_aborted("no .raw output, the analysis aborted before writing any results")
        sys.exit("postprocess: no .raw output found (looked in cwd and ./simulations)")
    return max(cands, key=os.path.getmtime)


def load_acsp(raw):
    """Return (frequency, n_ports, S) for the acsp analysis in `raw`.

    acsp names its outputs s(i,j) (port i out, port j excited).  The port count is found by
    probing the diagonal s(k,k) until one is missing, so the same script serves any N-port
    testbench.  S is keyed by the (i, j) integer pair."""
    rd = rawread(raw)
    plots = None
    for ndx in range(8):                       # skip an op plot if one precedes acsp
        try:
            p = rd.get(ndx=ndx, sweeps=0)
            _ = p["frequency"]
            plots = p
            break
        except Exception:
            continue
    if plots is None:
        plots = rd.get(sweeps=0)

    def sij(i, j):
        for nm in (f"s({i},{j})", f"S({i},{j})", f"s_{i}_{j}", f"S_{i}_{j}"):
            try:
                return np.asarray(plots[nm]).astype(complex).ravel()
            except Exception:
                continue
        return None

    n = 0
    while n < 64 and sij(n + 1, n + 1) is not None:   # probe the diagonal for the port count
        n += 1

    f = np.real(np.asarray(plots["frequency"]).astype(complex)).ravel()
    S = {}
    for i in range(1, n + 1):
        for j in range(1, n + 1):
            v = sij(i, j)
            if v is None:
                raise KeyError(f"S({i},{j}) missing from {raw}")
            S[(i, j)] = v
    return f, n, S


def write_table(f, n, dB, deg):
    """Write sim_data/<TB>.txt: a frequency column plus s{i}{j}_db and s{i}{j}_deg for every
    port pair.  snp2le maps columns by name, so any port count imports."""
    repo = os.path.abspath(os.path.join(HERE, "..", ".."))
    out_dir = os.path.join(repo, "sim_data")
    os.makedirs(out_dir, exist_ok=True)
    pairs = [(i, j) for i in range(1, n + 1) for j in range(1, n + 1)]
    cols = ["frequency"] + [f"s{i}{j}_db" for i, j in pairs] + [f"s{i}{j}_deg" for i, j in pairs]
    arrs = [f] + [dB[p] for p in pairs] + [deg[p] for p in pairs]
    data = np.column_stack(arrs)
    path = os.path.join(out_dir, TB + ".txt")
    with open(path, "w") as fh:
        fh.write(" " + " ".join(f"{c:>15s}" for c in cols) + "\n")
        for row in data:
            fh.write(" " + " ".join(f"{x: .8e}" for x in row) + "\n")
    return path


def main():
    try:                                        # only present if THIS run aborts
        os.remove(_abort_marker())
    except OSError:
        pass
    raw = find_raw()
    f, n, S = load_acsp(raw)
    if np.asarray(f).size < 2 or n < 1:         # an aborted analysis leaves no usable sweep,
        mark_aborted("analysis produced no sweep data")
        sys.exit("postprocess: analysis produced no sweep data (aborted?), "
                 "no result table written")     # so write nothing and let the GUI report it
    dB = {k: 20.0 * np.log10(np.maximum(np.abs(v), 1e-300)) for k, v in S.items()}
    deg = {k: np.unwrap(np.angle(v)) * 180.0 / np.pi for k, v in S.items()}

    table = write_table(f, n, dB, deg)
    print(f"postprocess: wrote {table}")        # write the table first, snp2le's GUI polls
                                                # for it, so keep it ahead of the slow
                                                # matplotlib import and plotting

    import matplotlib
    if not os.environ.get("SHOW_PLOTS"):        # headless under VACASK's run loop
        matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    fig, (axm, axp) = plt.subplots(2, 1, figsize=(8, 7), sharex=True)
    fghz = f / 1e9
    for i in range(1, n + 1):
        for j in range(1, n + 1):
            lab = f"S{i}{j}"
            axm.plot(fghz, dB[(i, j)], label=lab)
            axp.plot(fghz, deg[(i, j)], label=lab)
    axm.set_title(f"{n}-port, VACASK acsp S-parameters")
    axm.set_ylabel("magnitude (dB)"); axm.grid(True, alpha=0.3)
    axm.legend(ncol=min(n, 4), fontsize=7)
    axp.set_ylabel("phase (deg)"); axp.set_xlabel("frequency (GHz)")
    axp.grid(True, alpha=0.3)
    fig.tight_layout()
    png = os.path.join(os.path.dirname(table), TB + ".png")
    fig.savefig(png, dpi=130)
    print(f"postprocess: wrote {png}")
    if os.environ.get("SHOW_PLOTS"):
        plt.show()


try:
    main()
except Exception as exc:                       # don't crash VACASK's run loop
    print(f"postprocess failed: {exc}", file=sys.stderr)
