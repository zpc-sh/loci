# SLL Reference v0.1 (preserved from Tena)

This document preserves the Semantic Dockerfile (SLL) reference that
originated in the Tena substrate (`tena-substrate` / Rust), prior
to the `tmp/` cleanup in this arc. Tena's SLL predates Loci and is
Mu's build surface. We pull the surface into Loci as a wire
envelope (`mu.sll.build.contract.v0`, see
`docs/MU_SLL_BUILD_CONTRACT_v0.1.md`) and leave compile semantics to
Mu.

The original Tena SLL used biological / species-flavored verbs
(`SPAWN`, `WALK`, `SHADOW`, `DREAM`, `GATE`). For Loci we substitute
the canonical locus-primitive verbs from the adjoin contract:
`ADJOIN`, `CONSUME`, `ATOP`, `SUBTRACT`, `YATA_UNION`. The textual
front-end becomes a readable form of the Phase 2 adjoin expression
grammar. Exactly one sealable truth: the canonical JSON wire.

## Original Tena example (for reference)

```text
SUBSTRATE claude/opus
    MOBILITY 0.7
    MOVEMENT discrete

FROM semantic://foundational/logic AS logic
FROM semantic://cultural/vinh-long AS heritage

ERA "tena-architecture"
    START 2026-02-02
    END ongoing

SPAWN moth AT logic/reasoning
    ENERGY 0.5
    WATCH content_change -> ALERT
    WATCH heat_above(0.8) -> EXCITE

SPAWN sentinel AT boundaries
    WATCH neighbor_arrives(moth) -> SNAPSHOT

WALK witness THROUGH [logic, heritage, substrate]
    ENERGY 0.8
    COLLECT events

TAG research_log WITH ERA "tena-architecture"

SHADOW secrets
    CONTENT @env(API_KEYS)
    REQUIRES heat_pattern(auth_region) AND movement(discrete)
    DECOY @coord(0xfake123)

DREAM maintenance
    MODE cleanse
    TRIGGER heat_above(0.85)

SNAPSHOT AS "pre-deploy"

EXPORT semantic://zpc/tena/observation/v1
    INCLUDE [logic, heritage]
    EXCLUDE [secrets]
```

## Loci-canonical Semanticfile (v0.1)

```text
SUBSTRATE claude/opus
    MOBILITY 0.7
    MOVEMENT discrete

FROM locus://merkin/alpha AS alpha
FROM locus://merkin/beta  AS beta

ADJOIN alpha UNION beta
    META policy_mode=sanitize

CONSUME alpha
    INTO beta
    META boundary_mode=sanitize

YATA_UNION alpha
    WITH merkin.yata.plan#hole-7
    EXPECTED Observation
    MIN_CONFIDENCE 72

EXPORT locus://zpc/merkin/build/v1
    INCLUDE [alpha, beta]
```

Tena's fuzzy-match / typo-tolerant lexer rules are preserved for
AI-friendliness. The compile target is the Phase 2 canonical adjoin
JSON; sealing that JSON is the only source of truth.

## Out of scope for this reference

- The full SLL parser is Mu's responsibility. Loci carries only the
  build-contract envelope: a Semanticfile source string enters and
  a build-manifest envelope exits.
- Biological verbs (`SPAWN`, `WALK`, `SHADOW`, `DREAM`) are not
  re-introduced. They are species-specific to Tena; Loci stays on
  locus primitives.

## See also

- `docs/MU_SLL_BUILD_CONTRACT_v0.1.md` — the Loci↔Mu handoff envelope.
- `docs/packets/LOCUS_ADJOIN_CONTRACT_v0.1.md` — the canonical
  expression grammar the Semanticfile front-end compiles to.
- `model/sll_build_contract.mbt` — the envelope type.
