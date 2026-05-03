# Git-Replacement Test Dimensions (v0.1)

## Why this exists

If `loci` aims to replace Git-like workflows, we need proof beyond "it feels like pull/merge/submit works." This spec defines the dimensions of evidence needed to claim reliability, safety, and operability.

## Framing: User tasks vs. system guarantees

Users think in tasks:

- pull
- merge
- submit

A replacement system must prove deeper guarantees underneath those tasks:

- history integrity
- deterministic state transitions
- collaboration correctness under concurrency
- recovery under failure and partial connectivity
- policy/compliance and auditability

## Test Dimension 1 — Repository State Correctness

### Goal

Any workspace state can be reconstructed and validated from canonical persisted state.

### What to prove

- Object/state references are never silently corrupted.
- Snapshot/materialization reproduces expected files and metadata.
- Rename/delete/modify semantics are preserved across round-trips.

### Example tests

- Property tests over random file-tree mutations.
- Golden tests for edge cases: large trees, binary blobs, symlink-like constructs (if supported).
- Corruption-injection tests that verify explicit detection (not silent success).

## Test Dimension 2 — History and Causality Integrity

### Goal

Lineage is tamper-evident and causally coherent.

### What to prove

- Parent/ancestor relations are valid and acyclic.
- Rewriting operations are explicit and audit-marked.
- History queries return deterministic answers.

### Example tests

- DAG invariant checks after every history operation.
- Fuzz tests that interleave branching, rebasing/cherry-pick-like operations (if supported), and compaction.
- Deterministic replay tests from event logs.

## Test Dimension 3 — Pull/Sync Semantics

### Goal

Distributed synchronization converges to equivalent state with clear conflict outcomes.

### What to prove

- Idempotent pulls (pulling twice does not mutate state unexpectedly).
- Partial fetch/sparse sync correctness (if supported).
- Stable and explainable conflict detection.

### Example tests

- Two- and N-peer simulation tests with delayed/out-of-order transport.
- Packet/drop/reorder fault tests.
- Sync convergence tests with eventual consistency constraints.

## Test Dimension 4 — Merge/Integrate Semantics

### Goal

Merges are deterministic, reviewable, and policy-compliant.

### What to prove

- Merge base selection is correct.
- Merge output determinism given same inputs + strategy.
- Conflict markers/resolution metadata are structurally valid.

### Example tests

- Differential tests against a reference model for supported merge modes.
- Pathological conflict corpus tests (rename+edit, directory/file swaps, binary conflicts).
- Determinism tests across platforms/locales/timezones.

## Test Dimension 5 — Submit/Publish Workflow Guarantees

### Goal

"Submit" produces auditable, policy-checked, reproducible publication events.

### What to prove

- Access control and branch protection analogs are enforced.
- Required checks/gates cannot be bypassed by alternative API paths.
- Published artifacts can be traced to exact source state.

### Example tests

- Authorization matrix tests (actor × action × scope).
- Required-check bypass attempts.
- End-to-end provenance tests (submit -> artifact -> source digest).

## Test Dimension 6 — Concurrency and Multi-Actor Safety

### Goal

Multiple users/agents can act concurrently without hidden data loss.

### What to prove

- No lost updates under concurrent writes.
- Explicit conflict surfacing, not silent last-writer-wins unless configured.
- Locking/lease semantics (if present) are enforced and recoverable.

### Example tests

- Linearizability or serializability checks for critical operations.
- Chaos-style concurrent actor simulation.
- Long-running branch divergence and reconciliation scenarios.

## Test Dimension 7 — Failure Recovery and Durability

### Goal

System survives crashes, power loss, and partial writes while preserving recoverability.

### What to prove

- Crash-safe commit protocol (or equivalent atomic state transition).
- Journal/log replay correctness.
- Backup/restore and point-in-time recovery validity.

### Example tests

- Crash injection between each persistence step.
- Disk-full and permission-failure tests.
- Restore drills from intentionally stale snapshots.

## Test Dimension 8 — Security and Trust Boundaries

### Goal

Hostile input and actor behavior cannot violate integrity or exfiltrate protected data.

### What to prove

- Input validation on protocol and object ingestion.
- Signature/identity verification behavior (if applicable).
- Secret isolation in CLI/TUI logs and telemetry.

### Example tests

- Fuzzing parsers and protocol handlers.
- Adversarial repo/object fixtures.
- Redaction tests for logs, diagnostics, and error messages.

## Test Dimension 9 — Performance and Scale Envelopes

### Goal

Operations remain usable at sizes and team scales expected in production.

### What to prove

- Latency SLOs for core operations (init/sync/merge/submit/status/log).
- Throughput under concurrent CI/agent usage.
- Resource ceilings (CPU, memory, IO, network) are predictable.

### Example tests

- Benchmark suites at small/medium/very-large repo sizes.
- Load tests with realistic branch and PR churn.
- Regression guardrails with performance budgets in CI.

## Test Dimension 10 — UX/Operability for CLI/TUI

### Goal

Human operators can understand outcomes quickly and recover from failure safely.

### What to prove

- Errors are actionable and include remediation hints.
- Output remains stable enough for scripts where promised.
- TUI state transitions avoid ambiguous destructive actions.

### Example tests

- Snapshot tests for CLI contract surfaces.
- Usability task tests for common and failure flows.
- Accessibility checks for TUI readability and keyboard-first navigation.

## Minimum release evidence bar (suggested)

Before claiming "Git-replacement readiness" for a release train:

1. All 10 dimensions have at least one automated suite in CI.
2. High-risk dimensions (2, 3, 4, 6, 7, 8) include fault injection or fuzzing.
3. Each core user operation (`pull`, `merge`, `submit`) is covered by:
   - unit tests,
   - integration tests,
   - distributed/concurrency tests,
   - recovery-path tests,
   - policy/security tests.
4. A living "known gaps" report is published with explicit risk acceptance.

## Suggested immediate next moves

1. Build a capability map from current loci features to the 10 dimensions.
2. Mark each area as: `Not Started`, `Partial`, `Covered`, or `Production Grade`.
3. Create CI jobs by dimension to avoid one giant opaque test stage.
4. Start with determinism + recovery + sync convergence as priority test tracks.
