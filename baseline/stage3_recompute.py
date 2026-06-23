#!/usr/bin/env python3
"""
stage3_recompute.py — Stage-3 PARITY recompute (NEW structure).

Mirrors baseline/build_golden_manifest.py's hashing METHOD byte-for-byte:
  fitz render each PDF page @150 DPI -> sha256(PNG bytes) + raw-file sha256.

NEW-structure paths:
  from_code  = presentation/figures_central_folder/from_code/*.pdf
  _main.pdf  = presentation/latex/presentation/_main.pdf

Writes (under baseline/):
  stage3_manifest.csv   header: path,page,png_sha256,raw_sha256,source
                        (path = BARE filename, to join 1:1 vs baseline_manifest.csv)
  stage3_numbers.csv    header: quantity,value,source_file,note

Key numbers re-extracted from the EXTERNAL sample output dir.
"""
from __future__ import annotations
import csv, hashlib, sys
from pathlib import Path

ROOT = Path("C:/Users/tuca1/Projects/optimal-pension-reforms")
EXT  = Path("C:/Users/tuca1/OneDrive/Documentos/Pesquisa/transfer_may_retirement")

FROM_CODE = ROOT / "presentation" / "figures_central_folder" / "from_code"
MAIN_PDF  = ROOT / "presentation" / "latex" / "presentation" / "_main.pdf"
OUT_DIR   = ROOT / "baseline"
MANIFEST  = OUT_DIR / "stage3_manifest.csv"
NUMBERS   = OUT_DIR / "stage3_numbers.csv"

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


def page_rows(pdf: Path, source: str, name_only: bool = True):
    import fitz
    rsha = raw_sha256(pdf)
    rows = []
    doc = fitz.open(str(pdf))
    try:
        for i in range(doc.page_count):
            pix = doc.load_page(i).get_pixmap(matrix=fitz.Matrix(ZOOM, ZOOM), alpha=False)
            label = pdf.name if name_only else str(pdf).replace("\\", "/")
            rows.append((label, i + 1, sha256_bytes(pix.tobytes("png")), rsha, source))
    finally:
        doc.close()
    return rows


