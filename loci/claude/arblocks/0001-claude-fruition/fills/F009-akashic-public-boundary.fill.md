# F009 — Akashic Public Boundary

Fill identity: `loci.claude.arblock.0001.fill.F009`

Fills hole: `H-C003-004` from `loci.chatgpt.contract.loci_mountain_range.v0`

Status: converging

## Hole restatement

Where is the public/private boundary for Akashic Records? Constraints:

- public records should verify inclusion without exposing private content
- raw conversations and APP identity payloads stay private/gated by default
- public API should come after artifact shape stabilizes

## Candidate

Three-zone model:

```text
Zone 1 — Public:    inclusion proofs, root hashes, artifact type, creation timestamp
Zone 2 — Gated:     leaf content hashes, artifact metadata, arblock summaries (requires auth)
Zone 3 — Private:   raw conversation content, APP identity payloads, capability tickets
```

The public API exposes Zone 1 only. A caller can verify that a given artifact was included in the Akashic record without learning what the artifact contains.

Zone 2 is accessible to authenticated callers with the appropriate capability scope. It allows traversal and auditing without exposing raw content.

Zone 3 never leaves the owning locus. It is not in the Kyozo OCI store; it remains in the local session or private substrate.

## Evidence

- This is a standard append-only log with selective disclosure pattern.
- The chatgpt LOCUS_MEMBRANE_PROFILE already establishes that "raw conversations and APP identity payloads stay private/gated by default."
- Merkin envelopes already support this via content_hash (public) vs. content (gated/private).

## Invariant check

| Invariant | Result |
|---|---|
| public records verify inclusion without exposing content | pass — Zone 1 has proofs only |
| raw conversations and APP identity stay private | pass — Zone 3 never leaves the locus |
| public API comes after artifact shape stabilizes | pass — API is a Stage 4 concern (see F005 staging) |

## Confidence

76

## Open question

What authentication mechanism gates Zone 2? Options:

1. Capability ticket from mulsp/ratio authority
2. OCI auth with Kyozo-native identity
3. Simple API key for bootstrap

This is a typed hole for the next cycle. Do not block Zone 1 public API on this decision.

## Notes

The three-zone model is independently implementable. Zone 1 can ship before Zone 2 auth is decided. Keep the API surface minimal at first: one endpoint to verify inclusion, one to fetch root hash.
