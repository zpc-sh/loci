# C003 — Loci Mountain Range Contract

Contract identity: `loci.chatgpt.contract.loci_mountain_range.v0`

Status: draft

## Purpose

Bind the ChatGPT-locus arblock runway to the eventual Akashic Records path through Kyozo Store.

## Claim

The Akashic Records should begin as a Loci Mountain Range profile stored in Kyozo OCI/CAS artifacts.

Do not begin with a new service, database, or blockchain anchor.

## Root layer touched

```text
Merkin / material commitments
Loci / arblocks and membranes
Kyozo Store / OCI storage substrate
Akashic / future verification surface
```

## Typed holes

### H-C003-001 — LMR hash algorithm

- **expected_type**: technical decision
- **state**: open
- **invariants**:
  - must be deterministic
  - must be compatible with OCI digest practices or explicitly bridge them
  - should not block Kyozo storage if Loci prefers BLAKE3 and OCI uses SHA-256 descriptors
- **candidate_count**: 0
- **verification**: leaf/root/proof examples all compute consistently

### H-C003-002 — OCI artifact type final names

- **expected_type**: naming/schema decision
- **state**: open
- **invariants**:
  - must be flat and namespaced
  - must align with Kyozo OCI artifact conventions
  - must distinguish leaf, peak, root, proof, arblock, arbyte, arbit
- **candidate_count**: 1
- **verification**: Kyozo profile and Loci profile use same names

### H-C003-003 — First stored subject

- **expected_type**: bootstrap decision
- **state**: open
- **invariants**:
  - should use a harmless local arblock
  - should not include private payloads
  - should be reproducible by Codex
- **candidate_count**: 1
- **selected_candidate**: `loci/chatgpt/chatgpt.plan` or this arblock
- **verification**: first leaf/root/proof artifact can be generated from it

### H-C003-004 — Akashic public boundary

- **expected_type**: governance/disclosure decision
- **state**: open
- **invariants**:
  - public records should verify inclusion without exposing private content
  - raw conversations and APP identity payloads stay private/gated by default
  - public API should come after artifact shape stabilizes
- **candidate_count**: 0
- **verification**: public/private field split exists in Kyozo profile

## Lowering path

Current local docs:

```text
loci/chatgpt/AKASHIC_TO_KYOZO_PARTITION.md
loci/chatgpt/LOCI_MOUNTAIN_RANGE_PROFILE.md
```

Kyozo storage profile:

```text
zpc-sh/kyozo_store/docs/specification/LOCI_MOUNTAIN_RANGE_OCI_PROFILE.md
```

Future model/tooling:

```text
model/loci_mountain_range.mbt
tools/lmr-append-*.sh or cmd/main lmr commands
```

## Membrane crossing

Crossing from Loci to Kyozo:

```text
source_locus=loci/chatgpt
target_locus=zpc-sh/kyozo_store/docs/specification
intent=anchor-storage-profile
boundary_mode=observe
artifact_type=profile
```

Crossing from local profile to implementation:

```text
intent=implement
boundary_mode=strict
artifact_type=model|tool
```

## Seal condition

This contract is sealed when:

- LMR profile exists in Loci
- Kyozo OCI profile exists
- first subject/arblock is chosen
- first leaf/root/proof example is generated or explicitly queued as a typed hole

## Notes

The mountain range is the bridge from local work units to Akashic verification.

It should remain a data/profile layer before becoming a service.
