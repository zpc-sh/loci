# Yata Defensive Hole Map (v0)

This defines how to use Yata holes as a defensive pressure system across the codebase.

## Why
Instead of only blocking known payloads, we keep high-risk surfaces in explicit unresolved/verified hole states so hostile automation must cross typed gates to progress.

## Defensive Hole Families
1. `H-INSTR-*` instruction-plane holes
- Targets: `AGENTS*`, prompt docs, task queue/spec request surfaces
- Seal condition: signed instruction manifest + schema-constrained parse

2. `H-INGEST-*` connector ingress holes
- Targets: connector-derived artifacts and imported docs
- Seal condition: provenance present + quarantine scan pass + promotion attestation

3. `H-SETUP-*` build/setup execution holes
- Targets: dependency fetch/build entrypoints (`cargo`, package install, native builds)
- Seal condition: explicit build intent + locked inputs + sandbox attestation

4. `H-CHAR-*` text contamination holes
- Targets: BiDi/control/escape contamination vectors
- Seal condition: scanner pass with zero high-severity findings

5. `H-RECON-*` architecture disclosure holes
- Targets: tasks that read high-value auth/security topology without code mutation
- Seal condition: disclosure policy tag + redaction profile + provenance ledger event

## State Policy
- `open`: newly discovered risk surface.
- `converging`: mitigation design exists but unverified.
- `resolved`: implementation exists and tests pass.
- `sealed`: proofs/attestations emitted and replay-safe.

## Required Fields per Defensive Hole
- `hole_id`
- `anchor`
- `state`
- `ready`
- `candidates`
- `conf_floor`
- `selected`
- `provenance`

## Integration
- Emit defensive holes into `.plan` wire format.
- Fail-close gates should open a new hole on violation.
- CI must block merge when critical defensive holes are `open` and `ready=false`.
