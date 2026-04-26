# F003 — Contract Field Set

Fill identity: `loci.claude.arblock.0001.fill.F003`

Fills hole: `H-C002-001` from `loci.chatgpt.contract.typed_hole_contract.v0`

Status: converging

## Hole restatement

Finalize the minimum field set for a ChatGPT-emitted contract. Constraints:

- small enough for Codex to use immediately
- typed holes as first-class sections
- no canonical parser changes at v0
- should lower into Yata `.plan` entries later

## Candidate

Minimum required fields for a v0 contract:

```text
contract_identity   — unique stable ID for this contract
status              — draft | forming | converging | resolved | sealed | superseded
purpose             — one-paragraph statement of intent
claim               — the core assertion (not truth, just the frame)
root_layer_touched  — which of N-Merkle-FSM / Merkin / Loci this touches
typed_holes         — one or more H-* holes with: expected_type, state, invariants, candidate_count, verification
lowering_path       — where this lowers into the substrate
membrane_crossing   — source/target locus, boundary mode, intent
seal_condition      — what counts as done
notes               — anything that would confuse a future reader
```

Recommended optional fields:

```text
parents             — contract IDs this supersedes
aperture_refs       — Gemini/audit entries that reviewed this
fill_refs           — Claude fill entries that resolved holes here
```

## Evidence

The three existing contracts (C001, C002, C003) already follow this shape. The field set is a ratification of observed practice. No new fields are needed at v0.

## Invariant check

| Invariant | Result |
|---|---|
| small enough for Codex to use immediately | pass — 9 required fields, all names are self-describing |
| typed holes as first-class sections | pass — `typed_holes` is a required section |
| no canonical parser changes at v0 | pass — all fields are `.md` prose, not strict grammar |
| lowers into Yata .plan entries later | pass — field names map to Yata vocabulary (state, candidates, provenance) |

## Confidence

88

## Notes

The optional `parents`, `aperture_refs`, and `fill_refs` fields are for cross-linking. They are not required at v0 but should be used whenever available to keep the arblock traceable.
