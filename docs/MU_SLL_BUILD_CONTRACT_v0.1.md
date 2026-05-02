# Mu/SLL Build Contract v0.1

Contract identity: `mu.sll.build.contract.v0`

## Purpose

Define the envelope that carries a Semanticfile source from Loci to
Mu for compilation, and the envelope that carries the resulting
build manifest back. Loci owns the envelope shape and sealing rules.
Mu owns compile semantics (lexer, parser, op-graph lowering, WASM
emission).

## Shape

### Input envelope: `BuildRequest`

Fields:

- `request_id` — stable identifier for replay
- `semanticfile` — raw source text (a Loci-canonical Semanticfile,
  see `docs/SLL_REFERENCE_v0.1.md`)
- `target` — `BuildTarget { family, model, mobility, movement }`
- `boundary_mode` — `observe | sanitize | strict | quarantine`
  (from `merkin.locus.crossing.passport.v0.1`)
- `composition_mode` — `layered | sequenced | live` (mirrors
  `ResonanceOp` for compile-time grain when multiple Semanticfiles
  are composed)
- `ratio_loci` — authority marker required for cross-locus build
- `request_seal` — blake3 seal over the canonical serialization

### Output envelope: `BuildManifest`

Fields:

- `request_id` — matches the request
- `adjoin_seal` — the canonical adjoin-contract seal that represents
  the compiled op graph (ties back to Phase 2's normalized wire)
- `wasm_ref` — content-addressed reference to the compiled WASM, or
  `None` if compile did not emit WASM in this mode
- `provenance_seal` — blake3 seal over (request_seal || adjoin_seal
  || wasm_ref) so replays reproduce the full causal chain
- `diagnostics` — an array of `BuildDiagnostic { level, span, message }`
  entries
- `status` — `ok | warning | error`

Both envelopes are content-addressable and travel through the
Loci boundary FSM like any other substrate artifact.

## Validation rules (Loci side)

- `kind` and `version` match contract identity
- `request_id` / `ratio_loci` / `request_seal` non-empty
- `semanticfile` non-empty
- `boundary_mode` is a known mode
- `target.mobility` ∈ [0.0, 1.0]

Loci does not validate the Semanticfile source itself — that is
parse-time work for Mu. Loci only validates envelope shape.

## Error codes (v0.1)

- `SllBadKind`
- `SllBadVersion`
- `SllMissingField(field)`
- `SllEmptySource`
- `SllMobilityOutOfRange`
- `SllMissingSeal(field)`

## Composability

A `BuildRequest` may carry multiple Semanticfiles via a parent
adjoin expression. Example:

```text
ADJOIN semanticfile://alpha UNION semanticfile://beta
    COMPOSITION_MODE layered
```

The canonical adjoin expression is what actually gets sealed;
Semanticfile is a readable textual front-end that compiles to it.

## Out of scope for v0.1

- WASM binary format details (Mu's concern)
- Tena SLL's biological verbs (not in Loci scope)
- Live reactive compile feedback loops (future arc)

## Implementation anchors

- `model/sll_build_contract.mbt` — envelope types + validator
- `model/sll_build_contract_test.mbt` — round-trip tests
- `docs/SLL_REFERENCE_v0.1.md` — Semanticfile surface notes
