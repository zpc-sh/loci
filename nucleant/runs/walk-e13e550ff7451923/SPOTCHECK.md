# Nucleant Spot-Check Ledger

run_ref: `walk-e13e550ff7451923`
identity_basis: `material_hash`
chronology: `:redacted`

## Contract Binding Nucleant

- claim: contract surfaces bind to tests, coverage, and proof obligations before seal.
- files: `loci/chatgpt/specs/chatgpt-contract-binding.muon`, `loci/chatgpt/tests/chatgpt-contracts.results.muon`, `loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon`
- test signal: 30/30 passed, 0 failed, 0 blocked
- proof signal: 1/3 covered, 1 open, 1 blocked
- falsifier: a required proof obligation is open/blocked while the seal reports green.

## Async Boundary Nucleant

- claim: the core stays synchronous; asynchronous effects are normalized into receipts at the boundary.
- files: `loci/chatgpt/ASYNC_BOUNDARY_STANCE.md`
- falsifier: core contract evaluation waits on ambient async state instead of an explicit receipt.

## Append-Only Dialogue Nucleant

- claim: ChatGPT/Codex dialogue is append-only, sequence-addressed, and date-free.
- files: `loci/chatgpt/DIALOGUE_APPEND_ONLY_MUON_SPEC.md`, `loci/chatgpt/dialogue/chatgpt-codex.muonlog`
- falsifier: an entry relies on wall-clock ordering, self-attested identity, or in-place mutation.

## Event Walker Nucleant

- claim: interpreter walkers and compiled/JIT lowerings consume the same event and receipt model.
- files: `nucleant/NUCLEANT_WALK_CONTRACT.md`
- falsifier: interpreter and compiled paths accept different conflict-resolution facts.
