# Semantic Router Contract v0.1 (stub)

Contract identity: `merkin.semantic.router.contract.v0`

## Status

**Stub only.** This spec pins the shape of decision inputs and the
action enum for the next arc's semantic firewall. Policy logic
lives in the next arc; this arc emits replayable decision artifacts
but does not decide anything.

## Purpose

Every crossing attempt (passport) is evaluated by the semantic
router before target execution. The router is the only place that
can narrow / sandbox / quarantine / deny — it is never bypassed.
This arc ensures every decision is a **replayable artifact**: given
the same inputs, the same decision can be reproduced (audit-safe).

## Inputs

```
RouterInputs {
  passport          : merkin.locus.crossing.passport.v0.1
  target_profile    : target locus policy profile (opaque ref)
  boundary_findings : summary from boundary walker FSM
  capability_ticket : capability class + budget state
  resonance_signature : active AMF signature (optional)
}
```

`resonance_signature` is documented as an input from day one: per
prior art §7 (dual-use identity), a rule evaluated under different
resonance states produces different processing characteristics. The
router is thus resonance-aware by construction.

## Action enum

- `RouteAllow` — crossing permitted as declared
- `RouteNarrow(reduced_surfaces, reduced_capability)` — reduce
  surfaces or capability and continue
- `RouteSandbox(lane)` — redirect to a constrained execution lane
- `RouteQuarantine(reason)` — hold for review
- `RouteDeny(reason)` — reject crossing

## Invariants

1. Decisions are replayable: the decision artifact + the inputs
   reproduce the same outcome byte-for-byte.
2. Narrowing allowed; **widening forbidden.** A router cannot grant
   more authority than the passport declared.
3. No hidden implicit escalations.
4. Decision envelope includes the resonance signature under which
   the decision was made. Replays without that signature are
   treated as inadmissible.

## Decision artifact shape

```
RouterDecision {
  kind             : "merkin.semantic.router.decision.v0"
  version          : "v0"
  decision_id      : stable identifier
  passport_id      : referenced passport
  passport_seal    : seal of the evaluated passport
  resonance_signature : active AMF signature (or none)
  action           : RouterAction
  reason           : short human-readable reason
  decision_seal    : blake3 over the full envelope
}
```

## Error codes (v0.1)

- `RouterBadKind`
- `RouterBadVersion`
- `RouterMissingField(field)`
- `RouterMissingSeal(field)`

## What this arc ships

- Types for `RouterInputs`, `RouterAction`, `RouterDecision`
- Decision-artifact emitter (shape + seal), no policy logic
- Round-trip tests: construct decision → seal → re-emit → byte-equal
- Resonance-signature carry-through in the decision envelope

## What the next arc ships

- Actual policy evaluation (profile ↔ passport ↔ boundary ↔
  resonance)
- Narrowing-allowed / widening-forbidden enforcement
- Sandbox lane plumbing
- Router-side observability wire

## Implementation anchors

- `model/semantic_router.mbt` — types + decision emitter
- `model/semantic_router_test.mbt` — round-trip tests
