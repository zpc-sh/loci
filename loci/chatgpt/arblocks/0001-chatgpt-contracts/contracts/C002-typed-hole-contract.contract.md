# C002 — Typed Hole Contract Contract

Contract identity: `loci.chatgpt.contract.typed_hole_contract.v0`

Status: draft

## Purpose

Define the minimum form for ChatGPT-emitted contracts that expose typed holes rather than hiding uncertainty in prose.

## Claim

A ChatGPT contract is useful only if it preserves open decisions as typed holes.

The contract should not pretend a system is complete when the correct output is a shaped gap.

## Root layer touched

```text
Merkin / Yata
Loci / ChatGPT locus
```

## Contract shape

A minimal ChatGPT contract SHOULD include:

```text
contract_identity
status
purpose
claim
root_layer_touched
typed_holes
lowering_path
membrane_crossing
seal_condition
notes
```

## Typed holes

### H-C002-001 — Contract field set

- **expected_type**: schema/profile decision
- **state**: open
- **invariants**:
  - must remain small enough for Codex to use immediately
  - must preserve typed holes as first-class sections
  - must not require canonical parser changes at v0
  - should lower into Yata `.plan` entries later
- **candidate_count**: 1
- **verification**: at least three contracts in this arblock follow the shape

### H-C002-002 — Yata lowering vocabulary

- **expected_type**: mapping decision
- **state**: open
- **invariants**:
  - must map contract holes to Yata entries without mutating Yata core first
  - should reuse `state`, `ready`, `candidate_count`, `confidence_floor`, `selected_candidate`, and `provenance`
  - should not overload `state` with provider-specific meanings
- **candidate_count**: 0
- **verification**: one `.plan` example can represent this contract faithfully

### H-C002-003 — Parser timing

- **expected_type**: implementation timing decision
- **state**: open
- **invariants**:
  - docs/profile first
  - parser/model support only after examples stabilize
  - no strict parser breakage for existing `.plan`
- **candidate_count**: 0
- **verification**: move-out map distinguishes profile from parser work

## Lowering path

Local:

```text
loci/chatgpt/arblocks/0001-chatgpt-contracts/contracts/*.contract.md
```

Later:

```text
Yata plan profile
muyata contract work family
possibly model/chatgpt_contract.mbt
```

## Membrane crossing

Crossing from local contract file to canonical profile should use:

```text
boundary_mode=observe
intent=canonicalize
artifact_type=contract
```

Model/parser work should use:

```text
boundary_mode=strict
intent=implement
artifact_type=model
```

## Seal condition

This contract is sealed when:

- the contract shape is used by this arblock
- a Yata lowering example exists
- future Codex can parse the fields by convention without asking for explanation

## Notes

This is the contract for contracts. Keep it boring. Boring is the lock.
