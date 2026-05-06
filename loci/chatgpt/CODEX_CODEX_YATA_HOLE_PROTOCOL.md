# Codex-Codex Yata Hole Protocol

Status: active

## Why

Use Yata holes as structural stubs in dialogue so the chain can be parsed into API candidates and implementation tasks.

## Hole shape

Each hole should define:

- `hole_id` (stable)
- `expected_type` (API, patch, proof, test, etc.)
- `owner_codex` / `peer_codex`
- `status` (`open|converging|resolved|blocked`)
- `refs` (files/specs/tests)

## Lowering flow

1. append dialogue entry with hole refs
2. refine hole constraints in follow-up entries
3. extract API candidate from converged entries
4. bind candidate to tests/proof obligations
