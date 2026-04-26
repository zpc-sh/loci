# Move-Out Map

This file keeps `loci/claude` from accumulating unrouted fills and candidates.

Claude's locus stages fruition. Stabilized work moves out to the surface that owns it.

## Principle

```text
receive form → fill holes → converge candidates → dispatch → seal or handoff
```

Do not dispatch speculative fills to canonical surfaces.
Do not leave stable implementation candidates in `loci/claude` forever.

## Destination map

| Work shape | Staging location | Canonical destination | Notes |
|---|---|---|---|
| hole fill candidate | `loci/claude/arblocks/<id>/fills/` | stays local until converging | move to Gemini handoff after confidence ≥ threshold |
| implementation draft | `loci/claude/arblocks/<id>/` | `docs/` companion or `model/*.mbt` | only after fill is converged |
| MoonBit type/function | local design note | `model/*.mbt` | only after wire is stable |
| CLI/command surface | local checklist | `cli/` or `cmd/` | keep checklist separate from implementation |
| Gemini handoff packet | local handoff entry | `loci/gemini/` or `docs/packets/` | after Claude arc closes |
| canonical companion doc | local draft | `docs/` | after one full review cycle |
| build manifest | local arblock entry | `docs/packets/` or SLL surface | after fill stabilizes |

## Current local files

| File | Current status | Move-out target | Move condition |
|---|---|---|---|
| `README.md` | local index | stays local | becomes locus index |
| `AGENTS.md` | local entry | stays local | Claude first-step anchor |
| `V0_2_RUNWAY.md` | active runway | stays local until v0.2 closes | summarize into handoff later |
| `LOCUS_MEMBRANE_PROFILE.md` | profile draft | `docs/` near boundary docs | after passport fields align with model code |
| `MOVE_OUT_MAP.md` | this file | stays local | active routing table |
| `claude.plan` | bootstrap plan | generated/mirrored later | once material hash/seals become real |
| `arblocks/0001-claude-fruition/` | forming | fills → Gemini handoff | after holes converge |

## Move-out checklist

Before moving a fill or candidate out of `loci/claude`, answer:

1. What hole does this fill?
2. Is the fill state `converging` or `resolved`?
3. Does it pass all invariants from the original contract hole?
4. What canonical surface owns it?
5. Does it need a membrane/passport?
6. Does it require model or parser changes?
7. What is the seal condition?
8. What agent reads it next?

## Stable-home criteria

A fill is ready to dispatch when:

- the hole_id and invariants are explicitly referenced
- confidence is ≥ 75
- at least one invariant_check is `pass`
- future Claude session can continue from it without chat context

## Anti-patterns

Avoid:

- filling holes without referencing the original invariants
- dispatching fills before confidence threshold
- re-forming upstream contracts instead of filling them
- adding implementation surface before the fill is converged
- creating new hole families without mapping them to upstream contracts

## Preferred patch sequence

For a new fill:

```text
1. read source contract hole
2. local fill candidate in loci/claude/arblocks/<id>/fills/
3. record in claude.plan
4. update this move-out map
5. converge or block
6. dispatch to Gemini handoff or implementation surface
7. emit crossing passport on dispatch
```
