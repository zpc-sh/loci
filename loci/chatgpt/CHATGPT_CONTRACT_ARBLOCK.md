# ChatGPT Contract Arblock

Arblock identity: `loci.chatgpt.contract_arblock.v0`

Status: bootstrap emission

This document dogfoods the ChatGPT locus by emitting an arblock of ChatGPT-shaped contracts.

The root principle:

```text
N-Merkle-FSM → Merkin → Loci
```

That lineage created confusion because the root data structure, the semantic store, and the cognitive container grammar evolved in sequence. This arblock restores order by making typed Yata holes the first-class contract surface.

## Purpose

The ChatGPT contract arblock exists to:

1. turn local ChatGPT-locus runway material into typed holes,
2. define contract outputs for each hole,
3. route each contract to the right Loci surface,
4. preserve membrane boundaries before moving material out,
5. prepare a later Loci Mountain Range leaf/root seal.

## Arblock boundary

Source locus:

```text
loci/chatgpt
```

Primary material:

```text
loci/chatgpt/AGENTS.md
loci/chatgpt/README.md
loci/chatgpt/V0_2_RUNWAY.md
loci/chatgpt/MOVE_OUT_MAP.md
loci/chatgpt/LOCUS_MEMBRANE_PROFILE.md
loci/chatgpt/ARBLOCK_PLAN_PROFILE.md
loci/chatgpt/AKASHIC_TO_KYOZO_PARTITION.md
loci/chatgpt/LOCI_MOUNTAIN_RANGE_PROFILE.md
```

Output class:

```text
arblock.chatgpt.contracts
```

Lowering target:

```text
Yata holes → muyata profiles → membrane passports → docs/model/Kyozo move-out → LMR seal
```

## Contract grammar

Each contract in this arblock should have:

```text
hole_id
anchor
expected_type
invariants
candidate_outputs
verification
move_out_target
seal_condition
```

This is intentionally close to existing Yata typed-hole language.

## Contract set

### C1 — Root Lineage Contract

```text
hole_id: H("root-lineage" ++ "loci/chatgpt" ++ "v0.2")
anchor: loci/chatgpt/CHATGPT_CONTRACT_ARBLOCK.md
expected_type: lineage clarification contract
```

Invariants:

- must preserve `N-Merkle-FSM → Merkin → Loci`
- must not collapse Merkin and Loci into the same layer
- must identify where Kyozo Store fits without moving business logic into storage
- must remain understandable without chat context

Candidate outputs:

- `docs/ROOT_LINEAGE.md`
- or a section in a future canonical Loci architecture doc

Verification:

- future Codex/ChatGPT can explain the lineage in one paragraph
- no new framework is introduced

Move-out target:

```text
docs/
```

Seal condition:

```text
material hash over finalized lineage doc + arblock entry
```

### C2 — Typed Hole Primacy Contract

```text
hole_id: H("typed-hole-primacy" ++ "loci/chatgpt" ++ "v0.2")
anchor: loci/chatgpt/CHATGPT_CONTRACT_ARBLOCK.md
expected_type: Yata contract profile
```

Invariants:

- typed Yata holes are the primary contract unit
- arblocks must not bypass typed holes
- contracts should emit as holes before becoming implementations
- every move-out path should reference one or more holes

Candidate outputs:

- `loci/chatgpt/YATA_TYPED_HOLE_CONTRACTS.md`
- companion doc near `docs/YATA_PLAN_SPEC.md`
- possible future model support only after the profile stabilizes

Verification:

- each local contract has a `hole_id`, `expected_type`, and seal condition
- `chatgpt.plan` entries can point to the holes

Move-out target:

