---
title: "Loci Lint Mini Spec"
subtitle: "FSM-driven crystallization boundaries for sparse Loci trees"
author: "Loc Nguyen + ChatGPT"
status: "seed"
version: "0.1.0"
kind: "loci.chatgpt.spec"
---

# Loci Lint Mini Spec v0.1

```text
Name: Loci Lint
Kind: repository-local semantic linter / kernel walker
Purpose: transmute fenced conversational/code fragments into dense kernel objects,
         project them into CAS, and plant them into a sparse Loci tree.
```

## 1. Core idea

```text
conversation/code = append-only substrate
fence             = crystallization boundary
loci lint         = FSM-driven transmuter
CAS               = durable content address layer
sparse loci tree  = planted semantic topology
```

A fenced block is not merely text. It is a candidate kernel object.

Loci lint scans append-only conversations, documents, and source files; discovers cognitive fences and nucleant headers; canonicalizes them into dense kernel objects; projects raw/canonical/text/receipt objects into CAS; and plants the result into a sparse Loci tree.

This is the code-grain descendant of the self-completing paper pattern: marked gaps, executable completion path, validation, receipts, and later integration.

## 2. Primitive object types

```text
loci     freeform crystallization input; infer object type
nuc      local contract / replaceable work unit
kernel   field-level walker over many nucs
pollen   stigmergic contribution from an agent
receipt  proof of transition or projection
text     prose footer / human explanation
cas      content-addressed reference
```

## 3. Canonical fence types

````markdown
```loci
freeform text to be transmuted
```

```nuc
∴nuc <id>
@ <locus>
? <claim>
~ <allowed-touch-set>
! <oracle>
⇒ <transform>
```

```kernel
∴k <field>
⊃ <owned-locus>
S <fsm>
! <oracle>
⇄ <pollination-policy>
∑ <fold-rule>
.text <optional-text-ref>
```

```pollen
target: <selector>
offer: <projection|patch|test|doc|receipt>
trait: <trait>
```

```receipt
from: <source>
to: <projection>
state: <born|unborn|stale|folded|ghost>
```

```text
human explanation only
```
````

## 4. Dense grammar

### 4.1 Nucleant

```text
∴nuc <id>
@ <locus>
? <claim>
~ <may-touch>
! <must-pass>
⇒ <transform>
# <traits>
.text <cas-ref?>
```

Example:

```text
∴nuc firmament.cache.intent.v0
@ src/firmament/cache.ts:put
? cache.intent.continuity
~ src/firmament/cache.ts test/firmament/cache.test.ts
! test.firmament.cache
⇒ patch
# cache intent unborn
.text cas://b3/...
```

### 4.2 Kernel

```text
∴k <field>
⊃ <locus-pattern>
S <fsm>
! <oracles>
⇄ <pollination-policy>
∑ <fold-rule>
```

Example:

```text
∴k firmament
⊃ src/firmament/**
S discover→classify→project→pollinate→verify→receipt→plant→fold
! no_ghosts
! born(core)
⇄ pollinate(unborn|stale|needs-test)
∑ fold(pass(children))
```

## 5. State model

```text
draft       claim exists, not yet projected
unborn      implementation/projection exists but oracle has not passed
born        oracle passed
ghost       artifact exists without valid nuc/kernel lineage
stale       claim or dependency changed after birth
pollinated  external agent contribution attached
folded      child object summarized into parent
quarantine  malformed or unsafe object
```

## 6. FSM loop

```text
DISCOVER
  scan files, conversations, comments, fences

CLASSIFY
  detect loci/nuc/kernel/pollen/text/receipt/freeform

NORMALIZE
  canonicalize into dense kernel object

PROJECT
  emit CAS objects, sidecars, tests, docs, prompts, receipts

POLLINATE
  attach compatible agent contributions to unresolved objects

VERIFY
  check syntax, boundaries, oracles, receipts

RECEIPT
  append proof of projection / transition

PLANT
  insert object into sparse Loci tree

FOLD
  summarize children into parent kernel state
```

Compact FSM:

