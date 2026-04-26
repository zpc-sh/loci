# F005 — Parser Timing

Fill identity: `loci.claude.arblock.0001.fill.F005`

Fills hole: `H-C002-003` from `loci.chatgpt.contract.typed_hole_contract.v0`

Status: resolved

## Hole restatement

When do parser/model changes happen? Constraints:

- docs/profile first
- parser/model support only after examples stabilize
- no strict parser breakage for existing `.plan`

## Candidate

```text
Stage 0 (now):   .md profiles and .plan compact wire entries using existing fields
Stage 1:         companion doc in docs/ after local profile is stable
Stage 2:         model types in model/*.mbt after companion doc is reviewed
Stage 3:         parser support after model types are tested
Stage 4:         strict parser enforcement only after multiple arblocks prove the shape
```

The move-out map distinguishes profile work (Stage 0–1) from parser work (Stage 3–4). Claude and Codex should not jump stages.

## Evidence

- All three chatgpt contracts follow this implied order already.
- `ARBLOCK_PLAN_PROFILE.md` explicitly states "document-first" and "do not modify the canonical .plan strict parser until the profile stabilizes."
- The chatgpt.plan and chatgpt-contracts.plan files use existing parser-compatible fields only.

## Invariant check

| Invariant | Result |
|---|---|
| docs/profile first | pass |
| parser support only after examples stabilize | pass — Stage 3 requires tested model types |
| no strict parser breakage | pass — existing fields used throughout |

## Confidence

92

## State notes

This hole is `resolved`. The staged sequence above is a direct derivation of existing practice. No new decision is needed; this fill ratifies the approach already in use.
