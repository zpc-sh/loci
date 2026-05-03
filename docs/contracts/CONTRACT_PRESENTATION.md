# Cohesive Capsule + FST Contract Presentation

Generated: 2026-04-28T13:55:02Z

## Slide 1 - Why this contract

- One canonical contract source for capsule + FST runtime semantics
- Emit synchronized views (docs, machine JSON, UI cards, badges)
- Keep assurance posture explicit and replayable

## Slide 2 - Capsule shape

- Package: `zpc:capsule@0.1.0`
- Records: `27`
- Enums: `15`
- Variants: `6`
- Capsule API functions: `39`

## Slide 3 - FST assurance posture

- `network_direct_allowed=false`
- Allowed surfaces: `file-surface, socket-surface, store-surface, clock-surface, log-surface`
- Assurance hooks: `fst-default-assurance-policy, fst-verify-assurance-claim`

## Slide 4 - Personality set

- `boundary-walker@v0`: Membrane-side FSM: walks scalars for ghost/bidi/control bytes, evaluates Crosser credentials, emits stigmergy posture into its cave.
- `reporter@v0`: Observation FSM: sifts submissions into a deterministic edition, verifies, publishes, archives. Self-enclosed — no host I/O.
- `union@v0`: Parallel union transducer: feeds input to both children, merges output tapes. The swarm primitive.
- `subtract@v0`: Filter transducer: primary outputs minus filter-matching outputs. The fencing primitive.
- `diff@v0`: Symmetric difference transducer: emits outputs unique to each side. The delta detection primitive.
- `compose@v0`: Sequential composition transducer: inner output feeds outer input through a bridge function. Classic FST composition T₁ ∘ T₂.

## Slide 5 - Isomorphic outputs

- `capsule_contract.json` (machine)
- `fst_personalities.json` (machine)
- `COHESIVE_CONTRACT_INDEX.md` (docs)
- `isomorphic_cards.html` (UI cards)
- `badges/*.svg` (status surfacing)