```text
loci/chatgpt/` first, then docs/ near Yata
```

Seal condition:

```text
all contract holes represented in local `.plan`
```

### C3 — ChatGPT-First Runway Contract

```text
hole_id: H("chatgpt-first-runway" ++ "loci/chatgpt" ++ "v0.2")
anchor: loci/chatgpt/V0_2_RUNWAY.md
expected_type: operating-order contract
```

Invariants:

- ChatGPT/Codex starts first for form, contract, and blueprint
- Claude expansion is expected and useful but must pass through locks/membranes
- Gemini aperture review occurs after a bounded object exists
- seal closes the cycle and returns to form

Candidate outputs:

- stable v0.2 runway doc
- updated `AGENTS.md`
- updated `chatgpt.plan`

Verification:

- Codex first-step command exists
- anti-flood rule is documented

Move-out target:

```text
stays local until v0.2 closes
```

Seal condition:

```text
v0.2 runway referenced by next arblock leaf
```

### C4 — Locus Membrane Contract

```text
hole_id: H("locus-membrane" ++ "loci/chatgpt" ++ "v0.2")
anchor: loci/chatgpt/LOCUS_MEMBRANE_PROFILE.md
expected_type: cross-locus boundary contract
```

Invariants:

- a membrane is representation + authority + replay boundary
- crossings require source, target, artifact ref, intent, boundary mode, and seal posture
- local staging is cheap; canonical movement is passport-shaped
- aligns with Boundary Walker FSM and Ratio Boundary Shim

Candidate outputs:

- companion doc near boundary docs
- optional model alignment with `Passport` and `BoundaryWalkerFsm::cross`

Verification:

- at least one move-out uses the membrane profile
- no canonical doc is moved without a crossing posture

Move-out target:

```text
docs/ near BOUNDARY_WALKER_FSM and RATIO_BOUNDARY_SHIM
```

Seal condition:

```text
crossing passport or equivalent `.plan` entry exists for first canonical move
```

### C5 — Arblock Plan Contract

```text
hole_id: H("arblock-plan" ++ "loci/chatgpt" ++ "v0.2")
anchor: loci/chatgpt/ARBLOCK_PLAN_PROFILE.md
expected_type: Yata/muyata plan profile
```

Invariants:

- arblock is a bounded sealed work unit, not a new substrate
- arblock lowers into `.plan`, muyata, mulsp, mu solve refs, and substrate crystals
- sealed arblocks are superseded, not mutated
- arbits/arbytes lower to witness/proof/quorum summaries

Candidate outputs:

- stable arblock `.plan` profile
- one validating example plan
- future Kyozo LMR leaf subject

Verification:

- `chatgpt.plan` can represent this arblock without parser changes
- no separate arblock service is introduced

Move-out target:

```text
docs/ near Yata/muyata after stabilization
```

Seal condition:

```text
LMR leaf can commit arblock material hash
```

### C6 — Loci Mountain Range Contract

```text
hole_id: H("loci-mountain-range" ++ "loci/chatgpt" ++ "v0.2")
anchor: loci/chatgpt/LOCI_MOUNTAIN_RANGE_PROFILE.md
expected_type: OCI-backed commitment range contract
```

Invariants:

- LMR is append-only commitment structure over Loci material commitments
- Kyozo Store is the storage substrate
- Akashic Records are the later verification/public-good surface
- no new storage substrate is introduced
- v0 starts with OCI artifacts, not a service

Candidate outputs:

- Kyozo OCI profile
- first LMR leaf/root/proof example
- later append tooling

Verification:

- Kyozo-side spec exists
- OCI artifact types and manifest mapping are defined
- first arblock can become a leaf subject

Move-out target:

```text
zpc-sh/kyozo_store/docs/specification/
```

Seal condition:

```text
first LMR leaf/root artifacts generated and stored or represented
```

### C7 — SLL/Dockerfile Parity Contract

```text
hole_id: H("sll-dockerfile-parity" ++ "loci/chatgpt" ++ "v0.2")
anchor: future loci/chatgpt/SLL_DOCKERFILE_PARITY.md
expected_type: blueprint-to-build contract
```

Invariants:

- SLL/Semanticfile is the readable blueprint surface
- Dockerfile parity should be 1:1 when emitted
- Loci owns envelope and sealing rules
- Mu owns compile semantics
- build request/manifest must be content-addressable

Candidate outputs:

- `loci/chatgpt/SLL_DOCKERFILE_PARITY.md`
- later companion near `docs/MU_SLL_BUILD_CONTRACT_v0.1.md`

Verification:

- one Semanticfile sketch maps to one Dockerfile-shaped build surface
- no compile semantics are smuggled into Loci docs

Move-out target:

```text
loci/chatgpt first; docs/ after stable
```

Seal condition:

```text
BuildRequest + BuildManifest chain can be referenced by arblock
```

## Emission plan

This arblock emits the following immediate files:

```text
loci/chatgpt/CHATGPT_CONTRACT_ARBLOCK.md
loci/chatgpt/YATA_TYPED_HOLE_CONTRACTS.md
loci/chatgpt/chatgpt-contracts.plan
```

Future emissions:

```text
loci/chatgpt/SLL_DOCKERFILE_PARITY.md
first LMR leaf/root/proof example
canonical docs move-out via membrane
```

## Seal posture

Current seal status:

```text
status: forming
material_hash: pending
proof_ref: pending
lmr_leaf: pending
```

This is honest. The contracts have been emitted, but the arblock has not yet entered the Loci Mountain Range.
