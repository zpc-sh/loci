# QuickCheck Lane

Status: planned

Goal: add property-based checks for contract and solver-receipt invariants.

## First properties

1. `ContractBinding::required_open_count` is always between `0` and `obligations.length`.
2. `actionable_obligations().length == required_open_count()`.
3. `can_seal_with_solver(Some(receipt))` implies `can_seal()`.
4. Non-completed solver status never verifies as receipt evidence.

## Boundary constraints

- property generators must be deterministic under fixed seed
- async boundary behavior must be modeled as receipt/status inputs, not async runtime coupling in core tests
- failures should emit shrinking trace into `loci/chatgpt/tests/` as reproducible artifacts
