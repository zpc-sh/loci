# Loci Boundary Gates (v0)

This spec defines immediate fail-close guards used by local scripts and CI.

## Gate 1: `loci_legacy_write_gate`
- Canonical root: `_loci/`
- Legacy root: `loci/`
- Rule: writes under `loci/` fail unless prefix-allowlisted in `.well-known/loci-sparse-boundary-policy.json`.

## Gate 2: `loci_text_contamination_scan`
Detect and gate on:
- BiDi controls (`U+202A..U+202E`, `U+2066..U+2069`)
- ESC/C1 escape bytes (`0x1B`, `0x9B`)
- Disallowed ASCII controls (except `\n`, `\r`, `\t`)

## Gate 3: `loci_sparse_boundary_eval`
- Evaluate changed paths against sparse boundary policy.
- Emit machine report under `artifacts/security/`.
- Fail-close on legacy writes and blocked instruction-plane path matches.
