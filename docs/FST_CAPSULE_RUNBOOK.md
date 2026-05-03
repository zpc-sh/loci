# FST Capsule Runbook (v0.1)

This runbook ties `loci_fsm` execution to the capsule contract and the generated wasm assurance posture.

## Policy stance

- FSTs are deterministic/stateful transducers.
- FSTs do **not** perform direct network I/O.
- Allowed host-mediated surfaces: file, socket, store, clock, log.
- Network-deny is asserted in capsule assurance policy (`deny_network=true`).

## Default locus bootstrap

Every new locus now includes default FST profiles:

- `fst/defaults.yaml`
- `fst/boundary-walker.yaml`
- `fst/reporter.yaml`

Create and inspect:

```bash
loci loci new demo-fst
ls -la loci/demo-fst/fst
```

## Example 1: Repo-scoped boundary + triad scan

Run against this repository state:

```bash
just loci-fsm-repo-scan
```

Artifacts:

- `artifacts/loci-fsm/wasm-plan.txt`
- `artifacts/loci-fsm/triad-contract.txt`
- `artifacts/loci-fsm/summary.env`

Checks to assert:

- `wasm-plan.txt` contains `kind: loci.boundary.stigmergy`
- `triad-contract.txt` contains `"kind": "loci.triad.contract"`
- `triad-contract.txt` has `"refs_byte_clean": true` for clean refs

## Example 2: Custom routes/tokens

```bash
ROUTES="README.md,cli/src/spec.ts,loci_fsm/boundary.mbt" \
TOKENS="loci,fsm,boundary,release" \
just loci-fsm-repo-scan out_dir=artifacts/loci-fsm-custom
```

## Example 3: Pin sibling refs for stronger triad assurance

```bash
MU_HEAD="<mu-commit>" LANG_HEAD="<lang-commit>" \
MU_BRANCH="main" LANG_BRANCH="main" \
just loci-fsm-repo-scan out_dir=artifacts/loci-fsm-pinned
```

## Direct command equivalents

```bash
moon run cmd/main -- daemon yata wasm-plan \
  --routes "README.md,cli/src/spec.ts" \
  --tokens "loci,fsm" \
  --drift-peers "mu:unknown,lang:unknown" \
  --seal true

moon run cmd/main -- daemon yata triad-contract \
  --routes "README.md,cli/src/spec.ts" \
  --tokens "loci,fsm" \
  --drift-peers "mu:unknown,lang:unknown" \
  --loci-head "$(git rev-parse HEAD)" \
  --mu-head unknown \
  --lang-head unknown \
  --loci-branch "$(git rev-parse --abbrev-ref HEAD)" \
  --mu-branch unknown \
  --lang-branch unknown \
  --wasm-exports "plan_finger_wasm,plan_drift_commitment,triad_contract_wasm" \
  --generated-at-utc "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --contract-version v0.1
```

## Release gating recommendation

For release assurance, require:

1. `moon check --deny-warn`
2. `moon test --target wasm-gc`
3. `just loci-fsm-repo-scan`
4. Artifact checks for `loci.boundary.stigmergy` + `loci.triad.contract`
