# Solver Offload Typed Hole Contracts — ChatGPT Arblock

Profile identity: `loci.chatgpt.solver_offload_typed_hole_contracts.v0`

Status: bootstrap contract surface

Upstream proposal anchor: `../koan/docs/spec.md` (Solver Offload Service Mini-Spec)

## Core stance

Use solver-offload as an oracle surface for proof obligations, not as a replacement for local contract semantics.

```text
@contract + @pattern
  -> MoonBit where { proof_require/proof_ensure }
  -> optional solver job envelope
  -> solver receipt
  -> seal gate (@ready=true)
```

## Typed hole

```text
hole_id: H("solver-offload-receipt-binding" ++ "loci/chatgpt" ++ "v0.2")
anchor: loci/chatgpt/SOLVER_OFFLOAD_TYPED_HOLE_CONTRACTS.md
state: converging
expected_type: solver oracle receipt binding contract
```

Invariants:

- Contract obligations remain explicit in MoonBit (`where { ... }`).
- Solver execution is modeled as external evidence that discharges obligations.
- `@ready=true` requires local contract seal conditions and verified solver receipt when solver offload is requested.
- Solver receipt must capture solver identity, job id, status, and artifact/receipt reference.
- Failed/timed out/invalid solver jobs do not satisfy seal gates.

Candidate outputs:

- `LOCI-LINT-MINI-SPEC.md` solver directives
- `chatgpt.mbt` solver receipt + `can_seal_with_solver(...)` methods
- `chatgpt_difficult_test.mbt` solver seal gating tests

Verification:

- No solver-offload path can bypass required proof obligations.
- Completed solver receipt with evidence passes `can_seal_with_solver`.
- Non-completed or incomplete receipt fails `can_seal_with_solver`.

Move-out target:

```text
loci/chatgpt first, later docs/ near Yata and solver runtime specs
```

Seal condition:

```text
solver receipt binding is represented in mini-spec directives and executable MoonBit contract gates
```
