# F008 — First Stored Subject

Fill identity: `loci.claude.arblock.0001.fill.F008`

Fills hole: `H-C003-003` from `loci.chatgpt.contract.loci_mountain_range.v0`

Status: resolved

## Hole restatement

What is the first subject stored in the LMR/Kyozo? Constraints:

- should use a harmless local arblock
- should not include private payloads
- should be reproducible by Codex

Existing candidate: `loci/chatgpt/chatgpt.plan` or the chatgpt contract arblock.

## Candidate

```text
First stored subject: loci/chatgpt/chatgpt.plan
```

Rationale:

1. It is a single file — a minimal leaf, not a complex tree.
2. It has no private payload — it is a public Yata plan in the repo.
3. Codex can reproduce it from the file content alone.
4. It is already named as a candidate in H-C003-003.
5. Using it as the bootstrap subject proves the LMR machinery before scaling to arblocks.

After the first leaf is proven, the second subject should be this arblock itself (`loci.claude.arblock.0001.fruition`), to prove tree construction.

## Evidence

The upstream contract already selected this as `selected_candidate`. This fill ratifies that selection with a step-sequenced argument.

## Invariant check

| Invariant | Result |
|---|---|
| harmless local arblock | pass — chatgpt.plan is a public .plan file, no private data |
| no private payloads | pass |
| reproducible by Codex | pass — file is in the repo |

## Confidence

90

## Implementation note

The first working proof should be:

```text
1. normalize chatgpt.plan content (UTF-8, LF line endings)
2. compute BLAKE3 hash
3. compute SHA-256 hash
4. create leaf artifact: { content_hash_blake3, oci_descriptor_digest, path, size }
5. store leaf in Kyozo
6. compute LMR root over single-leaf tree
7. store root artifact
8. verify inclusion proof from leaf to root
```

This sequence is the LMR bootstrap test.
