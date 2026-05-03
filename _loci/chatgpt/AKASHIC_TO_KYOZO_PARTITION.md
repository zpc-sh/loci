# Akashic → Kyozo Partition

Partition identity: `loci.chatgpt.akashic_to_kyozo.v0`

This document partitions the runway from ChatGPT-locus arblocks to the eventual Akashic Records backed by `zpc-sh/kyozo_store`.

The final point is not a brand-new framework. Kyozo Store is already a content-addressed OCI repository store with manifests, blobs, subjects/referrers, materialized views, and N-Merkle-FSM dimensions. The missing piece is the Loci Mountain Range profile over that store.

## Core claim

```text
Akashic Records = public/replicated witness ledger
Loci Mountain Range = append-only commitment structure over Loci arblocks/arbytes/arbits
Kyozo Store = OCI/CAS substrate that stores the mountain range artifacts
```

Do not build a new storage substrate unless Kyozo fails this role.

## Partition stack

```text
□ ChatGPT / Codex
  local form, contracts, move-out maps, membrane passports
  ↓
Yata / muyata / mulsp / mu
  typed gap, AI profile, inhabitant wrapper, solve/proof refs
  ↓
Arblock
  bounded sealed work unit with material hash and witness/proof refs
  ↓
Loci Mountain Range leaf
  append-only commitment over one arblock/arbyte/arbit subject
  ↓
Loci Mountain Range peak/root
  bagged mountain commitment over accumulated leaves
  ↓
Kyozo OCI artifact
  OCI artifact manifest + CAS layers + subject/referrers lineage
  ↓
Akashic Records
  replicated/federated query and verification surface
```

## Names and roles

| Layer | Role | Owned by |
|---|---|---|
| `arbit` | single witness/proof/seal ref over material | Loci/Yata/mu |
| `arbyte` | quorum summary over related arbits | Loci/Yata/mu, stored in Kyozo |
| `arblock` | bounded sealed work unit | Loci/muyata/mulsp |
| `lmr_leaf` | append event committing an arblock/arbyte/arbit | Loci Mountain Range |
| `lmr_peak` | current complete subtree peak | Loci Mountain Range |
| `lmr_root` | bagged root over peaks | Loci Mountain Range |
| `akashic_record` | public/replicated verification record | Kyozo-backed service later |

## Phase partition

### Phase 0 — Local form

Home: `loci/chatgpt`

Outputs:

- local profiles
- arblock plan profile
- membrane profile
- move-out map
- bootstrap `.plan`

Seal status: mostly draft or pending.

### Phase 1 — Loci sealed arblocks

Home: `loci/*`, `docs/`, `model/`, `cmd/`

Outputs:

- arblock `.plan` files
- material hashes
- witness/proof/result refs
- membrane/passport entries for cross-locus movement
- selected Yata candidates and provenance

Goal:

- make each significant work unit sealable without involving Kyozo yet.

### Phase 2 — Loci Mountain Range profile

Home: `docs/` in Loci first, then Kyozo specification mirror.

Outputs:

- LMR leaf schema
- LMR peak/root schema
- OCI artifact type mapping
- repository/tag conventions
- proof/referrer conventions

Goal:

- define the mountain range as a portable artifact profile, not a service.

### Phase 3 — Kyozo OCI storage

Home: `zpc-sh/kyozo_store`

Outputs:

- OCI artifact manifests for LMR leaves, peaks, epochs, and roots
- layers for compact `.plan`, proof, and optional payload refs
- annotations for discoverability
- `subject`/referrers lineage for append and supersession

Goal:

- store all mountain range material using existing OCI/CAS patterns.

### Phase 4 — Akashic query surface

Home: Kyozo Store API / future public service

Outputs:

- `verify(hash)`
- `proof(hash)`
- `root()`
- `root_at(epoch|leaf_index|timestamp)`
- `referrers(subject)`
- arbyte quorum query

Goal:

- make verification easy without exposing private payloads.

### Phase 5 — Federation / public ground

Home: replicated Kyozo registries, mirrors, or public-good service.

Outputs:

- replicated root manifests
- periodic external timestamps if needed
- exported proof bundles
- read-only public verification mirrors

Goal:

- Akashic Records become public, cloneable, and verifiable.

## What not to build yet

Do not start with:

- Phoenix/Ash Akashic app
- blockchain anchoring
- new database schema
- new permission system
- full public API
- custom binary format

Start with:

- OCI artifact types
- manifest shape
- annotations
- subject/referrers lineage
- proof bundle as blob/layer
- local arblock material hashes

## Boundary rule

Movement from Loci into Kyozo is a membrane crossing.

Each crossing should bind:

- source locus
- target store/repository
- artifact ref
- material hash
- intent: `anchor | append | supersede | prove | mirror`
- boundary mode
- seal/proof refs when present

## Minimal viable Akashic unit

The minimum useful record is:

```text
one arblock material hash
+ one LMR leaf manifest
+ one Kyozo OCI digest
+ one current LMR root manifest
```

This proves:

- this bounded work unit existed in this material form
- it was appended into the Loci Mountain Range
- the range root at append time committed to it
- Kyozo can retrieve and verify the artifacts by digest

It does not prove truth. It proves witnessed commitment.

## Success condition

The partition is complete when a future agent can answer:

```text
Given an arblock hash, where is it in the Loci Mountain Range?
Which Kyozo OCI manifest stores it?
What root committed to it?
What proof path verifies inclusion?
What later records supersede or refer to it?
```

without needing chat context.
