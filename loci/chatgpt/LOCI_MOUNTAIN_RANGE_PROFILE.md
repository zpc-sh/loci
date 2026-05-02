# Loci Mountain Range Profile

Profile identity: `loci.mountain_range.v0`

A Loci Mountain Range (LMR) is an append-only commitment structure for sealed Loci work units.

It is the local name for the Akashic-compatible mountain range before it becomes a public Akashic service.

## Definition

```text
Loci Mountain Range = append-only Merkle Mountain Range over Loci material commitments
```

It commits to:

- arbits
- arbytes
- arblocks
- Yata plans
- SLL build manifests
- substrate crystals
- membrane crossing records
- proof/witness bundles

It does not store private content by default. It stores commitments and proof material.

## Design stance

The LMR should be storage-profile-first.

Do not begin with a new service or database. Use Kyozo Store as the OCI/CAS substrate.

Kyozo already has:

- content-addressed blobs
- OCI manifests
- OCI artifact support
- subject/referrers lineage
- tiered storage
- materialized views
- N-Merkle-FSM witness dimension

The LMR defines what gets stored and how it is linked.

## Artifact taxonomy

Recommended OCI artifact types:

```text
application/vnd.zpc.loci.lmr.leaf.v1+json
application/vnd.zpc.loci.lmr.peak.v1+json
application/vnd.zpc.loci.lmr.root.v1+json
application/vnd.zpc.loci.lmr.proof.v1+json
application/vnd.zpc.loci.arblock.v1+json
application/vnd.zpc.loci.arbyte.v1+json
application/vnd.zpc.loci.arbit.v1+json
```

Recommended layer media types:

```text
application/vnd.zpc.loci.plan.v1+text
application/vnd.zpc.loci.proof.v1+json
application/vnd.zpc.loci.passport.v1+json
application/vnd.zpc.loci.seal.v1+json
application/vnd.zpc.loci.payload-ref.v1+json
```

The exact media types may change, but they should remain flat, namespaced, and OCI-compatible.

## Leaf object

A leaf commits one subject into the range.

Conceptual JSON:

```json
{
  "kind": "loci.mountain_range.leaf",
  "version": "v0",
  "range": "loci://zpc-sh/loci/main",
  "leaf_index": 0,
  "subject_type": "arblock",
  "subject_hash": "blake3:...",
  "subject_ref": "oci://registry/repo@sha256:...",
  "source_locus": "loci/chatgpt",
  "semantic_cluster": "chatgpt-v0.2-runway",
  "witness_refs": [],
  "proof_refs": [],
  "parent_leaf": null,
  "created_at_utc": "RFC3339-or-external-anchor",
  "material_hash": "blake3:normalized-leaf-material"
}
```

## Peak object

A peak commits a complete subtree.

Conceptual JSON:

```json
{
  "kind": "loci.mountain_range.peak",
  "version": "v0",
  "range": "loci://zpc-sh/loci/main",
  "height": 3,
  "left_hash": "blake3:...",
  "right_hash": "blake3:...",
  "peak_hash": "blake3:...",
  "leaf_span": [0, 7],
  "material_hash": "blake3:normalized-peak-material"
}
```

## Root object

A root bags the current peaks.

Conceptual JSON:

```json
{
  "kind": "loci.mountain_range.root",
  "version": "v0",
  "range": "loci://zpc-sh/loci/main",
  "root_index": 12,
  "leaf_count": 37,
  "peaks": ["blake3:peak-a", "blake3:peak-b"],
  "root_hash": "blake3:bagged-peaks",
  "previous_root": "blake3:...",
  "created_at_utc": "RFC3339-or-external-anchor",
  "material_hash": "blake3:normalized-root-material"
}
```

## Proof object

A proof lets a verifier prove subject inclusion without fetching private payloads.

Conceptual JSON:

