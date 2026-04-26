# F006 — LMR Hash Algorithm

Fill identity: `loci.claude.arblock.0001.fill.F006`

Fills hole: `H-C003-001` from `loci.chatgpt.contract.loci_mountain_range.v0`

Status: converging

## Hole restatement

Which hash algorithm for the Loci Mountain Range? Constraints:

- must be deterministic
- must be compatible with OCI digest practices or explicitly bridge them
- should not block Kyozo storage if Loci prefers BLAKE3 and OCI uses SHA-256 descriptors

## Candidate

```text
Internal Loci LMR hashing:  BLAKE3
OCI descriptor digest:       SHA-256 (required by OCI Image Spec)
Bridge strategy:             dual-hash leaf/root record
```

Dual-hash approach:

```text
leaf {
  content_hash_blake3: <hex>
  oci_descriptor_digest: "sha256:<hex>"
}
```

The BLAKE3 hash is the Loci-native commitment. The OCI digest is the transport-layer anchor for Kyozo Store. They coexist on the same artifact record without conflating the two address spaces.

When only one hash is available (e.g., legacy artifact), the missing field is `null` with a provenance note.

## Evidence

- The codebase already uses BLAKE3 for internal hashing (scan module, genius module).
- OCI Image Spec mandates `sha256:` or `sha512:` digest in descriptors.
- Dual-hash is an established pattern (e.g., package managers use internal + registry hashes separately).

## Invariant check

| Invariant | Result |
|---|---|
| deterministic | pass — both BLAKE3 and SHA-256 are deterministic over the same input |
| compatible with OCI digest practices | pass — OCI digest field uses sha256 |
| does not block Kyozo storage on algorithm mismatch | pass — dual-hash coexistence avoids blocking |

## Confidence

78

## Open sub-question

The normalization input for hashing is not specified here. What byte sequence is hashed to produce the leaf hash — raw content, canonical JSON, or a structured envelope?

This sub-question should become a typed hole in the next cycle if not answered upstream.

## Notes

If BLAKE3 is rejected in favor of SHA-256 uniformity, the candidate changes but the dual-hash bridge pattern is still valid. Confidence drops to ~65 for pure SHA-256 (OCI reasons to prefer it exist but conflict with internal fast-hash use).
