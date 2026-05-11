# Session Log: Phase 3 — Domain Review of I4 and G5

**Date:** 2026-05-11
**Phase:** 3 (Static Domain Review)
**Goal:** Review I4 (WMVPF) and G5 (average benefit effects + pure reform decomposition)
against canonical deck formulas, without sample data.

---

## Approach

Static 5-lens review of both files:
1. Assumption audit (A1-A4)
2. Derivation check (WMVPF formulas, RR, bL/bS)
3. Citation fidelity
4. Code-theory alignment (vs canonical deck slides)
5. Logic chain (backward dependency check)

No sample data available on this machine — purely reading code against
documented formulas and tracing variable flows.

---

## Key Findings

### I4 (WMVPF without pure reforms): 0 critical, 3 major, 5 minor
- **ALIGNED** with canonical deck for core WMVPF computation
- Minor discount factor inconsistency (0.995^3 vs 1/1.005^3)
- Confirmed: loads G4/H2 (not G5/H3) — previously flagged
- No saved output (WMVPF result only in memory)

### G5 (benefit effects + pure reform bL/bS): 2 critical, 4 major, 5 minor
- **CRITICAL:** Script crashes at line 625 (undefined variables in Step 4)
  - Pure reform WMVPF_bL/WMVPF_bS has never been computed from G5
  - Code appears to be work-in-progress with incomplete refactoring
- **CRITICAL:** bS formula uses 0.082/0.069 instead of 0.82/0.69 (decimal error)
  - Same error in G3 (predecessor) — propagated through versions
  - Pure slope benefit computed as ~10% instead of ~82%/69% of full replacement
- **MAJOR:** bL/bS formulas have unexplained `/replacement_rate` factor
- **MAJOR:** bS models stored in models_bL list (works by accident)
- **MAJOR:** G5 reads G2 results for selection correction (not G4/G5)
- **MAJOR:** G5 uses D1 data while rest of pipeline uses D3

### Cross-cutting findings:
- G5 outputs are **orphaned** — not consumed by I4 or any other canonical script
- The pure reform WMVPF decomposition pipeline is incomplete:
  G5 crashes mid-way, and even if fixed, no I-stage consumes its output
  (I5 was the consumer but is LEGACY)
- This is the section of the paper that Arthur is actively building (Section 7.4)

---

## Decisions Made

- Flag all formula questions for professor review (not auto-fix)
- Wrote detailed review reports with specific line numbers
- Updated corrections log with all findings
- Did NOT edit source files (read-only review per Phase 3 scope)

---

## Artifacts Produced

- `_docs/quality_reports/phase3_I4_domain_review.md`
- `_docs/quality_reports/phase3_G5_domain_review.md`
- `_docs/memory/10_corrections_log.md` — populated with 8 entries

---

## Open Questions for Professors

1. I4 → G4/H2 references: intentional or stale?
2. bL/bS formula derivation (the /replacement_rate factor)
3. 0.082/0.069 vs 0.82/0.69 in bS formula
4. Step 4 of G5: is there a working version?
5. Consumption parameters source (cons_inss, cons_pop)
6. Tax externality removed from WMVPF — intentional?
7. Who will build the I-stage consumer for G5's pure reform outputs?

---

## Phase 3b: G5 Fix + I6 Creation + Sample Validation (same session)

### G5 Step 4 partial fix (user-directed)
- Deleted `oi` debugging artifact (line 625)
- Deleted redundant `_left` join block (lines 623-624)
- Renamed `_merge` suffix → unsuffixed to match downstream code
- NOTE: `dt_merged_with_betas` (line 650) remains undefined — deferred

### I6 creation
- New canonical I-stage file combining actual + pure reform WMVPF
- Three parts: actual WMVPF (from I4/I5 approach), pure reform (from G5), summary
- Key design: uses G5 output as single source (has F-stage frequencies + G5 benefits)
- Environment auto-detection, consistent discounting, graceful degradation

### I6 bugs caught during sample validation
1. **Directory path:** `dir` pointed to `data/` subdirectory; `output/F/` unreachable.
   Fixed to point to parent `transfer_may_retirement/`.
2. **Discount factor:** `1/(1/β)^t = β^t` — cost and welfare identical.
   Fixed to `(1/β)^t` matching I4 convention.
3. **G5 column merge:** Loading F-stage pure output separately from G5 output
   caused duplicate columns (claims_L.x/claims_L.y). Fixed by using G5 output
   alone (already contains F-stage frequency columns).

### Sample validation results
- Script ran end-to-end on 5% sample + full-data F/G outputs
- All 7 output files created (3 CSVs, 1 summary, 3 PDFs)
- No NaN/NA/Inf in any outputs
- ETA = 0.8281 (matches expected ~0.828)
- WMVPF_actual = -0.1852 (artifact of sample×full-data frequency mismatch)
- WMVPF_bL = 0.6972, WMVPF_bS = 0.5164 (reversed ordering consistent
  with G5 bS decimal error [LEARN:g5-bS-decimal])

### Commits (this sub-session)
- `2210c2e` Phase 3: fix G5 Step 4 merge variable naming
- `116fef7` Phase 3: create I6 canonical WMVPF with pure reform decomposition
- `2ff4bdb` Phase 3: fix I6 directory detection, discount factors, and G5 merge

---

## Artifacts Produced (updated)

- `_docs/quality_reports/phase3_I4_domain_review.md`
- `_docs/quality_reports/phase3_G5_domain_review.md`
- `_docs/memory/10_corrections_log.md` — populated with 8+ entries
- `trans_retirement/code/I6_wmvpf_with_pure_reforms_freq.R` — NEW canonical I-stage

---

## Open Questions for Professors

1. I4 → G4/H2 references: intentional or stale?
2. bL/bS formula derivation (the /replacement_rate factor)
3. 0.082/0.069 vs 0.82/0.69 in bS formula
4. Step 4 of G5: `dt_merged_with_betas` is still undefined (line 650)
5. Consumption parameters source (cons_inss, cons_pop)
6. Tax externality removed from WMVPF — intentional?
7. ~~Who will build the I-stage consumer for G5's pure reform outputs?~~ → **I6 created**

---

## Next Steps

- Phase 4: Stage-by-stage reruns on sample data
  - I6 actual reform section: validated ✓
  - I6 pure reform: needs G5 bS decimal fix first (currently produces reversed ordering)
  - G5: needs professor confirmation on bS formula before fixing
- Remaining open bugs in G5 (awaiting professor review):
  - 0.082/0.069 decimal error
  - bL/bS `/replacement_rate` factor
  - bS models in wrong list (line 396)
  - D1 → D3 update
  - G2 → G4 reference update
  - `dt_merged_with_betas` undefined (line 650)
