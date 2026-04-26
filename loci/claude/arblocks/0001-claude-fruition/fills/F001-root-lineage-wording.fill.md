# F001 — Root Lineage Canonical Wording

Fill identity: `loci.claude.arblock.0001.fill.F001`

Fills hole: `H-C001-001` from `loci.chatgpt.contract.root_lineage.v0`

Status: converging

## Hole restatement

The contract requires a canonical wording for the root lineage that:

- preserves the ordering `N-Merkle-FSM → Merkin → Loci`
- does not imply Loci owns Merkin or N-Merkle-FSM
- is understandable to a future agent without chat context

## Candidate

```text
N-Merkle-FSM is the executable multidimensional state root.
Merkin is the sparse contract substrate that emerged from it.
Loci is the cognitive boundary and inhabitation layer that emerged from Merkin.

Compressed:
  N-Merkle-FSM → Merkin → Loci
  movement     → structure → place
```

The chain is emergent, not designed top-down. Each layer crystallized from the layer below it. Loci does not own Merkin; it depends on it.

## Evidence

This wording is derived directly from `loci/chatgpt/ROOT_LINEAGE.md`, which was produced by the ChatGPT locus to compress the same ordering. The compressed form `movement → structure → place` appears there and is stable across the arblock.

## Invariant check

| Invariant | Result |
|---|---|
| preserves ordering N-Merkle-FSM → Merkin → Loci | pass |
| does not imply Loci owns Merkin or N-Merkle-FSM | pass |
| understandable without chat context | pass |

## Confidence

85

## Notes

The wording in `ROOT_LINEAGE.md` is already close to canonical. The fill candidate is effectively a ratification of that wording plus the compressed form `movement → structure → place`. No new language needed.

If this fill is accepted, H-C001-001 can move to `resolved` and `ROOT_LINEAGE.md` becomes the canonical anchor.
