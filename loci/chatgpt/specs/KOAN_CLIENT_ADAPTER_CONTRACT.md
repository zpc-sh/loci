# Koan Client Adapter Contract

Status: integration boundary for external solver client handoff

Scope: Koan builds solver client; loci/chatgpt consumes returned result payloads.

## Contract shape

Koan client results should map to `SolverClientResult`:

```text
contract_id
solver
solver_job
solver_status
solver_receipt_ref
proof_artifact_ref
```

This shape is intentionally minimal and stable.

## Integration path

1. Koan client executes solve request.
2. Koan client returns `SolverClientResult` payload.
3. Loci adapter maps payload map to `SolverClientResult::from_koan_payload(...)`.
4. Ingest via `SolverResultHandler::ingest_koan_payload(...)` or `SolverResultHandler::ingest_client_result(...)`.
5. Existing seal checks remain unchanged (`ContractBinding::can_seal_with_solver(...)`).

## Required semantics

- `contract_id` must match `ContractBinding.contract_id`.
- `solver_status` must be `Completed` for verification to pass.
- `solver_receipt_ref` is required for verified receipts.
- `proof_artifact_ref` should match the binding proof reference when provided.

## Payload keys

Expected key-value payload entries:

```text
contract_id
solver
solver_job
solver_status
solver_receipt_ref
proof_artifact_ref
```

`contract_id` may be omitted from payload only when explicitly passed as adapter argument.

## Sink choice

- `DropboxOnly`: queue for async consumers.
- `KvOnly`: keyed lookup by `solver_job`.
- `DropboxAndKv`: both.

## Non-goals

- no Koan transport/protocol coupling in this package
- no assumptions about HTTP vs RPC vs queue callback
- no duplication of solve logic in loci/chatgpt
