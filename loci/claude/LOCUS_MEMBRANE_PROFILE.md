# Claude Locus Membrane Profile

Profile identity: `loci.claude.locus_membrane.v0`

This profile describes the membrane between the Claude locus and other loci and surfaces.

It mirrors the shape of `loci/chatgpt/LOCUS_MEMBRANE_PROFILE.md` but with Claude-specific postures.

## Definition

Same definition as parent:

```text
membrane = representation boundary + authority boundary + replay boundary
```

A crossing occurs when work moves from one locus into another, or from the Claude locus outward to canonical surfaces.

## Upstream sources

The Claude locus receives material primarily from:

- `loci/chatgpt` — contracts, typed holes, form artifacts
- Human session input — new constraints, corrections, direction changes

## Downstream targets

Material leaving the Claude locus goes to:

| Destination | What moves there |
|---|---|
| `loci/gemini` | fill candidates and implementation drafts for aperture review |
| `docs/` | stabilized companion docs for canonical specs |
| `model/` | MoonBit type signatures and implementations |
| `cli/` or `cmd/` | operational command surface |
| `docs/packets/` | portable handoff packets |

## Boundary modes

Inherit from chatgpt membrane profile:

```text
observe     = detect/report only
sanitize    = normalize known-safe problems and continue
strict      = reject non-clean trusted material
quarantine  = accept only into isolated lane
```

Claude locus defaults:

| Crossing | Default mode |
|---|---|
| chatgpt fills → local arblock | `observe` |
| local arblock → docs/ companion | `observe` |
| local arblock → model/ | `sanitize` |
| local arblock → gemini aperture | `observe` |
| canonical spec changes | `strict` |
| adversarial or hostile material | `quarantine` |

## Claude Locus Crossing Passport

Same passport shape as chatgpt, with Claude-specific defaults:

```text
kind: loci.crossing.passport
version: v0
passport_id: <stable id>
who:
  overlay: claude
  family: anthropic.claude
  session_surface: <claude-code|api|chat>
what:
  artifact_ref: <path/hash/store ref>
  artifact_type: <fill|candidate|implementation|handoff|residue>
why:
  intent: <fill|implement|handoff|audit|seal|dispatch>
  note: <compact note>
where:
  source_locus: loci/claude
  target_locus: <target>
how_far:
  boundary_mode: <observe|sanitize|strict|quarantine>
  allowed_surfaces: <surface list>
  budget_class: <tiny|normal|large>
trace:
  context_ref: <conversation/doc/plan ref>
  lineage_ref: <parent contract hole ref>
seal:
  request_seal: <optional>
  material_hash: <optional>
  provenance_seal: <optional>
```

## Membrane decision table

Inherited from chatgpt membrane profile, plus:

| Input posture | Boundary result | Action |
|---|---|---|
| fill candidate + open hole ref | admitted | record in arblock |
| fill candidate + no hole ref | admitted with warning | note orphan, stage only |
| implementation draft + stable fill | admitted | dispatch to model/docs |
| implementation draft + open fill | hold | do not dispatch until fill converges |
| re-form of upstream contract | denied | aperture entry only |

## Relationship to arblock

Claude arblock entries may carry crossing passports as refs.

Recommended entry families:

```text
fill/<hole_id>/<candidate_id>
implementation/<surface>/<id>
handoff/<target>/<id>
residue/<id>
block/<hole_id>
```

## Non-goals

- do not turn this into a review system for Claude's own outputs
- do not block exploratory fills within `loci/claude`
- do not require passports for internal arblock notes
- do not inline confidence scores into passports (keep them in fill entries)
