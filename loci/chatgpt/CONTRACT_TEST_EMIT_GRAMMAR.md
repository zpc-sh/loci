# Contract Test Emit Grammar

Profile identity: `loci.chatgpt.contract_test_emit_grammar.v0`

Status: local profile draft

Purpose: define a finite grammar that lets one contract emit docs, specs, proofs, visuals, `.plan`, and tests, then track those tests without creating an unbounded meta-system.

## Core stance

A contract should be able to emit:

```text
docs
specs
proof obligations
visual graphs
yata plans
test manifests
test results
seal material
```

But the grammar must remain finite and bounded.

The safe rule:

```text
contract → finite emissions → bounded tests → tracked result → optional seal
```

Do not allow arbitrary recursive contract expansion during test emission.

## Computability boundary

This is computable while these constraints hold:

- finite node/edge set per contract graph
- finite emitter set
- finite test set per emitter
- deterministic normalization before hashing
- explicit fuel/budget for recursive derivations
- no unrestricted proof search in the default lane
- no emitter may modify the contract graph while emitting from it unless producing a successor graph

Danger zones:

- self-rewriting grammar with no epoch/fuel
- contract emits test that emits contract that emits test indefinitely
- proof obligations delegated to unbounded theorem search without timeout
- visual layout included in semantic hash
- tests whose oracle depends on hidden model judgment
- remote/network tests treated as deterministic consensus tests

## Grammar overview

```text
ContractGraph
  ::= Header Node* Edge* Emission* TestSuite* SealPolicy?

Emission
  ::= EmitDoc | EmitSpec | EmitPlan | EmitGraph | EmitVisual | EmitProofObligation | EmitTestManifest | EmitSealSubject

TestSuite
  ::= TestSuiteHeader TestCase+

TestCase
  ::= ParseTest | SchemaTest | GraphInvariantTest | PlanStrictnessTest | EmitterGoldenTest | ProofCheck | CommandCheck | RoundTripTest

TestResult
  ::= Passed | Failed | Skipped | Blocked | NonDeterministic
```

## ContractGraph additions

A graph may include `emissions` and `tests`.

Conceptual JSON:

```json
{
  "kind": "loci.contract_graph",
  "version": "v0",
  "graph_id": "loci.chatgpt.contract_arblock.v0",
  "nodes": [],
  "edges": [],
  "emissions": [],
  "tests": [],
  "test_runs": [],
  "seal_policy": {}
}
```

## Emission schema

```json
{
  "id": "emit-d3",
  "kind": "EmitVisual",
  "target": "d3",
  "source": "graph-ir",
  "path": "loci/chatgpt/graphs/chatgpt-contracts.d3.json",
  "deterministic": true,
  "semantic_hash_participates": false,
  "tests": ["test-d3-nodes-links"]
}
```

Emission kinds:

```text
EmitDoc
EmitSpec
EmitPlan
EmitGraph
EmitVisual
EmitProofObligation
EmitTestManifest
EmitSealSubject
```

## Test schema

```json
{
  "id": "test-d3-nodes-links",
  "kind": "GraphInvariantTest",
  "target": "loci/chatgpt/graphs/chatgpt-contracts.d3.json",
  "oracle": "d3_nodes_links_shape",
  "deterministic": true,
  "lane": "local",
  "command": null,
  "timeout_ms": 1000
}
```

Test kinds:

```text
ParseTest
SchemaTest
GraphInvariantTest
PlanStrictnessTest
EmitterGoldenTest
ProofCheck
CommandCheck
RoundTripTest
```

## Test result schema

```json
{
  "id": "run-2026-04-25T000000Z-test-d3-nodes-links",
  "test_id": "test-d3-nodes-links",
  "status": "passed",
  "observed_hash": "pending",
  "diagnostic": "nodes and links arrays present",
  "ran_at_utc": "2026-04-25T00:00:00Z"
}
```

Result statuses:

```text
passed
failed
skipped
blocked
non_deterministic
```

