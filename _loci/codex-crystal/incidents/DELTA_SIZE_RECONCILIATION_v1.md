# Delta Size Reconciliation (v1)

## Question
Why was a `+120k` scale change observed, and what was introduced?

## Measured Baselines
As of 2026-05-02:

- `PR#9 merge (87ecfe8f) -> current HEAD (ce305c3)`:
  - files changed: 434
  - insertions: 27,294
  - deletions: 2,308
  - net: +24,986

- Current unstaged tracked worktree delta (`HEAD -> working tree`):
  - files changed: 36
  - insertions: 384
  - deletions: 91
  - net: +293

## What Inflated the Delta
Largest net-introduced buckets in `PR#9 -> HEAD`:

1. `_loci` (+9,466)
2. `loci` (+2,882)
3. `cli` (+2,880)
4. `docs` (+2,445)
5. `loci_fsm` (+1,815)
6. `model` (+1,629)
7. `wit` (+1,050)

Notable pattern: duplicated semantic surfaces under both `_loci/` and `loci/` plus broad docs/contracts growth.

## Likely Source of `+120k` Perception
The larger perceived number is consistent with one or more of:

- Comparing against a different historical anchor than PR#9.
- Counting untracked quarantine split trees (`recovery/loci_turd`, `recovery/loci_clean`) in external tooling.
- Aggregating generated artifacts/logs and non-tracked mirrors in ad-hoc scans.
- Multi-repo or cloud-task-level aggregate rather than single-repo git delta.

## Contractual Next Step
Treat `PR#9 merge commit` as the clean arithmetic baseline for this repository and use `recovery/artifacts/loci_clean_vs_turd.diff` for collision triage.
