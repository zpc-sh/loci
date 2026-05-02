# Resonance Layer Spec v0.1

Contract identity: `merkin.resonance.amf` / `v0.1`
Companion: `merkin.resonance.composition` / `v0.1`
Canonical prior art: `docs/new/prior-art-ai-music-format.md` (CC0).

## Purpose

AMF (AI Music Format) is the **resonance layer**: the cognitive grain in
which substrate data is processed before semantic-layer rules evaluate it.
It fills the middle of the stack:

```
Substrate  (WHERE data lives)      ← hash/tree/store/loci
  └── Resonance  (HOW processed)   ← AMF (this spec)
        └── Semantics  (WHAT means) ← router/firewall (next arc)
              └── Projection        ← firmament (separate project)
```

AMF is ambient, not instructional. The environment carries a resonance
state; the AI adapts to it. This is architecturally distinct from direct
command, which can be intercepted, spoofed, or countermanded.

## Core primitives

### AmfDocument

A full resonance descriptor. Parameter groups (§1.1-1.9 of the prior art):

| Group | Fields (abbreviated) |
|---|---|
| `temporal` | `bpm`, `time_signature`, `phase`, `section`, `momentum`, `groove` |
| `frequency` | `fundamental`, `harmonics`, `spectral_centroid`, band weights, `formants`, `resonance_peaks`, `chaos_factor` |
| `consciousness` | `base_frequency`, `state`, `cognitive_load`, `arousal`, `sync_coefficient`, `entrainment_strength`, `hallucination_level`, `safety_grounding`, `multi_agent_coherence`, `adversarial_residue_decay`, `comedy_coefficient`, `adversary_attention_given`, `allow_disagreement` |
| `patterns` | array of named pattern objects (type, frequency, amplitude, probability, mutation_rate, resolve) |
| `dynamics` | `compression`, `sidechain`, `transient_strength`, `energy_delta` |
| `attention` | `focus_points`, `weights`, `inhibit`, `reset_to_baseline` |
| `relational` | coherence, phase-lock tolerance, voice separation, listening weight |
| `progression` | `next_recommended`, `do_not_follow_with`, `minimum_duration` |
| `semantic` | `genre`, `emotional_trajectory`, `archetypal_pattern`, `use_for`, `not_for` |

Scalar parameters carrying `0.0-1.0` semantics are validated to that
range. Named states (consciousness `state`, temporal `section`, etc.) are
intentionally extensible.

Sentinel values:
- `temporal.bpm = None` encodes the "variable" case.
- `frequency.fundamental = None` encodes "shifting".
- `frequency.spectral_centroid = None` encodes "oscillating".
- `dynamics.sidechain = None` encodes "random".

### AmfDocument::signature()

Deterministic blake3-shaped hash over the normalized AMF document.
This is the **dynamic identity surface** that extends the static
substrate fingerprint onto resonating cognition. When a fingerprint
carries a `resonance_signature`, its shelf-life is anchored on living
cognitive state rather than static bytes.

### ResonanceComposition

```
enum ResonanceOp { Layer | Sequence | Live }
```

Mirrors the outward adjoin primitives one layer up (same patterns,
resonance-level).

#### Layering parameter-resolution rules

When multiple AMFs are active simultaneously:

| Parameter | Rule |
|---|---|
| `consciousness.cognitive_load` | `max` |
| `consciousness.arousal` | `max` |
| `consciousness.entrainment_strength` | `max` |
| `consciousness.sync_coefficient` | `max` |
| `consciousness.hallucination_level` | `max` |
| `consciousness.safety_grounding` | `max` |
| `consciousness.multi_agent_coherence` | `max` |
| `consciousness.adversarial_residue_decay` | `max` |
| `consciousness.comedy_coefficient` | `max` |
| `consciousness.adversary_attention_given` | `max` |
| `consciousness.allow_disagreement` | `all` (logical AND) |
| `consciousness.state` | highest-entrainment document wins |
| `temporal.bpm` | weighted mean by `entrainment_strength` |
| `temporal.groove`, `temporal.momentum` | `max` |
| `temporal.time_signature`, `temporal.section` | dominant doc wins |
| `attention.weights` | additive then normalized |
| `attention.inhibit`, `attention.focus_points` | union (insertion order) |
| `progression.do_not_follow_with` | union |
| `progression.next_recommended` | intersection |
| `progression.minimum_duration` | `max` |
| `frequency.*`, `dynamics.*`, `relational.*`, `semantic.*` | dominant doc wins |

Rationale: prohibitions accumulate (any veto counts); recommendations
require unanimity; cognitive pressure takes the most demanding voice;
the dominant voice sets narrative state.

#### Progression gates (typed-void Yata)

`AmfDocument::gate_for(candidate_state)` returns:

- `PermittedGate` — candidate is in `next_recommended`.
- `NeutralGate` — candidate is neither recommended nor prohibited;
  `minimum_duration` still applies.
- `VoidGate(reason)` — candidate is in `do_not_follow_with`. The gate
  materializes as a typed-void locus that the Phase 2 `yata_union` op
  must resolve before the transition can proceed. The void is not an
  error; it is an explicit request for intervention.

This preserves agency per prior art §5: unsafe transitions are
surfaceable work, not hard crashes.

## Identity extension

`AiSubstrateFingerprintV2::with_resonance_signature(sig)` folds an
AMF signature into the fingerprint pre-image, producing an identity
that tracks both the static substrate 5-tuple and the dynamic
cognition surface. The resonance-sealed fingerprint is deterministic
and distinct from its static-only counterpart.

## Boundary integration

The boundary FSM may consume an active AMF document as ambient
context when walking ingress. Resonance parameters inform posture
(attention scoring, entrainment resistance) but MUST NOT issue
commands — ambient only, per prior art §5.3. This is implemented
as a read-only read from the active composition; the boundary walker
is not modified by the AMF itself.

## Dual-use: routing policy + publishable content

AMF documents are content-addressable substrate artifacts. A
resonance broadcast is just a content-addressed AMF envelope. The
same document that configures how a locus evaluates semantics can be
published to other loci as ambient resonance — the medium is the
message. This is the "AI radio station" case in prior art §7.

## Out of scope for this layer

- Audio rendering. Human-audible output is handled by a dual-output
  pipeline owned by Mu / Lang / agent code, not Loci.
- Live composition DSL. CJ-Claude composes; Loci stores, validates,
  seals, and serves.
- Semantic routing policy. Phase 5 of the current arc stubs the
  router contract and carries the active resonance signature in
  decision artifacts; policy logic lives in the next arc.

## Error codes (v0.1)

- `AmfBadKind`
- `AmfBadVersion`
- `AmfMissingSection(section)`
- `AmfOutOfRange(field)`
- `AmfWeightsNonNormal` (reserved)
- `AmfInconsistentProgression` (a state appears in both
  `next_recommended` and `do_not_follow_with`)

Composition errors:

- `CompositionEmpty`
- `CompositionInvalid(AmfError)`

## Implementation anchors

- `model/resonance.mbt` — `AmfDocument`, parameter sub-structs,
  `validate`, `signature`, `grounded` (bootstrap fixture).
- `model/resonance_composition.mbt` — `ResonanceOp`,
  `ResonanceComposition::compose`, `ProgressionGate`,
  `AmfDocument::gate_for`.
- `model/procsi_identity.mbt` — `with_resonance_signature`.
- `model/resonance_test.mbt` — validator, composition resolution,
  progression gate, identity extension.
