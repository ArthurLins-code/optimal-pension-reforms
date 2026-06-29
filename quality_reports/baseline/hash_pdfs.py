#!/usr/bin/env python3
"""
hash_pdfs.py — render PDF pages to PNG @150 DPI with PyMuPDF and sha256 the PNG bytes
(metadata-independent) plus a raw-file sha256. Writes a manifest CSV.

Usage:
  python hash_pdfs.py --out <manifest.csv> --source <tag> [--single <pdf> ...] [--dir <dir>]
"""
from __future__ import annotations
import argparse, csv, hashlib, sys
from pathlib import Path

DPI = 150
ZOOM = DPI / 72.0  # fitz default user space is 72 dpi


def sha256_bytes(b: bytes) -> str:
    h = hashlib.sha256()
    h.update(b)
    return h.hexdigest()


def raw_sha256(p: Path) -> str:
    h = hashlib.sha256()
    with open(p, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def hash_pdf_pages(pdf: Path, source: str):
    """Yield (path, page, png_sha256, raw_sha256, source) rows for each page."""
    import fitz
    rsha = raw_sha256(pdf)
    rows = []
    doc = fitz.open(str(pdf))
    try:
        for i in range(doc.page_count):
            pix = doc.load_page(i).get_pixmap(matrix=fitz.Matrix(ZOOM, ZOOM), alpha=False)
            png = pix.tobytes("png")
            rows.append((str(pdf).replace("\\", "/"), i + 1, sha256_bytes(png), rsha, source))
    finally:
        doc.close()
    return rows


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--source", default="asis")
    ap.add_argument("--dir", default=None, help="directory of PDFs to hash (page 1..N each)")
    ap.add_argument("--single", nargs="*", default=[], help="extra single PDFs (all pages)")
    args = ap.parse_args()

    targets = []
    if args.dir:
        d = Path(args.dir)
        targets += sorted(d.glob("*.pdf"))
    targets += [Path(p) for p in args.single]

    all_rows = []
    errors = []
    for pdf in targets:
        if not pdf.is_file():
            errors.append((str(pdf), "missing"))
            continue
        try:
            all_rows += hash_pdf_pages(pdf, args.source)
        except Exception as e:  # noqa: BLE001
            errors.append((str(pdf), f"error: {e}"))

    with open(args.out, "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["path", "page", "png_sha256", "raw_sha256", "source"])
        w.writerows(all_rows)

    print(f"hashed {len(targets)} pdf(s) -> {len(all_rows)} page rows  -> {args.out}")
    if errors:
        print("ERRORS:")
        for p, why in errors:
            print(f"   {p}: {why}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
