#!/usr/bin/env python3
"""
update_deck.py — one command to refresh the presentation's figures from the code.

It runs three steps in order:
  1. (optional) RUN one or more pipeline stages on the sample, so they regenerate figures
  2. COLLECT  — route the current figures into figures_central_folder/from_code/
  3. COMPILE  — rebuild presentation/latex/presentation/_main.pdf

Sample runs write their figures into the sample working dir (the OneDrive
"transfer_may_retirement" folder); the collector reads from there (newest of sample-dir
vs repo wins). So the whole loop is: edit a generating script -> run this -> deck updates.

Examples:
  python figures_central_folder/update_deck.py G5            # rerun G5, then collect + compile
  python figures_central_folder/update_deck.py G5 H2         # several stages
  python figures_central_folder/update_deck.py --collect-only
  python figures_central_folder/update_deck.py G5 --no-compile
"""
from __future__ import annotations

import argparse
import os
import subprocess
import sys
import time
from pathlib import Path

PRESENTATION = Path(__file__).resolve().parent.parent  # presentation/ (this tool's home)
REPO_ROOT = PRESENTATION.parent                        # repo root
ROOT = REPO_ROOT                                       # repo root (used for collector cwd)
CODE = REPO_ROOT / "analysis" / "code"                 # restructure: stage scripts moved here
DECK_DIR = PRESENTATION / "latex" / "presentation"     # restructure: presentation/latex/presentation

# short name -> canonical script that PRODUCES deck figures
STAGES = {
    "E4": CODE / "E4_plots_claiming_distributions.R",
    "G5": CODE / "G5_effect_average_benefit_freq_bL_and_bS.R",
    "H2": CODE / "H2_policy_elasticity_MW.R",
    "F":  CODE / "new_counterfactual_claiming3_pure.R",
    "Fg": CODE / "new_counterfactual_claiming3_gabriel.R",
    "I6": CODE / "I6_wmvpf_with_pure_reforms_freq.R",
}

# the sample working dir (figures from a sample run land here). The default is the
# external OneDrive transfer_may_retirement folder; override via PENSION_SAMPLE_ROOT
# (or --sample-root) without touching the repo.
SAMPLE_DIR_CANDIDATES = [
    os.environ.get("PENSION_SAMPLE_ROOT",
                   "C:/Users/tuca1/OneDrive/Documentos/Pesquisa/transfer_may_retirement"),
]


def find_sample_root():
    for d in SAMPLE_DIR_CANDIDATES:
        if Path(d).is_dir():
            return d
    return None


def banner(msg):
    print("\n" + "=" * 78 + f"\n{msg}\n" + "=" * 78, flush=True)


def run(cmd, cwd=None):
    t0 = time.time()
    r = subprocess.run(cmd, cwd=cwd)
    return r.returncode, time.time() - t0


def main() -> int:
    ap = argparse.ArgumentParser(description="Rerun stage(s) -> collect -> recompile the deck.")
    ap.add_argument("stages", nargs="*", help=f"stages to rerun: {', '.join(STAGES)} (or a path to a .R script)")
    ap.add_argument("--collect-only", action="store_true", help="skip running stages")
    ap.add_argument("--no-compile", action="store_true", help="skip recompiling the deck")
    ap.add_argument("--sample-root", default=None, help="override the sample working dir")
    args = ap.parse_args()

    sample_root = args.sample_root or find_sample_root()
    results = []

    # 1. RUN stages -----------------------------------------------------------
    if not args.collect_only:
        for s in args.stages:
            script = STAGES.get(s, Path(s))
            if not Path(script).is_file():
                print(f"!! unknown stage '{s}' (known: {', '.join(STAGES)}) or missing file"); return 2
            banner(f"RUN stage {s}  ->  {Path(script).name}")
            rc, dt = run(["Rscript", str(script)], cwd=ROOT)
            results.append((f"run {s}", rc, dt))
            if rc != 0:
                print(f"!! stage {s} failed (exit {rc}) -- stopping"); return rc

    # 2. COLLECT --------------------------------------------------------------
    banner("COLLECT  ->  figures_central_folder/from_code/")
    collect_cmd = [sys.executable, str(PRESENTATION / "figures_central_folder" / "collector.py")]
    if sample_root:
        collect_cmd += ["--sample-root", sample_root]
    rc, dt = run(collect_cmd, cwd=ROOT)
    results.append(("collect", rc, dt))
    if rc != 0:
        print("!! collector reported unresolved figures (see above)")

    # 3. COMPILE --------------------------------------------------------------
    if not args.no_compile:
        banner("COMPILE  ->  presentation/latex/presentation/_main.pdf")
        # -g forces a rebuild so a removed/frozen figure is always reflected
        # (latexmk can otherwise consider _main.pdf up-to-date and keep a stale image).
        crc, dt = run(["latexmk", "-g", "-pdf", "-interaction=nonstopmode", "_main.tex"], cwd=DECK_DIR)
        results.append(("compile", crc, dt))
        log = DECK_DIR / "_main.log"
        nf = log.read_text(errors="replace").count("not found") if log.is_file() else -1
        print(f"\nmissing-figure errors in _main.log: {nf}")

    # summary -----------------------------------------------------------------
    banner("DONE")
    print(f"{'STEP':<14}{'EXIT':>6}{'SECONDS':>10}")
    for name, rc, dt in results:
        print(f"{name:<14}{rc:>6}{dt:>10.1f}")
    print(f"\nsample working dir: {sample_root or '(none found -> repo only)'}")
    print(f"deck: {DECK_DIR / '_main.pdf'}")
    return 0 if all(rc == 0 for _, rc, _ in results) else 1


if __name__ == "__main__":
    sys.exit(main())
