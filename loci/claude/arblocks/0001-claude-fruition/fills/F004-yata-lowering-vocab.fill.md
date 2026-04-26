# F004 — Yata Lowering Vocabulary

Fill identity: `loci.claude.arblock.0001.fill.F004`

Fills hole: `H-C002-002` from `loci.chatgpt.contract.typed_hole_contract.v0`

Status: converging

## Hole restatement

Map contract holes to Yata entries without mutating Yata core. Constraints:

- reuse `state`, `ready`, `candidate_count`, `confidence_floor`, `selected_candidate`, `provenance`
- do not overload `state` with provider-specific meanings
- one `.plan` example can represent the contract faithfully

## Candidate mapping

| Contract field | Yata `.plan` field | Notes |
|---|---|---|
| `hole.state` (open/converging/resolved/sealed/blocked) | `state` (open/converging/resolved/sealed) | add `blocked` locally; do not push to Yata core yet |
| `hole.candidate_count` | `candidates=<uint>` | direct mapping |
| `hole.confidence` | `conf_floor=<uint>` | confidence floor for selection |
| `hole.selected_candidate` | `selected=<id\|none>` | direct mapping |
| `hole.evidence` | `provenance=<uint>` | provenance count as a proxy for evidence depth |
| `hole.invariant_check` | no direct field | encode as a note or sub-entry; do not add to Yata core |

Example Yata `.plan` entry for a contract hole:

```text
- H-C001-001/F001 loci/chatgpt/ROOT_LINEAGE.md converging ready=true candidates=1 conf_floor=85 selected=root-lineage-wording provenance=2
```

The hole_id and fill_id are combined in the entry label. The anchor is the artifact the fill references.

## Evidence

The chatgpt.plan already uses this shape. The chatgpt-contracts.plan uses a similar shape. The mapping is already latent in existing practice.

## Invariant check

| Invariant | Result |
|---|---|
| maps to Yata without mutating core | pass — uses existing fields only |
| does not overload state | pass — `blocked` stays local, not pushed to Yata core |
| one .plan example can represent the contract | pass — example above is complete |

## Confidence

82

## Notes

`invariant_check` has no direct Yata field. Options:
1. Encode pass/fail inline in the entry note (acceptable at v0)
2. Add a separate `invariants=<csv>` field to the entry (local extension, not Yata core)
3. Emit a companion `.plan` file for the arblock with one entry per invariant

Option 1 is simplest at v0. Revisit when the parser supports richer entry metadata.
