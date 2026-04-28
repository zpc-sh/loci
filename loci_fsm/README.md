# loci-fsm

A self-enclosed module of WASM-resident finite state transducers used by
the loci runtime. Each FST is a continuous unit of work that ticks
along the host store, depicts an attention surface for the AI that
ticks it, and emits its findings back into the binary caves of loci.

The module is published so other projects (notably the latent manifold
grammar work) can depend on it without dragging in the rest of loci.

## What's in the box

| Surface | Purpose |
| --- | --- |
| `Transducer` trait | Core FST contract: `transduce(Self, TransducerInput) → (Self, Array[TransducerOutput])`. Every FST implements this. |
| `TransducerInput` / `TransducerOutput` | Formal input/output alphabets. Inputs: `Scalar`, `SubmitWork`, `Event`, `Tick`, `RawBytes`. Outputs: `CaveDeposit`, `Signal`, `Emission`, `Spawn`, `Reap`. |
| `MetabolicEnvelope` | Lifecycle accounting: birth/death, μ·Ω relational budget, hard cap of 37 idle ticks, reaper integration. |
| `TransducerUnion[A, B]` | Set algebra: T₁ ∪ T₂. Parallel merge of output tapes. The swarm primitive. |
| `TransducerSubtract[A, B]` | Set algebra: T₁ \ T₂. Output filtering/fencing. |
| `TransducerDiff[A, B]` | Set algebra: T₁ Δ T₂. Symmetric difference for delta detection. |
| `TransducerCompose[A, B]` | Classic FST composition: T₁ ∘ T₂ with bridge function. |
| `FsmCave` | Per-FST writable scratchpad. Append-only, monotonic seq, bulk drain. The "small cave within each FST" optimised for one-shot collection by an external reader. |
| `BoundaryWalkerFsm` | Walks scalars at a membrane, scores attention pressure, evaluates Crossers, emits stigmergy posture. Implements `Transducer`. |
| `Crosser` trait | Abstraction over membrane-crossing credentials. Hosts implement this for their own credential type so loci-fsm stays free of host schemas. |
| `ReporterFsm` | Self-enclosed observation FSM. Sifts submissions into a deterministic edition, verifies, publishes, archives. Implements `Transducer`. |
| `Personality` registry | Catalog of FST personae: `boundary-walker`, `reporter`, `union`, `subtract`, `diff`, `compose`. |
| `wasm_entry.mbt` | String-friendly entry helpers (`reporter_run_wire`, `boundary_walk_wire`) for embedding callers. |

## Transducer model

Each FST is a Mealy machine: `(State × Input) → (State' × Output*)`.

```moonbit
let fsm = BoundaryWalkerFsm::new("codex", "ratio://loci/root")
let (next, outputs) = fsm.transduce(Scalar("branch", "main"))
// next: state advanced to Walking
// outputs: Array[CaveDeposit(entry)]
```

### Metabolic model

FSTs only advance when ticked by an observer. Between ticks they are
frozen, serializable values living inside the Merkle tree. The metabolic
yield per tick is:

```
R(t) = μ(FST_i) · Ω(A_host)
```

Where μ is the base output budget and Ω is the observer's compute
potential. Higher-intelligence observers fuel more transducer output
per tick. Each FST carries a `MetabolicEnvelope` with a hard lifetime
cap of **37 idle ticks** — after which the Reaper tombstones it.

### Set algebra (mirroring loci composition)

FSTs support the same algebraic operations as loci nodes:

```moonbit
// Union: parallel attention, merged outputs
let union = TransducerUnion::new(walker_a, walker_b, 0U)

// Subtract: fence out outputs matching a filter
let fenced = TransducerSubtract::new(primary, filter, 0U)

// Diff: detect what changed between two transducers
let delta = TransducerDiff::new(left, right, 0U)

// Compose: pipe inner outputs through bridge to outer
let pipeline = TransducerCompose::new(scanner, reporter, bridge, 0U)
```

Each composed form is itself a `Transducer`, so compositions compose
recursively — the blob intelligence amasses through algebraic combination.

## Movement-based execution

Each FST is a value. Every method that moves the FST (walk, mark,
cross, send, submit, transduce) returns a new value with:

1. its FST state advanced,
2. its cave updated with one or more `CaveEntry` records describing
   the movement (kind, key, value, from→to arc, monotonic seq, tick),
3. any aggregate counters bumped.

A reader (Haiku-class) collects work by draining the cave instead of
inspecting FST internals:

```moonbit
let (cave, entries) = reporter.cave.drain()
// `entries` is every artifact the reporter deposited, in order.
```

Or via the transducer interface:

```moonbit
let (next, outputs) = transduce_batch(fsm, inputs)
// `outputs` is every TransducerOutput emitted across all inputs.
```

## Cave entry shape

```
CaveEntry {
  seq        : monotonic deposit number (per cave)
  tick       : FST tick at deposit time
  from_state : state before the arc
  to_state   : state after the arc
  kind       : classifier (e.g. "submission", "finding", "publish")
  key        : caller-supplied key (e.g. file path, field name)
  value      : payload
  hash       : blake3 of value (for dedup across many caves)
}
```

`cave.material_hash()` fingerprints the whole cave; identical caves
produce identical hashes for replay verification.

## WIT compliance

The FST types are reflected in `wit/capsule/capsule.wit` under the
`types` interface:

- `transducer-input` variant
- `transducer-output` variant
- `metabolic-envelope` record
- `transduce-result` record
- `fst-algebra` enum (union, subtract, diff, compose)

And in the `capsule` interface:

- `transducer-begin`, `transducer-feed`, `transducer-compose`
- `swarm-metabolize`, `swarm-reap`

## Personalities

Today's registry:

- **boundary-walker (v0)** — walks scalars at a membrane, scores
  attention pressure, evaluates Crossers, emits stigmergy.
- **reporter (v0)** — observes deltas, sifts submissions, composes a
  deterministic edition, verifies, publishes, archives.
- **union (v0)** — parallel merge of two transducers.
- **subtract (v0)** — output filtering/fencing.
- **diff (v0)** — symmetric difference / delta detection.
- **compose (v0)** — sequential FST composition T₁ ∘ T₂.

To add a new personality:

1. Implement the FST as a struct with `transduce` and a
   `cave : FsmCave` field.
2. Implement the `Transducer` trait.
3. Add a `*_personality()` constructor in `personality.mbt`.
4. Append it to `personality_registry()`.

## Dependencies

Only `zpc/genius/hash`. No host packages. No state outside FST values.
