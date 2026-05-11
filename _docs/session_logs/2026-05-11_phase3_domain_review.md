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

## Next Steps

- Commit Phase 3 review reports
- If professors confirm findings, fix bugs in Phase 4
- Phase 4: Stage-by-stage reruns on sample data (requires data access)
