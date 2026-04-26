# F007 — OCI Artifact Type Final Names

Fill identity: `loci.claude.arblock.0001.fill.F007`

Fills hole: `H-C003-002` from `loci.chatgpt.contract.loci_mountain_range.v0`

Status: converging

## Hole restatement

What are the final OCI artifact type names? Constraints:

- must be flat and namespaced
- must align with Kyozo OCI artifact conventions
- must distinguish: leaf, peak, root, proof, arblock, arbyte, arbit

## Candidate

Namespace: `application/vnd.loci.`

```text
application/vnd.loci.leaf.v1+json       — leaf node (content hash + metadata)
application/vnd.loci.peak.v1+json       — intermediate tree node
application/vnd.loci.root.v1+json       — root node (mountain range root)
application/vnd.loci.proof.v1+json      — inclusion/exclusion proof
application/vnd.loci.arblock.v1+json    — bounded work bundle
application/vnd.loci.arbyte.v1+json     — quorum summary over arbits
application/vnd.loci.arbit.v1+json      — single witness/proof/seal reference
```

OCI artifact type field (in manifest `config.mediaType`):

```text
application/vnd.loci.<type>.v1+json
```

OCI layer MIME types follow the same namespace for structured layers.

## Evidence

- OCI artifact naming conventions use `application/vnd.<vendor>.<type>.v<version>+json`.
- The `+json` suffix signals JSON-encoded config.
- Flat namespacing avoids deep hierarchy that complicates OCI tooling.
- All seven terms (leaf, peak, root, proof, arblock, arbyte, arbit) appear in the chatgpt contracts.

## Invariant check

| Invariant | Result |
|---|---|
| flat and namespaced | pass — single depth under `application/vnd.loci.` |
| aligns with Kyozo OCI artifact conventions | partial — Kyozo conventions not yet confirmed; bridge likely needed |
| distinguishes all seven types | pass |

## Confidence

72

## Open question

Are these the right granular types or should `leaf`, `peak`, `root` be unified under a single `application/vnd.loci.node.v1+json` with a `node_kind` field? Unification simplifies OCI manifest counts; separation is more discoverable.

This is a design decision that benefits from Gemini aperture before locking.
