# Locus Membrane Profile

Profile identity: `loci.chatgpt.locus_membrane.v0`

A locus membrane is the boundary between two loci where material changes representation, authority, or cognitive posture.

It is not just a directory edge.

## Definition

```text
membrane = representation boundary + authority boundary + replay boundary
```

A crossing occurs when work moves from one locus into another, or from an external transport into a locus.

Examples:

- `git` transport → Merkin trusted state
- `loci/chatgpt` staging → `docs/` canonical spec
- `loci/chatgpt` staging → `model/` MoonBit implementation
- `loci/chatgpt` form → Claude/Codex implementation work
- Claude expansion → Gemini aperture review
- runtime result → substrate crystal

## Existing anchors

This profile should align with existing boundary work:

- `docs/BOUNDARY_WALKER_FSM_v0.1.md`
- `docs/RATIO_BOUNDARY_SHIM_SPEC_v0.1.md`
- `model/boundary_fsm.mbt`

The Boundary Walker FSM already distinguishes `Crossing` from scalar `Walking`: crossings carry authority material that must be validated, not merely scanned.

## Boundary modes

Use the existing boundary modes where possible:

```text
observe     = detect/report only
sanitize    = normalize known-safe problems and continue
strict      = reject non-clean trusted material
quarantine  = accept only into isolated lane
```

Recommended defaults:

| Crossing | Default mode |
|---|---|
| local staging → local docs | `observe` |
| git/external transport → trusted state | `sanitize` or `strict` |
| incident/adversarial material → any locus | `quarantine` |
| canonical release/spec surface | `strict` |

## Locus Crossing Passport

A crossing should carry a passport-shaped envelope.

Conceptual fields:

```text
kind: loci.crossing.passport
version: v0
passport_id: <stable id>
who:
  overlay: <chatgpt|codex|claude|gemini|human|tool>
  family: <model/runtime family or role family>
  session_surface: <chat|codex|cli|api|local>
what:
  artifact_ref: <path/hash/store ref>
  artifact_type: <profile|contract|plan|model|packet|crystal>
why:
  intent: <stage|canonicalize|implement|audit|seal|supersede>
  note: <compact note>
where:
  source_locus: <locus ref>
  target_locus: <locus ref>
how_far:
  boundary_mode: <observe|sanitize|strict|quarantine>
  allowed_surfaces: <surface list>
  budget_class: <tiny|normal|large>
trace:
  context_ref: <conversation/doc/plan ref>
  lineage_ref: <parent unit/arblock ref>
seal:
  request_seal: <optional>
  material_hash: <optional>
  provenance_seal: <optional>
```

Only the compact passport crosses by default. Deep identity, raw capability tickets, private scratchpad state, and unmasked substrate fingerprints stay behind their native carriers.

## Membrane decision table

| Input posture | Boundary result | Action |
|---|---|---|
| clean + valid passport | admitted | move or reference material |
| clean + missing seal | admitted with warning | stage only; do not canonicalize |
| ghost-byte attention | admitted in sanitize/observe | emit boundary finding |
| bidi/control containment | quarantine or reject | fail closed for trusted surfaces |
| capability mismatch | denied | create aperture/dispute entry |
| target scope wider than source grant | denied or narrowed | require new grant |

## Cross-locus move protocol

1. Create or identify the source artifact.
2. Compute or reference its material hash when available.
3. Create a passport.
4. Run boundary walk/crossing validation.
5. Emit stigmergy or `.plan` posture summary.
6. Move by reference first; copy material only if needed.
7. Canonicalize only after review/seal threshold is met.

## ChatGPT locus use

`loci/chatgpt` should use membranes to prevent staging material from becoming canonical too early.

Default rule:

```text
local profile first
canonical spec later
runtime implementation last
```

## Relationship to arblock

An arblock may contain crossing passports as entries or refs.

Recommended local entry families:

```text
membrane/passport/<id>
membrane/finding/<id>
membrane/decision/<id>
```

## Relationship to SLL

When an SLL/Semanticfile crosses into Mu compilation, the passport should bind the `BuildRequest` and later the `BuildManifest`.

This lets the source blueprint, compile request, emitted WASM, and provenance seal remain one replayable crossing chain.

## Non-goals

- do not turn membranes into a global ACL system
- do not inline secrets into passports
- do not require every local edit to carry a heavy passport
- do not block exploratory staging in `loci/chatgpt`

The membrane is for crossings, not thinking.
