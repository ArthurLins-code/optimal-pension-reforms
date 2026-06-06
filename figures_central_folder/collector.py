#!/usr/bin/env python3
"""
collector.py — route pipeline figure outputs into figures_central_folder/from_code/

Single-source-of-truth bridge between the analysis pipeline (trans_retirement/output/**)
and the presentation (latex/presentation/_main.tex). Reads manifest.csv and, for each
live deck figure:

  * copies the code output -> from_code/<deck_name>, applying the rename the deck expects
  * for the actual/counterfactual frequency family, prefers the (pending) canonical pure
    script output and falls back to gabriel's tmp output (warns on fallback)
  * renders side-by-side E3->E4 visual diffs into _diffs/ (rows tagged diff=E3->E4)
  * verifies NONE (manual/external) rows already exist in static/  (never copies them)
  * prints a summary table and exits nonzero if any routable row is unresolved

Hard rule: this layer touches NO analysis script in trans_retirement/. All routing and
renaming logic lives here + in manifest.csv.

Usage:
    python figures_central_folder/collector.py            # route + diffs + verify
    python figures_central_folder/collector.py --no-diff  # skip the PDF diffs
"""

from __future__ import annotations

import argparse
import csv
import shutil
import sys
from pathlib import Path

# ----------------------------------------------------------------------------- paths
HERE = Path(__file__).resolve().parent          # figures_central_folder/
ROOT = HERE.parent                               # repo root
FROM_CODE = HERE / "from_code"
STATIC = HERE / "static"
DIFFS = HERE / "_diffs"
MANIFEST = HERE / "manifest.csv"
LATEX_FIGURES = ROOT / "latex" / "figures"       # source of the OLD (E3) copies for diffs

ROUTABLE_STATUSES = {"OK", "OK-RENAME", "UPSTREAM-CANONICAL", "LEGACY"}


# ----------------------------------------------------------------------------- helpers
def parse_directives(notes: str) -> dict:
    """Pull machine directives (prefer=..., diff=...) out of the free-text notes field."""
    d = {}
    for tok in notes.split():
        if tok.startswith("prefer="):
            d["prefer"] = tok[len("prefer="):]
        elif tok.startswith("diff="):
            d["diff"] = tok[len("diff="):]
    return d


def render_first_page(pdf_path: Path, zoom: float = 2.0):
    import fitz  # PyMuPDF
    doc = fitz.open(str(pdf_path))
    try:
        pix = doc.load_page(0).get_pixmap(matrix=fitz.Matrix(zoom, zoom), alpha=False)
        return pix
    finally:
        doc.close()


def make_side_by_side(old_pdf: Path, new_pdf: Path, out_pdf: Path,
                      old_label: str, new_label: str, colw: float = 340.0) -> None:
    """One-page PDF: OLD (left) vs NEW (right), each scaled into a fixed-width column."""
    import fitz
    p_old = render_first_page(old_pdf)
    p_new = render_first_page(new_pdf)
    margin, header, gap = 16.0, 36.0, 22.0

    def col_h(p):
        return colw * (p.height / p.width)

    h_old, h_new = col_h(p_old), col_h(p_new)
    body = max(h_old, h_new)
    W = margin * 2 + colw * 2 + gap
    H = margin * 2 + header + body

    out = fitz.open()
    page = out.new_page(width=W, height=H)
    page.insert_text((margin, margin + 10),
                     "E3 -> E4 content check  (deck filename unchanged; source rewired to canonical E4)",
                     fontsize=9, color=(0, 0, 0))
    page.insert_text((margin, margin + 27), old_label, fontsize=10, color=(0.7, 0, 0))
    page.insert_text((margin + colw + gap, margin + 27), new_label, fontsize=10, color=(0, 0.45, 0))
    y0 = margin + header
    page.insert_image(fitz.Rect(margin, y0, margin + colw, y0 + h_old), pixmap=p_old)
    x1 = margin + colw + gap
    page.insert_image(fitz.Rect(x1, y0, x1 + colw, y0 + h_new), pixmap=p_new)
    out.save(str(out_pdf))
    out.close()