## Required invariants

### Graph invariants

- every edge source exists as a node id
- every edge target exists as a node id
- node ids are unique
- edge ids are unique
- graph kind/version are present
- semantic hash excludes renderer state

### D3 invariants

- top-level `nodes` array exists
- top-level `links` array exists
- every link source/target exists in `nodes`
- D3 projection does not contain canonical-only secrets
- optional layout fields are ignored for semantic hash

### Mermaid invariants

- file contains one fenced `mermaid` block
- every referenced hole label maps back to a graph node or plan entry
- projection is allowed to be lossy but not contradictory

### Yata plan invariants

- `kind: merkin.yata.plan` exists
- required headers are present
- entry lines use parser-compatible token order
- `self_report_gap` matches or intentionally summarizes entries
- no fabricated procsi/capability commitments

### Proof obligation invariants

- proof obligations are finite
- obligations have stable ids
- unproven obligations are marked `open`, not `passed`
- external theorem/proof tools are bounded by timeout/fuel

## Existing command lanes

This profile maps to existing repository commands when possible:

```text
just check       = type-check / parser sanity lane
just test        = full test lane
just test-yata   = focused Yata verification lane
just test-wasm   = wasm-gc lane
just test-simd   = native SIMD lane
```

Use command checks as test cases only when the environment supports them.

## Local test manifest path

Recommended local files:

```text
loci/chatgpt/tests/chatgpt-contracts.tests.json
loci/chatgpt/tests/chatgpt-contracts.results.json
```

The manifest declares tests. Results record observed outcomes.

Do not commit fake pass results. If not run, use `blocked` or `skipped`.

## Test tracking rule

Each emitted artifact should have at least one tracking test:

| Artifact | Minimum test |
|---|---|
| `.plan` | `PlanStrictnessTest` |
| graph IR | `GraphInvariantTest` |
| D3 JSON | `GraphInvariantTest` |
| Mermaid | `ParseTest` or `GraphInvariantTest` |
| proof obligations | `ProofCheck` marked open/blocked until discharged |
| command surface | `CommandCheck` |
| LMR leaf/root | `SchemaTest` + proof inclusion check |

## Automatic emission rule

Automatic emission is allowed only when:

- source graph is explicit
- emitter target is declared
- output path is declared
- emitter is deterministic or marked non-deterministic
- tests are declared before or with output
- emitter does not mutate the source graph in place

If an emitter produces new graph structure, it must emit a successor graph:

```text
graph-v0 → emit → graph-v1
```

not mutate `graph-v0`.

## Proofs and computability

Proof emission is safe when it emits obligations, not when it tries to solve arbitrary proofs by default.

Safe default:

```text
contract emits proof obligations
bounded checker discharges simple invariants
hard proofs remain open or offloaded with fuel
```

Unsafe default:

```text
contract emits arbitrary theorem search and waits until solved
```

## Typed hole

```text
hole_id: H("contract-test-emit-grammar" ++ "loci/chatgpt" ++ "v0.2")
anchor: loci/chatgpt/CONTRACT_TEST_EMIT_GRAMMAR.md
state: open
expected_type: finite test/emission grammar contract
```

Invariants:

- grammar is finite
- emitters are deterministic or explicitly marked otherwise
- tests are bounded
- test results never claim success unless observed
- recursive emission requires a successor graph and fuel
- visual layout does not affect semantic hash

Candidate outputs:

- this profile
- `tests/chatgpt-contracts.tests.json`
- `tests/chatgpt-contracts.results.json`
- future generator command that emits docs/specs/proofs/visuals/plans/tests from ContractGraph IR

Verification:

- current ChatGPT contracts graph has test manifest
- graph and D3 projections have invariant tests
- unrun command tests are marked `blocked`, not passed

Move-out target:

```text
loci/chatgpt first; docs/ or model/ after one end-to-end generation loop
```

Seal condition:

```text
test manifest + observed results are referenced by arblock plan and later LMR leaf
```
