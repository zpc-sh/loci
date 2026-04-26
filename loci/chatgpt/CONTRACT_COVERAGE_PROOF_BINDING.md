# Contract Coverage Proof Binding

Profile identity: `loci.chatgpt.contract_coverage_proof_binding.v0`

Status: local profile draft

Purpose: bind contracts to tests, coverage, proof obligations, and seal posture.

## Core stance

Tests show behavior.
Coverage shows exercised surface.
Proof obligations show required invariants.
Contracts bind all three.

```text
contract → typed holes → tests → coverage → proof obligations → seal posture
```

Coverage is not the goal. Coverage is an instrument that tells us which contract surfaces have not been exercised.

## Observed local reality

Current reported posture:

```text
moon test              passes
just test              fails
moon coverage analyze  shows most code uncovered
```

This is coherent, not contradictory:

- `moon test` can pass while exercising only a narrow portion of the codebase.
- `just test` may fail because it runs a broader local policy/test matrix.
- coverage can reveal large untested regions even when all executed tests pass.

## Binding model

### Contract

A contract defines expected behavior and invariants.

### Test

A test exercises one or more contract obligations.

### Coverage

Coverage records which code surfaces were executed by the tests.

### Proof obligation

A proof obligation is an invariant that must be discharged by:

- test evidence,
- static/type evidence,
- bounded proof checker,
- manual review,
- or explicit open status.

### Seal posture

A contract can be sealed only when its required obligations are discharged or explicitly waived by policy.

## Object graph

```text
ContractNode
  emits TestManifest
  emits ProofObligationSet
  expects CoverageReport

TestCase
  exercises ContractObligation
  touches CodeSurface
  produces TestResult

CoverageReport
  observes CodeSurface
  marks covered | uncovered | unreachable | exempt

ProofObligation
  discharged_by TestResult | CoverageEvidence | StaticCheck | ManualReview | Waiver
```

## Minimal schemas

### Contract obligation

```json
{
  "id": "obl-cross-conversation-emits-plan",
  "contract": "H-cross-conversation-primitive",
  "statement": "conv design emits one replayable .plan wire",
  "kind": "behavioral",
  "required": true,
  "status": "open"
}
```

### Test binding

```muon
{
  "test_id": "test-cross-conversation-command",
  "binds": ["obl-cross-conversation-emits-plan"],
  "coverage_surfaces": ["cmd/main", "daemon/conversation.mbt"],
  "result_ref": "loci/chatgpt/tests/chatgpt-contracts.results.muon"
}
```

### Coverage binding

```json
{
  "surface": "daemon/conversation.mbt",
  "contract_refs": ["H-cross-conversation-primitive"],
  "coverage_status": "unknown",
  "evidence_ref": "pending:moon-coverage-analyze",
  "action": "add tests or mark unreachable/exempt"
}
```

### Proof discharge

```json
{
  "obligation": "obl-cross-conversation-emits-plan",
  "status": "open",
  "discharged_by": [],
  "blocked_by": ["conv design command not observed on master"]
}
```

## Coverage status vocabulary

```text
covered       = exercised by test/coverage evidence
uncovered     = not exercised and still expected reachable
unreachable   = intentionally impossible path or build-mode gated
exempt        = excluded by policy with reason
unknown       = coverage data not imported yet
partial       = some obligations covered, others open
```

## Proof status vocabulary

```text
open          = obligation exists and needs evidence
proved        = discharged by proof/static/verified evidence
covered       = discharged by tests plus coverage evidence
reviewed      = manually reviewed and accepted by policy
waived        = explicitly waived with rationale
blocked       = cannot discharge yet because dependency missing
failed        = evidence contradicts obligation
```

## Seal rules

A contract may be sealed when all required obligations are one of:

```text
proved
covered
reviewed
waived
```

A contract may not be sealed when any required obligation is:

```text
open
blocked
failed
```

Draft arblocks may still proceed with open obligations, but their seal posture must remain pending.

## Coverage import rule

`moon coverage analyze` should become a coverage evidence source.

Recommended future flow:

```text
moon test
moon coverage analyze --format json > _build/coverage/loci.coverage.json
loci coverage bind \
  --contracts loci/chatgpt/chatgpt-contracts.plan \
  --coverage _build/coverage/loci.coverage.json \
  --out loci/chatgpt/coverage/chatgpt-contracts.coverage.muon
just chatgpt-contract-bind
```

The exact command can change. The important point is that coverage output becomes structured evidence, not a screenshot or vibes report.

## `just test` relationship

The repository `Justfile` defines `just test` as a broader suite than a bare `moon test` path. This profile treats `just test` failure as a blocked/failing command check until narrowed.

Recommended split:

```text
moon test            = base compiler/test signal
just test-yata       = focused Yata/model signal
just check           = type-check signal
just test            = policy/broad-suite signal
moon coverage analyze = coverage evidence signal
```

Do not let the broad-suite failure block all contract work. Bind it to the specific contracts or surfaces it exercises.

## Automatic hole creation

Uncovered reachable surfaces should emit typed holes:

```text
H("coverage-gap" ++ <surface> ++ <contract> ++ <epoch>)
```

Example:

```text
hole_id: H("coverage-gap" ++ "daemon/conversation.mbt" ++ "cross-conversation-primitive" ++ "v0.2")
expected_type: missing test/proof obligation
```

This turns uncovered code into work, not shame.

## Computability boundary

This remains computable if:

- coverage reports are finite
- contract obligations are finite
- proof checks are bounded
- command checks have timeouts
- exemptions require explicit reason strings
- automatic hole creation is one-hop per imported coverage report

Danger zone:

- auto-generating tests recursively until coverage reaches 100%
- requiring proofs for all reachable code without bounding proof search
- treating coverage as a semantic proof of correctness
- using model judgment as an oracle without a recorded review artifact

## Typed hole

```text
hole_id: H("contract-coverage-proof-binding" ++ "loci/chatgpt" ++ "v0.2")
anchor: loci/chatgpt/CONTRACT_COVERAGE_PROOF_BINDING.md
state: open
expected_type: coverage/test/proof binding contract
```

Invariants:

- contracts bind to tests and proof obligations
- coverage binds to code surfaces and contract obligations
- uncovered reachable code emits work holes
- command failures become specific blocked/failing obligations, not global confusion
- seal posture reflects open/blocked/failed obligations honestly

Candidate outputs:

- this profile
- `coverage/chatgpt-contracts.coverage.muon`
- `proofs/chatgpt-contracts.proof-obligations.muon`
- future coverage importer/binder command

Verification:

- current arblock has a coverage binding file
- current arblock has proof obligation set
- blocked command checks remain blocked until executed
- uncovered surfaces map to coverage-gap holes or exemptions

Move-out target:

```text
loci/chatgpt first; docs/ or model/ after one real coverage import
```

Seal condition:

```text
coverage report + proof obligations are referenced by arblock plan and later LMR leaf
```