# ----------------------------------------------------------------------------- main
def main() -> int:
    ap = argparse.ArgumentParser(description="Route pipeline figures into figures_central_folder/from_code/")
    ap.add_argument("--manifest", default=str(MANIFEST))
    ap.add_argument("--no-diff", action="store_true", help="skip rendering E3->E4 diffs")
    args = ap.parse_args()

    FROM_CODE.mkdir(parents=True, exist_ok=True)
    DIFFS.mkdir(parents=True, exist_ok=True)

    with open(args.manifest, newline="", encoding="utf-8") as fh:
        rows = list(csv.DictReader(fh))

    copied, missing, static_ok, static_missing = [], [], [], []
    warn_legacy, warn_sample, warn_fallback = [], [], []
    diff_jobs, diffs_made, diffs_skipped = [], [], []

    for r in rows:
        deck = r["deck_name"].strip()
        status = r["status"].strip()
        mode = r["mode"].strip()
        d = parse_directives(r["notes"])

        # ---- manual/external assets: verify they sit in static/, never copy ----
        if status == "NONE":
            if (STATIC / deck).exists():
                static_ok.append(deck)
            else:
                static_missing.append(deck)
            continue

        # ---- resolve the code source (with pure->gabriel preference) ----
        primary = ROOT / r["code_output_path"] / r["code_output_name"]
        src, src_kind = primary, "primary"
        if status == "UPSTREAM-CANONICAL" and "prefer" in d:
            pref = ROOT / d["prefer"]
            if pref.exists():
                src, src_kind = pref, "pure"
            else:
                src, src_kind = primary, "fallback"  # gabriel

        # ---- copy (with rename) or record miss ----
        if src.exists():
            shutil.copy2(src, FROM_CODE / deck)
            copied.append((deck, src_kind, status, mode))
            if status == "LEGACY":
                warn_legacy.append((deck, r["code_script"].strip()))
            if mode == "sample":
                warn_sample.append(deck)
            if src_kind == "fallback":
                warn_fallback.append(deck)
        else:
            missing.append((deck, status, mode, str(src.relative_to(ROOT)) if ROOT in src.parents else str(src)))

        # ---- queue E3->E4 diff ----
        if d.get("diff") == "E3->E4":
            diff_jobs.append((deck, LATEX_FIGURES / deck, primary, r["code_output_name"].strip()))

    # ---- diffs ----
    if not args.no_diff:
        try:
            import fitz  # noqa: F401
            for deck, old_pdf, new_pdf, new_name in diff_jobs:
                out = DIFFS / (Path(deck).stem + "__OLD-E3_vs_NEW-E4.pdf")
                if old_pdf.exists() and new_pdf.exists():
                    try:
                        make_side_by_side(
                            old_pdf, new_pdf, out,
                            old_label=f"OLD  {deck}  (current deck / legacy E3)",
                            new_label=f"NEW  {new_name}  (canonical E4)",
                        )
                        diffs_made.append(out.name)
                    except Exception as e:  # noqa: BLE001
                        diffs_skipped.append((deck, f"render error: {e}"))
                else:
                    why = []
                    if not old_pdf.exists():
                        why.append("old E3 copy missing")
                    if not new_pdf.exists():
                        why.append("new E4 output missing")
                    diffs_skipped.append((deck, "; ".join(why)))
        except ImportError:
            diffs_skipped = [(deck, "PyMuPDF not installed") for deck, *_ in diff_jobs]

    # ----------------------------------------------------------------- summary
    bar = "=" * 78
    print(bar)
    print("figures_central_folder collector - summary")
    print(bar)

    by_status = {}
    for r in rows:
        by_status[r["status"].strip()] = by_status.get(r["status"].strip(), 0) + 1
    print("Manifest rows by status:")
    for st in ("OK", "OK-RENAME", "UPSTREAM-CANONICAL", "LEGACY", "NONE"):
        if st in by_status:
            print(f"   {st:<20} {by_status[st]}")
    print()

    print(f"Routed into from_code/ : {len(copied)}")
    print(f"Static assets present  : {len(static_ok)}/{len(static_ok) + len(static_missing)}")
    print(f"Diffs generated        : {len(diffs_made)}")
    print(f"MISSING (routable)     : {len(missing)}")
    print()

    if warn_sample:
        print("!! SAMPLE-MODE figures (5% sample, NOT full-data) -- do not ship as final:")
        for d in warn_sample:
            print(f"     [SAMPLE] {d}")
        print()
    if warn_legacy:
        print("!! LEGACY-sourced figures (may be outdated; canonical generator absent):")
        for d, scr in warn_legacy:
            print(f"     [LEGACY] {d}   <- {scr}")
        print()
    if warn_fallback:
        print("!! FALLBACK-to-gabriel (preferred pure-script output not present; pending later prompt):")
        for d in warn_fallback:
            print(f"     [FALLBACK] {d}")
        print()
    if diffs_skipped:
        print("-- E3->E4 diffs skipped:")
        for d, why in diffs_skipped:
            print(f"     {d}: {why}")
        print()
    if static_missing:
        print("xx STATIC assets missing from static/ (place them before compiling):")
        for d in static_missing:
            print(f"     {d}")
        print()
    if missing:
        print("xx MISSING routable sources (stage not run / wrong path):")
        for d, st, mode, src in missing:
            print(f"     {d}  [{st}/{mode}]  expected: {src}")
        print()

    # ----------------------------------------------------------------- result table
    print(bar)
    print(f"{'CATEGORY':<34}{'COUNT':>8}")
    print("-" * 42)
    print(f"{'Routed (canonical OK + OK-RENAME)':<34}{sum(1 for _,k,st,_ in copied if st in ('OK','OK-RENAME')):>8}")
    print(f"{'Routed (upstream-canonical)':<34}{sum(1 for _,k,st,_ in copied if st=='UPSTREAM-CANONICAL'):>8}")
    print(f"{'Routed (legacy, flagged)':<34}{sum(1 for _,k,st,_ in copied if st=='LEGACY'):>8}")
    print(f"{'  of which gabriel-fallback':<34}{len(warn_fallback):>8}")
    print(f"{'  of which sample-mode':<34}{len(warn_sample):>8}")
    print(f"{'Static (manual) present':<34}{len(static_ok):>8}")
    print(f"{'E3->E4 diffs generated':<34}{len(diffs_made):>8}")
    print(f"{'MISSING (routable)':<34}{len(missing):>8}")
    print(f"{'STATIC missing':<34}{len(static_missing):>8}")
    print(bar)

    fail = bool(missing) or bool(static_missing)
    if fail:
        print("RESULT: FAIL - unresolved figure(s) above. (A sample-only stage that was not run "
              "locally, e.g. I6, is an expected local gap; rerun that stage to resolve.)")
        return 1
    print("RESULT: PASS - every live deck figure resolves under from_code/ or static/.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
