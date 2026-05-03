# Cohesive Contract Index
Generated isomorphic views from capsule + FST canonical sources.
## Sources
- `wit/capsule/capsule.wit`
- `loci_fsm/personality.mbt`

![capsule-version](badges/capsule-version.svg) ![fst-network](badges/fst-network.svg) ![fst-personalities](badges/fst-personalities.svg)
## Capsule Snapshot
- Package: `zpc:capsule@0.1.0`
- Types: `27` records, `15` enums, `6` variants
- Capsule functions: `39`
- FST operations: `transducer-begin, transducer-feed, transducer-compose, swarm-metabolize, swarm-reap, fst-default-assurance-policy, fst-verify-assurance-claim`
## FST Assurance Posture
- `network_direct_allowed=false`
- Allowed host surfaces: `file-surface, socket-surface, store-surface, clock-surface, log-surface`
- Assurance hooks: `fst-default-assurance-policy, fst-verify-assurance-claim`
## FST Personality Set
- `boundary-walker@v0`: Membrane-side FSM: walks scalars for ghost/bidi/control bytes, evaluates Crosser credentials, emits stigmergy posture into its cave.
- `reporter@v0`: Observation FSM: sifts submissions into a deterministic edition, verifies, publishes, archives. Self-enclosed — no host I/O.
- `union@v0`: Parallel union transducer: feeds input to both children, merges output tapes. The swarm primitive.
- `subtract@v0`: Filter transducer: primary outputs minus filter-matching outputs. The fencing primitive.
- `diff@v0`: Symmetric difference transducer: emits outputs unique to each side. The delta detection primitive.
- `compose@v0`: Sequential composition transducer: inner output feeds outer input through a bridge function. Classic FST composition T₁ ∘ T₂.
## Isomorphic Artifacts
- `docs/contracts/capsule_contract.json`
- `docs/contracts/fst_personalities.json`
- `docs/contracts/CONTRACT_PRESENTATION.md`
- `docs/contracts/isomorphic_cards.html`
- `docs/contracts/badges/*.svg`
