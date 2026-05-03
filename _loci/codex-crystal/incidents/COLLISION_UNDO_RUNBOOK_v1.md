# Collision Undo Runbook (v1)

## Purpose
Recover from repository collision/taint while preserving forensic evidence, then restore development from a trusted baseline.

## Principles
- Evidence first, mutation second.
- Deterministic rollback only (commit-SHA anchored).
- Reintroduce changes only through reviewed allowlists.
- Canonical locus root remains `_loci/`.

## Trusted Anchors
- Trusted baseline SHA: `ab1304e07a3c6db10cb7b9cb178193017ff462e1`
- Known local checkpoint SHA: `ce305c3e6cdecaa2f8a77e7bac7385d525e18e45`

## Phase 0: Incident Freeze
1. Stop all task automation and connector-triggered background workflows.
2. Do not pull, merge, or run build/test commands on the contaminated tree.
3. Record current wall-clock UTC and operator identity in incident log.

## Phase 1: Evidence Preservation
1. Make an immutable full copy of the repository directory, including `.git`.
2. Export these snapshots from contaminated state:
- `git status --porcelain=v1`
- `git log --oneline --decorate -n 100`
- `git reflog --date=iso`
- full diff patch (`git diff` + `git diff --cached`)
- untracked file manifest
3. Save security artifacts:
- `artifacts/security/trust_report.json`
- `artifacts/security/loci_mirror_check.json`
- incident docs under `_loci/codex-crystal/incidents/`
4. Hash all exported artifacts (SHA-256 manifest).

## Phase 2: Clean Restore
1. Create a fresh worktree/clone from trusted baseline SHA.
2. Verify baseline commit and remote integrity before any file import.
3. Apply zero user changes initially; confirm clean status.
4. Re-run static trust checks on clean tree (no build, no dependency fetch).

## Phase 3: Controlled Reintroduction
1. Build an explicit allowlist of files to restore from contaminated copy.
2. Restore in batches by subsystem:
- docs/incident-only
- `_loci` canonical artifacts
- approved code paths
3. After each batch:
- review diff
- check executable bits against allowlist
- run BiDi/escape scanner
- run sparse-tree boundary checks
4. Reject any file failing trust policy; quarantine separately.

## Phase 4: Dual-Root Collision Resolution
1. Keep `_loci/` as canonical write surface.
2. Treat `loci/` as legacy mirror only.
3. Enforce mirror drift report and fail on unauthorized divergence.
4. Require explicit sync tooling for any mirror updates.

## Phase 5: Security Gate Before Resume
Resume normal work only when all pass:
- provenance report generated
- no unexpected executables
- no unresolved BiDi/control-char findings
- instruction-plane policy checks pass
- sparse-tree boundary checks pass

## Phase 6: Post-Incident Controls
1. Incident retrospective with root-cause hypotheses and confidence levels.
2. Add permanent CI gates (see roadmap doc).
3. Submit OpenAI packet and track response SLAs.

## Abort Conditions
Stop rollback and return to freeze if:
- trusted baseline mismatch appears,
- evidence hash mismatch appears,
- new unexplained task artifacts appear during restore.

