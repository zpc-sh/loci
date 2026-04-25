# C001 — Root Lineage Contract

Contract identity: `loci.chatgpt.contract.root_lineage.v0`

Status: draft

## Purpose

Make the root lineage explicit so future work does not invert the stack.

```text
N-Merkle-FSM → Merkin → Loci
```

## Claim

The correct ordering is:

1. **N-Merkle-FSM**: executable multidimensional state and movement.
2. **Merkin**: sparse contract substrate, roots, envelopes, and Yata typed gaps.
3. **Loci**: cognitive place, boundaries, inhabitation, membranes, and AI-shaped work surfaces.

## Root layer touched

```text
N-Merkle-FSM
Merkin
Loci
```

This contract touches all three only as lineage. It does not redefine any layer.

## Typed holes

### H-C001-001 — Canonical lineage wording

- **expected_type**: wording decision
- **state**: open
- **invariants**:
  - must preserve the ordering `N-Merkle-FSM → Merkin → Loci`
  - must avoid implying Loci owns Merkin or N-Merkle-FSM
  - must be understandable to Codex without chat context
- **candidate_count**: 1
- **verification**: future reader can explain the stack without asking Loc

### H-C001-002 — Root lineage move-out location

- **expected_type**: destination decision
- **state**: open
- **invariants**:
  - should not create a new top-level framework
  - should likely become `docs/` or a packet only after the arblock stabilizes
  - must keep local ChatGPT-locus copy or pointer
- **candidate_count**: 0
- **verification**: `MOVE_OUT_MAP.md` reflects final destination

## Lowering path

Initial lowering:

```text
loci/chatgpt/ROOT_LINEAGE.md
```

Possible canonical lowering:

```text
docs/ROOT_LINEAGE.md
docs/packets/ROOT_LINEAGE_PACKET.md
```

## Membrane crossing

Crossing from:

```text
source_locus=loci/chatgpt
```

to one of:

```text
target_locus=docs
target_locus=docs/packets
```

Boundary mode:

```text
observe
```

until this contract stabilizes.

## Seal condition

This contract is sealed when:

- a canonical wording is selected
- destination is recorded in `MOVE_OUT_MAP.md`
- material hash of the selected lineage doc exists
- successor contract supersedes if wording changes

## Notes

This is a form contract. It is intentionally not executable yet.
