# Three-Body Lock: Executable MoonBit Markdown

Status: active  
Scope: `loci <-> mu <-> lang`  
Intent: keep all three projects in one contract-runtime paradigm and avoid drifting back to two-way lock failure modes.

## 1) Invariant Contract

The lock is healthy only if all of these are true at once:

1. **Contract lock**: shared contract surfaces are present and version-aligned.
2. **Runtime lock**: each repo can emit/consume runtime chain artifacts.
3. **Proof lock**: prove/check/test gates are green enough to trust handoffs.
4. **Projection lock**: human+machine views are regenerated from executable sources.

## 2) Executable Snapshot

Run this from loci root:

```bash
./scripts/three_body_lock_snapshot.sh
```

Outputs:
- `artifacts/three-body-lock/snapshot.json`
- `artifacts/three-body-lock/snapshot.md`

## 3) Loci-First Runtime Bridge Walk

This executes the in-loci FST-style runtime bridge handler and append chain:

```bash
./scripts/sync_lang_loci_specs.sh
python3 scripts/loci_runtime_bridge_handler.py
```

Check artifacts:

```bash
test -f _loci/chatgpt/handlers/runtime-bridge/latest_projection.json
test -f _loci/chatgpt/event-chain/blocks.jsonl
tail -n 5 _loci/chatgpt/handlers/runtime-bridge/walk.jsonl
```

## 4) Capsule + Crystal + Proof Binding

```bash
python3 docs/emit_contract_views.py
python3 docs/emit_pattern_crystal.py
./scripts/prove_crystal_capsule.sh
```

Expected receipt:

```bash
test -f docs/contracts/CRYSTAL_CAPSULE_PROOF.json
cat docs/contracts/CRYSTAL_CAPSULE_PROOF.json
```

## 5) Tri-Repo Synchronization Pattern

Minimal lock step:

```bash
# in loci
./scripts/three_body_lock_snapshot.sh

# in mu and lang (mirrored pattern)
# - emit contract projection
# - run runtime chain checks
# - emit proof receipt
```

Required shared fields across repos:
- `project`
- `head`
- `branch`
- `contract_surface_version`
- `runtime_chain_status`
- `proof_status`
- `generated_at_utc`

## 6) MoonBit Contract Skeleton (portable)

```moonbit
pub struct RepoLockReport {
  project : String
  head : String
  branch : String
  contract_surface_version : String
  runtime_chain_status : String
  proof_status : String
  generated_at_utc : String
}

pub fn repo_lock_ready(r : RepoLockReport) -> Bool {
  r.head != "" &&
  r.branch != "" &&
  r.contract_surface_version != "" &&
  r.runtime_chain_status == "ok" &&
  r.proof_status == "ok"
}
```

## 7) Promotion Rule

A change is three-body promotable only if:

1. loci lock snapshot generated
2. runtime bridge walk passes in loci
3. capsule+crystal proof receipt emitted
4. equivalent lock snapshot exists in mu and lang (same lock schema)

If any one fails, treat as `not promotable`.

## 8) Why This Works

This pattern keeps us out of "doc-only architecture":
- executable scripts generate lock state
- lock state emits machine-readable artifacts
- artifacts are consumed by handlers/FST walkers
- handlers append canonical chain blocks

So the architecture becomes self-demonstrating and self-correcting.

