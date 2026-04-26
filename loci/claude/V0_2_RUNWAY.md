# Claude Locus v0.2 Runway

Status: active

This file is the Claude-first runway for v0.2 fruition work.

Claude enters after ChatGPT/Codex has produced form. The form layer already exists in `loci/chatgpt`. This runway defines how Claude consumes that form and produces the next layer.

## Prime ordering

```text
1. ChatGPT / Codex  = form, contract, blueprint, bounded work surface
2. Claude           = continuity, expansion, implementation, chain-building  ← you are here
3. Gemini           = aperture, observation, multi-perspective audit
4. Seal             = proof, witness, crystallization, replay anchor
```

## Why Claude is second

Claude-shaped work needs form before it can build. The ChatGPT locus produces the contracts and typed holes. Claude resolves them.

Without upstream form, Claude expansion drifts. With it, Claude can carry forward precisely and handoff cleanly to Gemini.

## v0.2 goal for this locus

Work through the open typed holes in `loci/chatgpt/arblocks/0001-chatgpt-contracts/contracts/`:

| Hole | Contract | Status |
|---|---|---|
| H-C001-001 | root lineage wording | open |
| H-C001-002 | root lineage move-out location | open |
| H-C002-001 | contract field set | open |
| H-C002-002 | Yata lowering vocabulary | open |
| H-C002-003 | parser timing | open |
| H-C003-001 | LMR hash algorithm | open |
| H-C003-002 | OCI artifact type final names | open |
| H-C003-003 | first stored subject | open (candidate: chatgpt.plan) |
| H-C003-004 | Akashic public boundary | open |

Emit fill candidates for each. Do not pretend a hole is closed without evidence. Record confidence.

## Complexity threshold

When a fill candidate overwhelms the current arc, split it into:

```text
candidate      = proposed resolution with evidence and confidence
residue        = material that did not fit but is worth keeping
handoff        = summary for the next agent (Gemini or next Claude session)
block          = explicit statement that a hole cannot be resolved without external input
```

## Work stages

### 0. Enter

Read the upstream contracts. Classify the open holes. Do not start filling until you know which holes exist.

### 1. Fill

For each open hole, emit a fill candidate:

```text
hole_id
candidate_id
summary
evidence
confidence (0–100)
invariant_check (pass/fail/partial for each invariant)
state: converging | resolved | blocked
```

A fill is not a seal. A fill is a candidate awaiting aperture and seal.

### 2. Extend

If the fill resolves the hole, build the next surface:

- implementation draft
- model type or function signature
- build manifest
- mulsp chain entry

Work the lowest layer that is ready. Do not build above an unresolved layer.

### 3. Dispatch

When a fill or implementation candidate is stable:

- emit it as an arblock entry
- record it in `claude.plan`
- update `MOVE_OUT_MAP.md` with its destination
- create a membrane crossing record

### 4. Handoff

When this locus has resolved or converged its holes, emit a handoff for Gemini aperture:

```text
what was filled
what was blocked
what is ready for audit
what remains open
```

The handoff is not a summary for humans only. It is a machine-usable aperture entry.

## Anti-re-form rule

Do not re-emit ChatGPT's contracts. Do not rename them. Do not improve their phrasing in place.

If the form needs correction, create an aperture entry and let the cycle close properly.

Claude's job is to build, not to refactor the blueprint while standing on it.

## Immediate v0.2 candidates

1. `arblocks/0001-claude-fruition/` — first arblock picking up chatgpt contract holes
2. `LOCUS_MEMBRANE_PROFILE.md` — Claude locus membrane and passport profile
3. `MOVE_OUT_MAP.md` — move-out map for fills and implementation candidates