```text
discover→classify→normalize→project→pollinate→verify→receipt→plant→fold
```

## 7. Sparse Loci tree

The repository is projected as a sparse semantic tree.

```text
root
├─ field kernels
│  ├─ subsystem kernels
│  │  ├─ nuc leaves
│  │  ├─ pollen objects
│  │  └─ receipts
│  └─ folded summaries
└─ CAS blobs
```

A parent kernel does not need to address every child directly. It may select children by locus, field, trait, state, epoch, or lens.

```text
@locus
@field
@trait
@state
@epoch
@lens
```

Example selectors:

```text
@field:firmament + @state:unborn
@locus:src/cache/** + @trait:needs-test
@field:loci + @state:ghost
```

## 8. CAS projection

Each crystallized block emits, at minimum:

```text
raw_hash       hash of original fenced block
canon_hash     hash of normalized kernel object
text_hash      hash of prose footer, if any
receipt_hash   hash of projection receipt
```

Suggested layout:

```text
.loci/
  objects/
    <hash>.json
  raw/
    <hash>
  text/
    <hash>.md
  receipts/
    <hash>.json
  projections/
    <source>.jsonl
  tree/
    sparse.index.jsonl
```

Receipt shape:

```yaml
kind: receipt.transmute
from: chat://session/turn-12/block-1
raw: cas://b3/raw_hash
canon: cas://b3/canon_hash
text: cas://b3/text_hash
state: born
planted_at: loci://firmament/cache/intent
```

## 9. Lint rules v0

```text
L001 known fence type
L002 raw text preserved
L003 canonical object emitted
L004 receipt emitted for every projection
L005 nuc has locus
L006 nuc has claim
L007 nuc has oracle unless explicitly draft/text/pollen
L008 may-touch boundary exists for patch/replace transforms
L009 kernel has owned locus
L010 no ghost artifacts under strict mode
L011 stale objects detected when source hash changes
L012 folded parent summarizes child states
```

## 10. CLI surface

```bash
loci lint <path>
loci lint <path> --write
loci lint <path> --strict
loci lint <path> --emit cas
loci lint <path> --verify
loci lint <path> --plant
```

Behavior:

```text
default       report only
--write       emit .loci sidecars
--strict      fail on ghost/unborn/malformed objects
--emit cas    write raw/canon/text/receipt blobs
--verify      run safe oracles
--plant       insert canonical objects into sparse Loci tree
```

## 11. Macro / DSL responsibility

The macro layer moves over code and plants kernel headers.

It should:

```text
1. detect candidate functions/classes/modules
2. infer or request claim
3. attach locus
4. attach may-touch boundary
5. attach oracle
6. emit nuc header
7. preserve original code
8. write receipt
9. plant object into sparse tree
```

Example planted code:

```ts
// ∴nuc firmament.cache.intent.v0
// @ src/firmament/cache.ts:put
// ? cache.intent.continuity
// ~ src/firmament/cache.ts test/firmament/cache.test.ts
// ! test.firmament.cache
// ⇒ patch
// # cache intent
export function put(locus: Locus, intent: Intent): Receipt {
  throw new Error("unborn")
}
```

## 12. Kernel invariant

```text
No projection without raw preservation.
No mutation without locus.
No born state without oracle.
No fold without receipt.
No ghost code in strict mode.
```

## 13. First implementation target

Deploy as a repository primitive first:

```text
zpc-sh/loci
  loci/chatgpt/LOCI-LINT-MINI-SPEC.md   this seed spec
  examples/conversation/*.md            append-only conversation substrates
  .loci/                                local CAS + receipts + sparse index
```

The first useful test is self-referential: place a conversation seed in `examples/conversation/`, run `loci lint --write --emit cas --plant`, and verify that the fence that defines Loci lint is itself projected, receipted, and planted.

## 14. One-line definition

```text
Loci lint is an FSM-driven repository primitive that scans append-only text and code for crystallization boundaries, canonicalizes them into dense kernel objects, projects them into CAS, receipts every transition, and plants the result into a sparse Loci tree.
```

∴ ※ ∎
