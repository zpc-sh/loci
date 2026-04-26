# Arblock 0001 — Claude Fruition

Arblock identity: `loci.claude.arblock.0001.fruition`

Status: building

Upstream: `loci.chatgpt.arblock.0001.contracts`

## Purpose

This arblock picks up the open typed holes from the ChatGPT contract arblock and emits fill candidates for each.

It does not re-form the contracts. It does not audit them. It resolves what can be resolved and records what is blocked.

## Inherited holes

```text
H-C001-001  root lineage canonical wording
H-C001-002  root lineage move-out location
H-C002-001  contract field set finalization
H-C002-002  Yata lowering vocabulary mapping
H-C002-003  parser timing decision
H-C003-001  LMR hash algorithm
H-C003-002  OCI artifact type final names
H-C003-003  first stored subject
H-C003-004  Akashic public boundary
```

## Fill set

```text
fills/
├── F001-root-lineage-wording.fill.md
├── F002-root-lineage-move-out.fill.md
├── F003-contract-field-set.fill.md
├── F004-yata-lowering-vocab.fill.md
├── F005-parser-timing.fill.md
├── F006-lmr-hash-algorithm.fill.md
├── F007-oci-artifact-names.fill.md
├── F008-first-stored-subject.fill.md
└── F009-akashic-public-boundary.fill.md
```

## Dogfood rule

Every fill in this arblock must answer:

1. Which hole does this fill?
2. What is the proposed candidate?
3. What evidence supports it?
4. Do the original invariants pass?
5. What is the confidence (0–100)?
6. What is the current state: converging | resolved | blocked?

## Local work cycle

```text
□ → ○ → △ → ∎ → □
```

For this arblock:

- `□ Form`: ChatGPT contract arblock provided the holes.
- `○ Fruition`: This arblock fills them.  ← **here**
- `△ Aperture`: Gemini reviews fill coherence and contradictions.
- `∎ Seal`: material hashes and proof refs anchor the result.

## Current seal status

Not sealed. Filling in progress.

## Move-out target

Converged fills → Gemini handoff or companion docs in `docs/`.
Resolved implementation surfaces → `model/` or `cli/`.
