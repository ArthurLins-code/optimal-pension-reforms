#!/usr/bin/env python3
"""
build_golden_manifest.py — the GOLDEN PARITY MANIFEST.

For every PDF in figures_central_folder/from_code/: render page 1..N to PNG @150 DPI,
sha256 the PNG bytes (metadata-independent), and raw-sha256 the file.
For latex/presentation/_main.pdf: render ALL pages and hash each (holistic deck hash).
Copy fresh from_code/*.pdf and _main.pdf into baseline/figures_before/.
Write baseline/baseline_manifest.csv with header:
   path,page,png_sha256,raw_sha256,source
source = "rerun" for files a parity stage regenerated this run (mtime >= RUN_START),
         else "asis-untouched".
"""
from __future__ import annotations
import csv, hashlib, shutil, sys, time
from pathlib import Path
from datetime import datetime

ROOT = Path("C:/Users/tuca1/Projects/optimal-pension-reforms")
FROM_CODE = ROOT / "figures_central_folder" / "from_code"
MAIN_PDF = ROOT / "latex" / "presentation" / "_main.pdf"
OUT_DIR = ROOT / "baseline"
FIG_BEFORE = OUT_DIR / "figures_before"
MANIFEST = OUT_DIR / "baseline_manifest.csv"

# run start cutoff: any from_code pdf with mtime at/after this was refreshed this run
RUN_START = datetime(2026, 6, 23, 14, 25, 0).timestamp()

DPI = 150
ZOOM = DPI / 72.0


def sha256_bytes(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()


def raw_sha256(p: Path) -> str:
    h = hashlib.sha256()
    with open(p, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def page_rows(pdf: Path, source: str):
    import fitz
    rsha = raw_sha256(pdf)
    rows = []
    doc = fitz.open(str(pdf))
    try:
        for i in range(doc.page_count):
            pix = doc.load_page(i).get_pixmap(matrix=fitz.Matrix(ZOOM, ZOOM), alpha=False)
            rows.append((pdf.name, i + 1, sha256_bytes(pix.tobytes("png")), rsha, source))
    finally:
        doc.close()
    return rows


def main() -> int:
    FIG_BEFORE.mkdir(parents=True, exist_ok=True)
    all_rows = []
    errors = []

    pdfs = sorted(FROM_CODE.glob("*.pdf"))
    n_rerun = n_asis = 0
    for pdf in pdfs:
        source = "rerun" if pdf.stat().st_mtime >= RUN_START else "asis-untouched"
        if source == "rerun":
            n_rerun += 1
        else:
            n_asis += 1
        try:
            all_rows += page_rows(pdf, source)
            shutil.copy2(pdf, FIG_BEFORE / pdf.name)
        except Exception as e:  # noqa: BLE001
            errors.append((pdf.name, str(e)))

    # _main.pdf : holistic, all pages; it was rebuilt this run -> source "rerun"
    if MAIN_PDF.is_file():
        try:
            rows = page_rows(MAIN_PDF, "rerun")
            all_rows += rows
            shutil.copy2(MAIN_PDF, FIG_BEFORE / MAIN_PDF.name)
            print(f"_main.pdf: {len(rows)} pages hashed")
        except Exception as e:  # noqa: BLE001
            errors.append((MAIN_PDF.name, str(e)))
    else:
        errors.append((str(MAIN_PDF), "missing"))

    with open(MANIFEST, "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["path", "page", "png_sha256", "raw_sha256", "source"])
        w.writerows(all_rows)

    print(f"from_code pdfs: {len(pdfs)}  (rerun={n_rerun}, asis-untouched={n_asis})")
    print(f"total page rows: {len(all_rows)}  -> {MANIFEST}")
    print(f"copied fresh pdfs into: {FIG_BEFORE}")
    if errors:
        print("ERRORS:")
        for n, why in errors:
            print(f"   {n}: {why}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