# ---------------- FIGURES ----------------
def build_manifest() -> int:
    all_rows = []
    errors = []
    pdfs = sorted(FROM_CODE.glob("*.pdf"))
    for pdf in pdfs:
        try:
            all_rows += page_rows(pdf, "rerun")
        except Exception as e:  # noqa: BLE001
            errors.append((pdf.name, str(e)))

    main_pages = 0
    if MAIN_PDF.is_file():
        try:
            rows = page_rows(MAIN_PDF, "rerun")
            main_pages = len(rows)
            all_rows += rows
        except Exception as e:  # noqa: BLE001
            errors.append((MAIN_PDF.name, str(e)))
    else:
        errors.append((str(MAIN_PDF), "missing"))

    with open(MANIFEST, "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["path", "page", "png_sha256", "raw_sha256", "source"])
        w.writerows(all_rows)

    print(f"from_code pdfs: {len(pdfs)} | _main.pdf pages: {main_pages} | "
          f"total rows: {len(all_rows)} -> {MANIFEST}")
    if errors:
        print("MANIFEST ERRORS:")
        for n, why in errors:
            print(f"   {n}: {why}")
    return len(pdfs), main_pages, errors


# ---------------- NUMBERS ----------------
def read_kv_csv(path: Path):
    """Read a 2-col Metric,Value csv into a dict."""
    d = {}
    if not path.is_file():
        return d
    with open(path, newline="", encoding="utf-8") as fh:
        r = csv.reader(fh)
        next(r, None)
        for row in r:
            if len(row) >= 2:
                d[row[0].strip()] = row[1].strip()
    return d


def read_table_csv(path: Path):
    if not path.is_file():
        return [], []
    with open(path, newline="", encoding="utf-8") as fh:
        r = list(csv.reader(fh))
    return r[0], r[1:]


def col_sum(header, rows, colname):
    if colname not in header:
        return None
    j = header.index(colname)
    s = 0.0
    for row in rows:
        if j < len(row) and row[j] != "":
            s += float(row[j])
    return s


def file_sha256(path: Path):
    return raw_sha256(path) if path.is_file() else "MISSING"


def build_numbers():
    rows = []  # (quantity, value, source_file, note)

    # --- I6 summary (headline) ---
    i6 = EXT / "output" / "I" / "I6_summary_sample.csv"
    s = read_kv_csv(i6)
    src_i6 = "output/I/I6_summary_sample.csv"
    rows += [
        ("WMVPF_actual", s.get("WMVPF (actual reform)", "NA"), src_i6, "headline"),
        ("WMVPF_bL_cumulative", s.get("WMVPF_bL cumulative (Pure Level)", "NA"), src_i6, "pure Level cumulative"),
        ("WMVPF_bS_cumulative", s.get("WMVPF_bS cumulative (Pure Slope)", "NA"), src_i6, "pure Slope cumulative"),
        ("WMVPF_bL_perqtr_at_T", s.get("WMVPF_bL per-quarter at T (Pure Level)", "NA"), src_i6, "pure Level per-qtr at T"),
        ("WMVPF_bS_perqtr_at_T", s.get("WMVPF_bS per-quarter at T (Pure Slope)", "NA"), src_i6, "pure Slope per-qtr at T"),
        ("eta", s.get("Welfare weight eta", "NA"), src_i6, "welfare weight"),
        ("gamma_CRRA", s.get("CRRA gamma", "NA"), src_i6, "baseline CRRA"),
        ("cons_beneficiaries", s.get("Consumption beneficiaries", "NA"), src_i6, "consumption INSS beneficiaries"),
        ("cons_population", s.get("Consumption population", "NA"), src_i6, "consumption population"),
        ("quarters_analyzed", s.get("Quarters analyzed", "NA"), src_i6, "quarters analyzed"),
    ]

    # --- I4 table last-row welfare + net_cost (dist_reform=12) ---
    i4 = EXT / "output" / "I" / "I4_table_wmvpf_sample.csv"
    hdr, body = read_table_csv(i4)
    src_i4 = "output/I/I4_table_wmvpf_sample.csv"
    if body:
        last = body[-1]
        def cell(c):
            return last[hdr.index(c)] if c in hdr and hdr.index(c) < len(last) else "NA"
        rows += [
            ("WMVPF_actual_I4_welfare_lastrow", cell("welfare"), src_i4, "I4 welfare dist_reform=12"),
            ("WMVPF_actual_I4_netcost_lastrow", cell("net_cost"), src_i4, "I4 net_cost dist_reform=12"),
        ]
    else:
        rows += [
            ("WMVPF_actual_I4_welfare_lastrow", "NA", src_i4, "MISSING"),
            ("WMVPF_actual_I4_netcost_lastrow", "NA", src_i4, "MISSING"),
        ]

    # --- F claim counts ---
    fcc = EXT / "output" / "F" / "new_counterfactual_claim_counts_sample.csv"
    src_fcc = "output/F/new_counterfactual_claim_counts_sample.csv"
    h, b = read_table_csv(fcc)
    rows += [
        ("F_claim_counts_sample_nrow", str(len(b)), src_fcc, "data rows excl header"),
        ("F_claim_counts_sample_sha256", file_sha256(fcc), src_fcc, "full-file sha256"),
        ("F_claim_counts_sample_sum_claims", _fmt(col_sum(h, b, "claims")), src_fcc, "sum claims"),
        ("F_claim_counts_sample_sum_claims_c", _fmt(col_sum(h, b, "claims_c")), src_fcc, "sum claims_c"),
    ]

    # --- F pure schedules ---
    fps = EXT / "output" / "F" / "new_counterfactual_claim_counts_with_pure_schedules_3_sample.csv"
    src_fps = "output/F/new_counterfactual_claim_counts_with_pure_schedules_3_sample.csv"
    h2, b2 = read_table_csv(fps)
    rows += [
        ("F_pure_schedules_sample_nrow", str(len(b2)), src_fps, "data rows excl header"),
        ("F_pure_schedules_sample_sha256", file_sha256(fps), src_fps, "full-file sha256"),
        ("F_pure_schedules_sample_sum_claims", _fmt(col_sum(h2, b2, "claims")), src_fps, "sum claims"),
        ("F_pure_schedules_sample_sum_claims_c", _fmt(col_sum(h2, b2, "claims_c")), src_fps, "sum claims_c"),
        ("F_pure_schedules_sample_sum_claims_L", _fmt(col_sum(h2, b2, "claims_L")), src_fps, "sum claims_L"),
        ("F_pure_schedules_sample_sum_claims_S", _fmt(col_sum(h2, b2, "claims_S")), src_fps, "sum claims_S"),
    ]

    # --- H2 policy elasticity (UNCHANGED INPUT, not regenerated; read for parity coverage) ---
    h2 = EXT / "output" / "H" / "H2_table_results_sample.csv"
    src_h2 = "output/H/H2_table_results_sample.csv"
    hh, hb = read_table_csv(h2)
    def h2_pe(year, estimator):
        if not hb:
            return "NA"
        jy, jp, je = hh.index("year"), hh.index("point_estimate"), hh.index("estimator")
        for row in hb:
            if len(row) > max(jy, jp, je) and row[jy] == year and row[je] == estimator:
                return row[jp]
        return "NA"
    rows += [
        ("policy_elasticity_H2_DD_qtr3",    h2_pe("3", "DD"),     src_h2, "DD +3 (INPUT, not regenerated)"),
        ("policy_elasticity_H2_DDIPW_qtr3", h2_pe("3", "DD-IPW"), src_h2, "DD-IPW +3 (INPUT, not regenerated)"),
        ("policy_elasticity_H2_DD_qtr0",    h2_pe("0", "DD"),     src_h2, "DD event-time 0 (INPUT, not regenerated)"),
    ]

    # --- deck page count ---
    main_pages = 0
    if MAIN_PDF.is_file():
        import fitz
        doc = fitz.open(str(MAIN_PDF))
        main_pages = doc.page_count
        doc.close()
    rows.append(("deck_main_pdf_pages", str(main_pages), "presentation/latex/presentation/_main.pdf", "compiled page count this run"))

    with open(NUMBERS, "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["quantity", "value", "source_file", "note"])
        w.writerows(rows)
    print(f"numbers extracted: {len(rows)} -> {NUMBERS}")
    return rows


def _fmt(x):
    if x is None:
        return "NA"
    # match baseline style: integers where whole, else 4-dp
    if abs(x - round(x)) < 1e-9:
        return str(int(round(x)))
    return f"{x:.4f}"


def main() -> int:
    n_fc, main_pages, errs = build_manifest()
    build_numbers()
    print(f"\nDONE — from_code={n_fc}, deck pages={main_pages}, manifest errors={len(errs)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
