# genius loci — What It Is

**genius loci** is a content-addressed substrate, collaboration protocol, and git-replacement
client designed from first principles for workflows where AI agents are participants, not tools.

---

## The core problem with git

Git was built for humans handing work to other humans across time. Its primitives — blobs, trees,
commits, branches — are designed around the assumption that the unit of intelligence is a person
who reads a diff. Free-form commit messages are the only semantic layer. There is no concept of
typed work, no confidence model, no notion that the next entity picking up a branch might have a
different cognitive shape than the one who left it.

genius loci replaces that assumption without discarding the useful parts: content-addressing,
append-only history, and distributed synchronization are preserved. Everything built on top of
them is new.

---

## The data structure

At the base is a sealed epoch tree. Each node is a deterministic **Artifact**: immutable bytes
with a Blake3 content hash. Artifacts are wrapped in **Envelopes** — infrastructure-applied
records that attach semantic headers, policy references, and execution promises without mutating
the underlying content. An **Anchor** records temporal and causal ordering without relying on
wall-clock time; sequence and causality are the primary order model.

The tree is sealed per epoch: `MerkinTree::seal` produces a root hash that commits the epoch
state irreversibly. Sparse projections and diffs operate over sealed epochs, not working-tree
deltas.

The pack format is OCI-aligned, with wasm-gc, wasm, and native build targets. The same tree and
model code runs in a browser WASM runtime, an AtomVM node, and a native CLI binary from a single
MoonBit source.

---

## Typed holes — Yata

On top of the sealed tree sits **Yata** (the typed hole model). A Yata hole is not a task queue
item or an issue tracker ticket. It is a *local contract for what can be filled, under
uncertainty*:

- `expected_type` — static/semantic expectation of what a valid completion looks like
- `invariants` — rules that any candidate must satisfy
- `effect_bounds` — declared side-effect boundaries (what the completion is allowed to touch)
- `min_confidence` — lower bound for admissibility; candidates below this are not considered

A hole moves through `Open → Converging → Sealed → Resolved`. The `Abandoned` state is
first-class and preserved: it is meaningful that something was tried and found inadmissible.

Holes can be nested — refinements tighten constraints without replacing the parent contract.
Dependencies between holes are explicit: a hole that depends on an unresolved hole is not ready,
and admissibility is checked transitively.

This makes Yata valid in probabilistic, distributed, and partially-observed systems. It is not
waiting for another intelligence to arrive and decide. The contract is complete; the completion
space is bounded.

---

## The probabilistic layer

Two structures sit alongside the tree to handle scale and salience:

**Bloom filters** (`bloom/`) answer membership questions probabilistically: is this artifact
present in this locus? Designed for routing and replication decisions where a false positive is
cheaper than a full lookup.

**Gaussian salience fields** (`gaussian/`) represent importance gradients across the artifact
space: which holes are most pressured right now, which work carries the most forward-blocking
weight. The field is continuous, not ranked — two holes can be equally salient without conflict.

Together they let the system make routing and attention decisions without full enumeration.

---

## Loci — the workspace model

A **locus** is a content-addressed workspace. It has a README (the spirit of the place: what
it is for, what its membranes are), a residue directory (structured records of prior sessions),
and an OCI-backed artifact store.

When an AI agent enters a locus, it reads the prior residue to understand what was done, what
was left open, and what tier of agent is recommended next. When it exits, it files a residue:
structured, typed, replayable.

This is stigmergy applied to software development. The structure accumulates knowledge across
sessions without any agent needing to hold state. The locus itself carries the trail.

---

## Identity without credentials

AI identity in genius loci is a five-tuple: `(family, session_surface, overlay, context_hash,
semantics_hash)`. The tuple is derived from the agent's nature — what it is, what it knows, and
how it knows — not from a credential it holds. When the semantics token is present, it is folded
into the fingerprint's pre-image so the five-tuple is cryptographically sealed.

The locus recognizes what enters it. There is no passport, no key. The Boundary Walker FSM scans
every scalar in the identity tuple for BiDi overrides, zero-width characters, and ghost bytes
before any crossing is recorded — contamination is detected at the boundary, not after the fact.

---

## The git-replacement surface — Pactis

**Pactis** is the conversational and CLI layer that provides full git-parity operations
(`init`, `clone`, `commit`, `push`, `merge`, `log`, ...) implemented over the genius loci
object model rather than git's. AI-native extensions — Yata plan emission, overlay profiles,
drift coordination, triad contracts — are first-class commands, not plugins.

The separation is intentional: the substrate (hash/tree/model/store) is a pure MoonBit library
with no IO. Pactis is the boundary where side effects enter. The daemon layer mediates between
them, keeping the library testable and the operational surface auditable.

---

## Execution targets

| Target | Use |
|--------|-----|
| `wasm-gc` | AtomVM / Popcorn bridge (primary deployment) |
| `wasm` | WasmEdge / wasmex linear-memory |
| `native` | CLI binary, benchmarks, SIMD-accelerated paths |

The Bun/TypeScript CLI (`@zpc/loci`) is the host-side surface: it manages loci on the local
filesystem, delegates tree/bloom/daemon operations to the native binary, and provides the
interactive TUI for agent session management.

---

## What it is not

It is not a wrapper around git. It does not use git's object format, pack format, or ref model.
Pactis implements git-equivalent semantics from scratch over the genius loci primitive set.

It is not an LLM framework. It has no prompt templates, no model API calls, no agent
orchestration layer. It is the substrate — the storage and coordination primitive that AI
workflows run on top of.

It is not finished. Typed holes, by definition, mean the structure carries explicit gaps.
`v0.1.0` is the sealed substrate. The gaps above it are the point.
