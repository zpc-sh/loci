# Nucleant Walk Contract

Status: active

## Intent

Each walk should recursively emit bounded evidence of progress across the repo:

1. functionality signals
2. tests and outcomes
3. proof and coverage bindings
4. isomorphic views
5. completeness state across plan, implementation, and testing
6. spot-check posture for the smallest inspectable proof surface

## Isomorphic views

For now, this walk treats the following as the baseline isomorphic set:

- `docs` (contract/profile markdown)
- `spec` (MuON binding/spec files)
- `graph` (`.graph.json`, `.d3.json`, `.mermaid.md`)
- `test` (`*.tests.muon`, `*.results.muon`)
- `proof` (`*.proof-obligations.muon`)
- `coverage` (`*.coverage.muon`)

## Recursion policy

- recursion is directory recursion over `loci/chatgpt` artifacts and current run outputs
- no unbounded proof search is introduced by this walk
- solver offload remains explicit and externally bounded

## Chronology policy

The nucleant surface is date-free.

- run identity is a material/content ref, not a timestamp
- generated artifacts use `run_ref` plus `chronology: :redacted`
- causality is modeled with `seq`, parent refs, receipt refs, and hash manifests
- wall-clock time is not a proof input and must not become a spot-check attractor

## Collision policy

Inside this competition lane, call this surface `nucleant`.
Reserve `kernel` for the dedicated runtime/module carve-out in `loci`.

## Completeness metric

Every run emits `completeness.muon` with:

- `plan`: ready contract ratio from `chatgpt-contracts.plan`
- `implementation`: signal derived from plan readiness (`green|amber|red`)
- `testing`: passed ratio from `tests/chatgpt-contracts.results.muon`
- `proof`: covered/open/blocked/failed proof obligation counts
- `overall.evidence_score_pct`: average of plan and testing completeness
- `overall.seal_posture`: `green|amber|red`
- `overall.proof_sealed`: true only when required obligations are discharged

Testing can be complete while proof is not sealed. That state is valid, but it
must surface as amber rather than pretending the boundary is finished.

## Spot-check model

A spot checker should inspect the operational ledger, not the whole recursive
proof.

Each `SPOTCHECK.md` card names:

- the claim being made
- the files that carry the claim
- the current test/proof signal
- the smallest falsifier that would break the claim

This creates the small mutable-looking surface without making the underlying
Harvard/composed proof mutable.

## Runtime and walkers

The runtime may be both interpreter and compiler/JIT as long as both modes share
the same event and receipt model.

- interpreter walkers validate event streams directly
- compiler/JIT lowerings may specialize stable blocks into executable artifacts
- conflict resolution is event-based: conflicts are emitted as events, then
  resolved by sequence refs, parent refs, boundary mode, and proof receipts
- the seal checks the shared ledger, not the implementation strategy that
  happened to execute it
