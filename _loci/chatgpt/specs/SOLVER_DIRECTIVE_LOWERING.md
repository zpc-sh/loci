# Solver Directive Lowering Sketch

Status: executable sketch for mini-block lowering

Scope: `loci/chatgpt` merge-safe directive lines

## Input surface

```text
@contract
@pattern
@claim
@ready
@oracle
@solver
@solver_job
@solver_status
@solver_receipt
```

## Lowering target

Directive mini blocks are lowered into:

- `ContractDirectiveMini` via `ContractDirectiveMini::from_directive_lines(...)`
- optional `SolverReceipt` from `ContractDirectiveMini::to_solver_receipt(...)`
- contract gate check via `ContractDirectiveMini::ready_gate()`
- final seal gate via `ContractBinding::can_seal_with_solver(...)`
- transport sink via `SolverResultHandler::ingest(...)` or `SolverResultHandler::ingest_http_directive_lines(...)`
- external client sink via `SolverResultHandler::ingest_client_result(...)`
- koan payload-map sink via `SolverResultHandler::ingest_koan_payload(...)`

## Deterministic mapping

```text
@contract      -> ContractDirectiveMini.contract_id
@pattern       -> ContractDirectiveMini.pattern
@claim         -> ContractDirectiveMini.claim
@ready         -> ContractDirectiveMini.ready
@oracle        -> ContractDirectiveMini.oracle
@solver        -> ContractDirectiveMini.solver
@solver_job    -> ContractDirectiveMini.solver_job
@solver_status -> ContractDirectiveMini.solver_status
@solver_receipt-> ContractDirectiveMini.solver_receipt
```

## Gate rules

- if `ready=false`, directive gate passes without solver constraints
- if `ready=true` and no solver requested, directive gate passes
- if `ready=true` and solver requested, require:
  - `solver_status=Completed`
  - `solver_job` present
  - `solver_receipt` present
- final contract seal still requires `ContractBinding::can_seal()==true`

## Sink routes

- `DropboxOnly` : append verified receipt to dropbox queue
- `KvOnly` : upsert verified receipt by `solver_job`
- `DropboxAndKv` : append + upsert

## Notes

- this keeps parser-core unchanged: only macro/prepass lowering is required
- solver evidence is additive and cannot bypass proof/test/coverage obligations
