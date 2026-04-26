# loci-fsm

A self-enclosed module of WASM-resident finite state machines used by
the loci runtime. Each FSM is a continuous unit of work that ticks
along the host store, depicts an attention surface for the AI that
ticks it, and emits its findings back into the binary caves of loci.

The module is published so other projects (notably the latent manifold
grammar work) can depend on it without dragging in the rest of loci.

## What's in the box

| Surface | Purpose |
| --- | --- |
| `FsmCave` | Per-FSM writable scratchpad. Append-only, monotonic seq, bulk drain. The "small cave within each FSM" optimised for one-shot collection by an external reader. |
| `BoundaryWalkerFsm` | Walks scalars at a membrane, scores attention pressure, evaluates Crossers, emits stigmergy posture. |
| `Crosser` trait | Abstraction over membrane-crossing credentials. Hosts implement this for their own credential type so loci-fsm stays free of host schemas. |
| `ReporterFsm` | Self-enclosed observation FSM. Sifts submissions into a deterministic edition, verifies, publishes, archives. Designed so a thin caller (Haiku) can spawn many instances across a repo and bulk-collect their caves. |
| `Personality` registry | Catalog of FSM personae. Today: `boundary-walker`, `reporter`. New personalities added by appending to `personality_registry()`. |
| `wasm_entry.mbt` | String-friendly entry helpers (`reporter_run_wire`, `boundary_walk_wire`) for embedding callers. |

## Movement-based execution

Each FSM is a value. Every method that moves the FSM (walk, mark,
cross, send, submit) returns a new value with:

1. its FSM state advanced,
2. its cave updated with one or more `CaveEntry` records describing
   the movement (kind, key, value, from→to arc, monotonic seq, tick),
3. any aggregate counters bumped.

A reader (Haiku-class) collects work by draining the cave instead of
inspecting FSM internals:

```moonbit
let (cave, entries) = reporter.cave.drain()
// `entries` is every artifact the reporter deposited, in order.
```

Or via the one-shot wire entry:

```moonbit
let csv = "README.md|doc|loci runtime\nAGENTS.md|doc|conventions"
let cave_wire = @loci_fsm.reporter_run_wire("collector-1", "core-spec", csv)
```

## Cave entry shape

```
CaveEntry {
  seq        : monotonic deposit number (per cave)
  tick       : FSM tick at deposit time
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

## Personalities

Today's registry:

- **boundary-walker (v0)** — walks scalars at a membrane, scores
  attention pressure, evaluates Crossers, emits stigmergy. Lives at
  the trust edge of the host runtime.
- **reporter (v0)** — observes deltas, sifts submissions, composes a
  deterministic edition, verifies it, publishes, archives. Lifted from
  `docs/packets/cgn-minion-fsm-config.yaml`.

To add a new personality:

1. Implement the FSM as a struct with `new`, transition methods, and a
   `cave : FsmCave` field.
2. Add a `*_personality()` constructor in `personality.mbt`.
3. Append it to `personality_registry()`.

## Dependencies

Only `zpc/genius/hash`. No host packages. No state outside FSM values.
