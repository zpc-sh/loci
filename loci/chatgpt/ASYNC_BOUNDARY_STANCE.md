# Async Boundary Stance

Status: active

## Position

Yes, we can stay naturally sync in core contract logic.

Async belongs at boundaries:

- solver/offload adapters
- IO and command/process adapters
- networked handoff surfaces
- event ingress/egress

## Core rule

Inside the Codex Nucleant contract core:

- deterministic sync semantics first
- explicit state transitions
- receipts as evidence
- no implicit concurrency requirement

At the edges:

- adapters may be async
- async result is lowered into sync receipt/state objects
- core seal gates consume normalized receipts, not futures/promises

This keeps proofs/contracts stable while still allowing concurrency where it actually exists.
