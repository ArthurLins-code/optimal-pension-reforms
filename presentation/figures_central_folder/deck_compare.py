#!/usr/bin/env python3
"""
deck_compare.py — page-by-page visual diff of two compiled decks (OLD vs NEW).

Renders each page of both PDFs and flags pages whose pixels differ (i.e. a figure
changed), then writes a single side-by-side PDF of just the changed pages so you
can eyeball exactly what moved. Text/TikZ pages render identically and are skipped.

Usage:
  python figures_central_folder/deck_compare.py OLD.pdf NEW.pdf OUTDIR

Output:
  OUTDIR/deck_changes_OLD_vs_NEW.pdf   (one side-by-side per changed page)
  console report: pages compared, identical, changed (with diff %)
"""
import sys
from pathlib import Path

import fitz  # PyMuPDF

try:
    import numpy as np
    HAVE_NP = True
except ImportError:
    HAVE_NP = False

ZOOM = 2.0
TOL_BYTE = 16        # per-channel byte delta below this is treated as noise
CHANGED_FRAC = 0.001 # page flagged changed if >0.1% of channel-bytes differ


def render(doc, i, zoom=ZOOM):
    return doc.load_page(i).get_pixmap(matrix=fitz.Matrix(zoom, zoom), alpha=False)


def diff_frac(pa, pb):
    if (pa.width, pa.height, pa.n) != (pb.width, pb.height, pb.n):
        return 1.0
    if HAVE_NP:
        a = np.frombuffer(pa.samples, dtype=np.uint8).astype(np.int16)
        b = np.frombuffer(pb.samples, dtype=np.uint8).astype(np.int16)
        return float((np.abs(a - b) > TOL_BYTE).mean())
    # fallback: exact-equality (no magnitude)
    return 0.0 if pa.samples == pb.samples else 1.0


def side_by_side(page_out, pa, pb, label):
    colw, margin, header, gap = 340.0, 14.0, 26.0, 18.0
    ha = colw * (pa.height / pa.width)
    hb = colw * (pb.height / pb.width)
    body = max(ha, hb)
    W = margin * 2 + colw * 2 + gap
    H = margin * 2 + header + body
    pg = page_out.new_page(width=W, height=H)
    pg.insert_text((margin, margin + 9), label, fontsize=9, color=(0, 0, 0))
    pg.insert_text((margin, margin + 21), "OLD (presentation/latex/figures)", fontsize=9, color=(0.7, 0, 0))
    pg.insert_text((margin + colw + gap, margin + 21), "NEW (figures_central_folder)", fontsize=9, color=(0, 0.45, 0))
    y0 = margin + header
    pg.insert_image(fitz.Rect(margin, y0, margin + colw, y0 + ha),
                    stream=pa.tobytes("jpeg", jpg_quality=72))
    x1 = margin + colw + gap
    pg.insert_image(fitz.Rect(x1, y0, x1 + colw, y0 + hb),
                    stream=pb.tobytes("jpeg", jpg_quality=72))


def main():
    old_pdf, new_pdf, outdir = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])
    outdir.mkdir(parents=True, exist_ok=True)
    d_old, d_new = fitz.open(str(old_pdf)), fitz.open(str(new_pdf))
    n_old, n_new = d_old.page_count, d_new.page_count

    print(f"OLD: {old_pdf.name}  ({n_old} pages)")
    print(f"NEW: {new_pdf.name}  ({n_new} pages)")
    if n_old != n_new:
        print(f"!! PAGE-COUNT MISMATCH ({n_old} vs {n_new}) — comparing first {min(n_old,n_new)} pages")
    if not HAVE_NP:
        print("(numpy not present — using exact-equality fallback)")

    out = fitz.open()
    changed = []
    for i in range(min(n_old, n_new)):
        pa, pb = render(d_old, i), render(d_new, i)
        frac = diff_frac(pa, pb)
        if frac > CHANGED_FRAC:
            changed.append((i + 1, frac))
            side_by_side(out, pa, pb, f"Deck page {i + 1}  -  {frac*100:.1f}% of pixels differ")

    print(f"\nPages compared : {min(n_old, n_new)}")
    print(f"Identical      : {min(n_old, n_new) - len(changed)}")
    print(f"Changed        : {len(changed)}")
    if changed:
        print("\nChanged pages (deck page : % pixels differing):")
        for pg, frac in changed:
            print(f"   p{pg:<4} {frac*100:5.1f}%")

    if out.page_count:
        out_path = outdir / "deck_changes_OLD_vs_NEW.pdf"
        out.save(str(out_path))
        print(f"\nSide-by-side of changed pages -> {out_path}")
    else:
        print("\nNo visual differences — the two decks render identically.")
    out.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