```json
{
  "kind": "loci.mountain_range.proof",
  "version": "v0",
  "range": "loci://zpc-sh/loci/main",
  "subject_hash": "blake3:...",
  "leaf_index": 37,
  "leaf_hash": "blake3:...",
  "siblings": [
    {"side": "left", "hash": "blake3:..."},
    {"side": "right", "hash": "blake3:..."}
  ],
  "peaks": ["blake3:..."],
  "root_hash": "blake3:...",
  "root_ref": "oci://registry/repo@sha256:..."
}
```

## OCI manifest mapping

Each LMR object should be stored as an OCI artifact manifest.

Suggested mapping:

- `artifactType`: one of the LMR media types above
- `config`: compact JSON object or descriptor of the normalized LMR object
- `layers`: optional plan/proof/passport/seal payload refs
- `subject`: previous root, subject arblock, or parent object depending on artifact type
- `annotations`: flat searchable metadata

Recommended annotations:

```text
org.opencontainers.image.created=<rfc3339>
sh.zpc.loci.range=<range-id>
sh.zpc.loci.kind=<leaf|peak|root|proof|arblock|arbyte|arbit>
sh.zpc.loci.leaf_index=<uint>
sh.zpc.loci.root_hash=<hash>
sh.zpc.loci.subject_hash=<hash>
sh.zpc.loci.source_locus=<path-or-locus-id>
sh.zpc.loci.semantic_cluster=<string>
```

## Repository layout

Recommended Kyozo repository paths:

```text
zpc/loci/mountain/<range-id>:root-latest
zpc/loci/mountain/<range-id>:root-<root-index>
zpc/loci/mountain/<range-id>/leaves:<leaf-index>
zpc/loci/mountain/<range-id>/proofs:<subject-hash-short>
zpc/loci/arblocks/<source-locus>:<material-hash-short>
```

Exact registry path can adapt to Kyozo conventions, but root, leaf, proof, and arblock artifacts should be separable.

## Append algorithm

Minimal append flow:

1. Normalize subject material.
2. Compute `subject_hash`.
3. Create or reference subject OCI artifact.
4. Create LMR leaf object.
5. Hash leaf object.
6. Merge peaks by Merkle Mountain Range rules.
7. Create any new peak objects.
8. Create new root object.
9. Store all objects as OCI artifacts.
10. Tag latest root.
11. Emit proof object or make proof derivable.

## Subject/referrers usage

Use OCI `subject` and referrers API for lineage:

- new leaf may have `subject` pointing to the arblock artifact
- new root may have `subject` pointing to previous root
- proof artifact may have `subject` pointing to the leaf or subject arblock
- superseding arblock may have `subject` pointing to prior arblock

This allows replay, rewind, branch, and discoverability without a custom graph database.

## Privacy stance

LMR stores commitments first.

Default public material:

- hashes
- compact refs
- proof paths
- source locus names
- semantic clusters
- timestamps/anchors when available

Default private material:

- raw conversation payloads
- raw APP identity payloads
- capability tickets
- private chain-of-thought
- unmasked substrate fingerprints
- encrypted evidence bodies

Payloads may be stored as encrypted or access-gated blobs, but the range should not require public payload disclosure for verification.

## Relationship to Akashic Records

The Akashic Records are the public/federated face of one or more Loci Mountain Ranges.

```text
LMR = data structure and OCI artifact profile
Kyozo = storage substrate
Akashic = verification/public-good surface
```

## First implementation target

The first target should be document/tooling only:

- generate one arblock artifact from `loci/chatgpt/chatgpt.plan`
- create one LMR leaf object
- create one LMR root object
- store both in Kyozo-compatible OCI shape
- write a proof object

No service required.

## Future service target

Only after artifact shape stabilizes:

```text
GET /api/v1/lmr/:range/root
GET /api/v1/lmr/:range/root/:index
GET /api/v1/lmr/:range/verify/:subject_hash
GET /api/v1/lmr/:range/proof/:subject_hash
GET /api/v1/lmr/:range/referrers/:digest
POST /api/v1/lmr/:range/append
```

Reads should become public where safe. Writes remain gated by summoner/authority/membrane policy.
