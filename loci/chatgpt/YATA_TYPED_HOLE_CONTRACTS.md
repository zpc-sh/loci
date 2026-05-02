# Yata Typed Hole Contracts — ChatGPT Arblock

Profile identity: `loci.chatgpt.yata_typed_hole_contracts.v0`

Status: bootstrap contract surface

This file turns the ChatGPT contract arblock into explicit Yata-shaped typed holes.

## Root lineage

```text
N-Merkle-FSM → Merkin → Loci
```

Interpretation:

- **N-Merkle-FSM**: source data structure and executable state lineage
- **Merkin**: semantic store, sparse commitments, Yata holes, replay transport
- **Loci**: cognitive container grammar, membranes, AI-shaped workrooms, composed contract surfaces

Typed holes are paramount because they prevent Loci from becoming free-floating prose.

## Contract hole shape

Each hole should be representable as:

```text
hole_id: H(<name> ++ <anchor> ++ <epoch>)
anchor: <file or locus anchor>
state: open | converging | resolved | sealed | blocked | reopened
expected_type: <contract output type>
invariants:
  - <must remain true>
candidate_outputs:
  - <possible artifact>
verification:
  - <how to know it worked>
move_out_target: <local|docs|model|kyozo|well-known>
seal_condition: <what closes this hole>
```

## Holes

### H1 — Root Lineage

```text
hole_id: H("root-lineage" ++ "loci/chatgpt" ++ "v0.2")
anchor: loci/chatgpt/CHATGPT_CONTRACT_ARBLOCK.md
state: open
expected_type: lineage clarification contract
```

Invariants:

- Preserve `N-Merkle-FSM → Merkin → Loci`.
- Do not collapse the executable tree, semantic store, and cognitive container into one layer.
- Kyozo is storage substrate, not the origin of the lineage.
- The result must stand without chat context.

Candidate outputs:

- `docs/ROOT_LINEAGE.md`
- section in a future canonical Loci architecture document

Verification:

- A future agent can explain the lineage without asking Loc.
- The doc makes clear where Yata typed holes live.

Move-out target:

```text
docs/
```

Seal condition:

```text
final lineage doc has material hash and is referenced by arblock plan
```

### H2 — Typed Hole Primacy

```text
hole_id: H("typed-hole-primacy" ++ "loci/chatgpt" ++ "v0.2")
anchor: loci/chatgpt/YATA_TYPED_HOLE_CONTRACTS.md
state: converging
expected_type: Yata contract profile
```

Invariants:

- Typed Yata holes are the primary unit of contract work.
- Arblocks collect typed holes; they do not replace them.
- Implementations should follow typed holes, not precede them.
- Cross-locus movement should reference holes.

Candidate outputs:

- this file
- companion doc near `docs/YATA_PLAN_SPEC.md`
- future MoonBit model only after profile stabilizes

Verification:

- Each local contract has hole id, expected type, move target, and seal condition.
- `chatgpt-contracts.plan` lists the holes.

Move-out target:

```text
loci/chatgpt first, then docs/ near Yata
```

Seal condition:

```text
all bootstrap contract holes appear in `chatgpt-contracts.plan`
```

### H3 — ChatGPT-First Runway

```text
hole_id: H("chatgpt-first-runway" ++ "loci/chatgpt" ++ "v0.2")
anchor: loci/chatgpt/V0_2_RUNWAY.md
state: converging
expected_type: operating-order contract
```

Invariants:

- ChatGPT/Codex starts first for form, contract, and blueprint.
- Claude expansion passes through locks, membranes, and typed holes.
- Gemini aperture occurs after a bounded object exists.
- Seal closes a cycle and returns the result to form.

Candidate outputs:

- `V0_2_RUNWAY.md`
- updated `AGENTS.md`
- updated `chatgpt.plan`

Verification:

- Codex first-step command is explicit.
- Anti-flood rule exists.

Move-out target:

```text
stays local until v0.2 closes
```

Seal condition:

```text
v0.2 runway is referenced by first LMR leaf or successor arblock
```

### H4 — Locus Membrane

```text
hole_id: H("locus-membrane" ++ "loci/chatgpt" ++ "v0.2")
anchor: loci/chatgpt/LOCUS_MEMBRANE_PROFILE.md
state: converging
expected_type: cross-locus boundary contract
```

Invariants:

- A membrane is a representation, authority, and replay boundary.
- Canonical moves need crossing posture.
- Boundary modes reuse `observe | sanitize | strict | quarantine`.
- The profile aligns with Boundary Walker FSM and Ratio Boundary Shim.

Candidate outputs:

- `LOCUS_MEMBRANE_PROFILE.md`
- future companion doc near boundary specs
- optional model alignment with `Passport` and `BoundaryWalkerFsm::cross`

Verification:

- First canonical move-out has membrane/passport posture.
- No direct session authority crosses as trusted material.

