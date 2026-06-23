#!/usr/bin/env python3
"""
stage3_compare.py — Stage-3 PARITY verdict.

FIGURES: join baseline_manifest.csv vs stage3_manifest.csv on (path,page),
         restricted to from_code rows (exclude _main.pdf — date-nondeterministic).
         Compare png_sha256 EXACTLY -> MATCH / MISMATCH / MISSING / EXTRA.
NUMBERS: join baseline_numbers.csv vs stage3_numbers.csv on quantity.
         Floats: relative diff < 1e-6 = MATCH. sha256 / integer sums: EXACT.

Prints a per-figure summary, a per-number table, and an overall verdict.
Writes baseline/stage3_compare_figures.csv and baseline/stage3_compare_numbers.csv.
"""
from __future__ import annotations
import csv
from pathlib import Path

OUT = Path("C:/Users/tuca1/Projects/optimal-pension-reforms/baseline")
B_MAN = OUT / "baseline_manifest.csv"
S_MAN = OUT / "stage3_manifest.csv"
B_NUM = OUT / "baseline_numbers.csv"
S_NUM = OUT / "stage3_numbers.csv"

FLOAT_RELTOL = 1e-6


def load_manifest(p):
    """Return {(name,page): png_sha256} excluding _main.pdf."""
    d = {}
    with open(p, newline="", encoding="utf-8") as fh:
        r = csv.DictReader(fh)
        for row in r:
            name = row["path"].split("/")[-1]
            if name == "_main.pdf":
                continue
            d[(name, row["page"])] = row["png_sha256"]
    return d


def load_numbers(p):
    d = {}
    with open(p, newline="", encoding="utf-8") as fh:
        r = csv.DictReader(fh)
        for row in r:
            d[row["quantity"]] = row["value"]
    return d


def is_float(s):
    try:
        float(s)
        return True
    except (ValueError, TypeError):
        return False


def num_match(b, s):
    if b == s:
        return True, "exact"
    if is_float(b) and is_float(s):
        bf, sf = float(b), float(s)
        if bf == 0:
            return (abs(sf) < FLOAT_RELTOL), f"absdiff={abs(sf):.3g}"
        rel = abs(bf - sf) / abs(bf)
        return (rel < FLOAT_RELTOL), f"reldiff={rel:.3g}"
    return False, "string-diff"


def main():
    # ---------- FIGURES ----------
    bman = load_manifest(B_MAN)
    sman = load_manifest(S_MAN)
    keys = sorted(set(bman) | set(sman))
    fig_rows = []
    counts = {"MATCH": 0, "MISMATCH": 0, "MISSING": 0, "EXTRA": 0}
    for k in keys:
        name, page = k
        if k in bman and k in sman:
            status = "MATCH" if bman[k] == sman[k] else "MISMATCH"
        elif k in bman:
            status = "MISSING"   # in baseline, absent in stage3
        else:
            status = "EXTRA"     # in stage3, absent in baseline
        counts[status] += 1
        fig_rows.append((name, page, status,
                         bman.get(k, "")[:12], sman.get(k, "")[:12]))

    with open(OUT / "stage3_compare_figures.csv", "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["figure", "page", "status", "baseline_png_sha12", "stage3_png_sha12"])
        w.writerows(fig_rows)

    print("=== FIGURES (from_code, 66 expected) ===")
    print(f"  MATCH={counts['MATCH']} MISMATCH={counts['MISMATCH']} "
          f"MISSING={counts['MISSING']} EXTRA={counts['EXTRA']}  (total={len(keys)})")
    for name, page, status, b12, s12 in fig_rows:
        if status != "MATCH":
            print(f"  [{status}] {name} p{page}  base={b12} stage3={s12}")

    # ---------- NUMBERS ----------
    bnum = load_numbers(B_NUM)
    snum = load_numbers(S_NUM)
    nkeys = sorted(set(bnum) | set(snum))
    num_rows = []
    nmatch = nmis = 0
    for q in nkeys:
        b = bnum.get(q, "<absent>")
        s = snum.get(q, "<absent>")
        if q not in bnum:
            ok, note = False, "stage3-only"
        elif q not in snum:
            ok, note = False, "baseline-only"
        else:
            ok, note = num_match(b, s)
        status = "MATCH" if ok else "MISMATCH"
        if ok:
            nmatch += 1
        else:
            nmis += 1
        num_rows.append((q, b, s, status, note))

    with open(OUT / "stage3_compare_numbers.csv", "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["quantity", "baseline", "stage3", "status", "note"])
        w.writerows(num_rows)

    print("\n=== NUMBERS ===")
    print(f"  MATCH={nmatch} MISMATCH={nmis}  (total={len(nkeys)})")
    for q, b, s, status, note in num_rows:
        flag = "" if status == "MATCH" else "  <<<"
        # truncate long sha values for display
        bd = b if len(str(b)) <= 22 else str(b)[:18] + "..."
        sd = s if len(str(s)) <= 22 else str(s)[:18] + "..."
        print(f"  [{status}] {q}: base={bd} stage3={sd} ({note}){flag}")

    overall = "PASS" if (counts["MISMATCH"] == 0 and counts["MISSING"] == 0
                         and counts["EXTRA"] == 0 and nmis == 0) else "FAIL"
    print(f"\n=== OVERALL FIGURE+NUMBER PARITY: {overall} ===")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
