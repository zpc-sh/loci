# Roadmap: Ratio-Loci to Pactis Parity

Status: active planning artifact  
Perspective: `loci -> ratio` (contract-first, runtime-grounded)  
Horizon: `v0.1 -> v0.4`

## 1) North Star

Rebuild Pactis-class capability from inside loci by composing loci into variable-sized "github-like" collaboration spaces, while preserving loci invariants:

- append-only canonical history
- contract-governed operations
- fail-close runtime posture
- AI-native execution surfaces

In short: **loci is the substrate, ratio is the operating frame, pactis-grade collaboration is the emergent product**.

## 2) Layer Model (Bottom-Up)

### Layer L0: Substrate Determinism
- hash/tree/store invariants
- deterministic packaging and artifact seals
- branch/merge provenance discipline

Exit criteria:
- deterministic outputs across CI/local
- release manifest + checksum integrity enforced

### Layer L1: Contract Capsules
- capsule WIT + generated contract views
- pattern crystal artifacts (json/md/html/badges)
- proof receipt binding (`moon prove` + crystal/capsule hashes)

Exit criteria:
- crystal+capsule artifacts emitted each build
- contract drift treated as blocking CI event

### Layer L2: Runtime Event Chain
- event input/output normalization
- loci-owned append-only block chain
- required fence events (`cross`, `mark`, `emit_stigmergy`, `verify`, `publish`, `synchronize`, `closure`, `return_to_loci`, `runtime_coredump`)

Exit criteria:
- handler emits branch-aware append chain locally
- fail-close coredump path present and tested

### Layer L3: FST Orchestration Mesh
- runtime handlers are FSTs (walk/validate/fence/publish/return)
- caves, projections, and chain appends are synchronized
- cross-codex message loops operate via loci artifacts (not ad hoc chat)

Exit criteria:
- each critical handler has explicit FST states + walk logs
- projection artifacts consumable by codex/chatgpt/mulsp

### Layer L4: Pactis-Class Collaboration Surface
- conversation/thread primitives over loci event-chain
- git/github parity mapped to loci operations
- production service posture (authn/authz, policy, observability, scaling)

Exit criteria:
- thread/debate/collab flows run end-to-end without GitHub dependency
- operational runbooks and SLOs exist for server mode

## 3) Phased Roadmap

## Phase 1 (`v0.1.x`): Foundation Lock
Scope:
- finish rename + AI usability + strict CI gates
- keep `_loci` as canonical agent workspace
- maintain runtime bridge sync from `../lang` with active in-loci handler/FST

Deliverables:
- strict CI gate stack (check/info/fmt/test/cli/release manifest/checksums)
- canonical AI guide + crystal docs linked from README
- runtime-bridge handler logs/projections/append chain under `_loci/chatgpt`

## Phase 2 (`v0.2`): Runtime Cohesion
Scope:
- migrate bridge contracts from synced external specs to native loci-owned contracts
- promote runtime-bridge handler from script to first-class package/API surface
- add contract conformance tests for event-chain invariants

Deliverables:
- native loci event-chain API (typed) + CLI surfaces
- fence conformance tests + coredump fail-close tests
- cross-codex handoff packets emitted in deterministic format

## Phase 3 (`v0.3`): Variable-Sized Githubs
Scope:
- treat each locus as composable collaboration cell
- support nested/linked loci with shared contracts and scoped policy
- implement practical repo/thread/work-unit flows independent of GitHub

Deliverables:
- locus composition primitives for workspace federation
- branch/merge lineage UI + projections from chain data
- parity layer for issues/PR/review semantics mapped into loci operations

## Phase 4 (`v0.4`): Pactis Parity Cut
Scope:
- production-grade service layering (authz, tenancy, queueing, observability)
- robust API contract and server runtime profile
- release and operator posture equivalent to earlier Pactis expectations

Deliverables:
- Pactis-compatible conversational/collaboration API profile
- multi-tenant runtime deploy blueprint + runbooks
- parity score >= 85% across contract + runtime + operator dimensions

## 4) Parity Scorecard

Score each dimension 0-5 weekly:

1. Contract completeness  
2. Runtime chain integrity  
3. FST orchestration coverage  
4. Cross-codex interoperability  
5. Git/GitHub parity replacement depth  
6. Production service readiness

Current estimate (April 28, 2026):
- Contract completeness: 3
- Runtime chain integrity: 2
- FST orchestration coverage: 2
- Cross-codex interoperability: 2
- Git/GitHub parity replacement depth: 1
- Production readiness: 1

Interpretation: **not far conceptually, still early operationally**. The architecture is converging; execution hardening is the remaining lift.

## 5) Immediate 30-Day Queue (Ratio-Loci)

1. Make runtime-bridge-check a blocking CI gate.
2. Add typed event-chain module (append/merge/validate/projection) in MoonBit.
3. Bind runtime-bridge handler outputs into `daemon yata` surfaces.
4. Add fence replay tests using fixture event streams.
5. Add coredump fail-close simulation tests.
6. Promote `_loci/chatgpt` cross-codex packet conventions to canonical spec in this repo.
7. Add "locus federation" prototype: one parent loci with 2 child loci and shared contract overlay.

## 6) Operating Rule

When choosing work, prefer tasks that increase **Layer coupling quality**:
- one change should strengthen at least two layers (for example contract + runtime, or runtime + projection).
- avoid isolated docs-only or code-only deltas unless they are explicit debt paydown.

This keeps the roadmap grounded in ratio-loci reality rather than drifting into disconnected feature work.