Move-out target:

```text
docs/ near boundary docs
```

Seal condition:

```text
first crossing record exists for a moved canonical doc
```

### H5 — Arblock Plan

```text
hole_id: H("arblock-plan" ++ "loci/chatgpt" ++ "v0.2")
anchor: loci/chatgpt/ARBLOCK_PLAN_PROFILE.md
state: converging
expected_type: Yata/muyata plan profile
```

Invariants:

- Arblock is a bounded sealed work unit.
- Arblock lowers into `.plan`, muyata, mulsp, mu solve refs, and crystals.
- Arbits/arbytes lower to witness/proof/quorum summaries.
- Sealed arblocks are superseded, not mutated.

Candidate outputs:

- `ARBLOCK_PLAN_PROFILE.md`
- `chatgpt-contracts.plan`
- first LMR leaf subject later

Verification:

- Plan entries can represent the arblock without parser changes.
- No independent arblock service appears.

Move-out target:

```text
docs/ near Yata/muyata after stabilization
```

Seal condition:

```text
LMR leaf commits arblock material hash
```

### H6 — Loci Mountain Range

```text
hole_id: H("loci-mountain-range" ++ "loci/chatgpt" ++ "v0.2")
anchor: loci/chatgpt/LOCI_MOUNTAIN_RANGE_PROFILE.md
state: converging
expected_type: OCI-backed commitment range contract
```

Invariants:

- LMR is append-only commitment structure over Loci material commitments.
- Kyozo Store is the storage substrate.
- Akashic Records are the later verification/public-good surface.
- v0 starts with OCI artifacts, not a service.

Candidate outputs:

- `LOCI_MOUNTAIN_RANGE_PROFILE.md`
- `AKASHIC_TO_KYOZO_PARTITION.md`
- Kyozo-side OCI profile
- first LMR leaf/root/proof example

Verification:

- OCI artifact types and manifest mapping exist.
- First arblock can become a leaf subject.

Move-out target:

```text
zpc-sh/kyozo_store/docs/specification/
```

Seal condition:

```text
first LMR leaf/root artifacts generated or represented
```

### H7 — SLL / Dockerfile Parity

```text
hole_id: H("sll-dockerfile-parity" ++ "loci/chatgpt" ++ "v0.2")
anchor: loci/chatgpt/SLL_DOCKERFILE_PARITY.md
state: open
expected_type: blueprint-to-build contract
```

Invariants:

- SLL/Semanticfile is readable blueprint source.
- Dockerfile parity should be 1:1 when emitted.
- Loci owns envelope and sealing rules.
- Mu owns compile semantics.
- BuildRequest and BuildManifest are content-addressable.

Candidate outputs:

- `loci/chatgpt/SLL_DOCKERFILE_PARITY.md`
- companion near `docs/MU_SLL_BUILD_CONTRACT_v0.1.md`

Verification:

- One Semanticfile sketch maps to a Dockerfile-shaped build surface.
- Compile semantics are not smuggled into Loci docs.

Move-out target:

```text
loci/chatgpt first; docs/ after stable
```

Seal condition:

```text
BuildRequest + BuildManifest chain can be referenced by arblock
```

### H8 — Cross Conversation Primitive

```text
hole_id: H("cross-conversation-primitive" ++ "loci/chatgpt" ++ "v0.2")
anchor: loci/chatgpt/CROSS_CONVERSATION_PRIMITIVE.md
state: open
expected_type: daemon conversation primitive contract
```

Invariants:

- ChatGPT and Codex design discussion should pass through `ConversationHost`, not an ad-hoc side channel.
- The primitive emits one replayable `.plan` wire for design handoff and audit.
- The command surface should support `daemon conv design` with `--topic`, `--chatgpt-content`, `--codex-content`, and optional `--design-out`.
- Terminal output must be sanitized and replay-safe.
- The primitive should report whether each side was accepted.

Candidate outputs:

- `loci/chatgpt/CROSS_CONVERSATION_PRIMITIVE.md`
- `daemon/conversation.mbt` additions if needed
- `cmd/main` command plumbing for `daemon conv design`
- tests for accepted/rejected turns and saved plan output

Verification:

- preferred command emits `hall_id`, `thread_id`, and `.plan` wire
- `--design-out` writes a valid `.plan` file
- `design_plan_emitted` and `design_plan_saved` are reported truthfully

Move-out target:

```text
cmd/main + daemon/conversation.mbt for implementation
loci/chatgpt for profile and dogfood docs
```

Seal condition:

```text
first successful `conv design` output becomes an arblock/LMR leaf subject
```

## Resolution policy

A hole is resolved when:

- its output exists,
- its invariants are satisfied,
- its move-out target is known,
- its seal condition is either satisfied or explicitly pending.

A hole is sealed only when its material hash/proof/ref exists.

Do not mark draft profiles as sealed.
