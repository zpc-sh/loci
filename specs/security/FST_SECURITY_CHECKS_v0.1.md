# FST Security Checks (v0.1)

## Why
Assume adversary strategy is complexity explosion: force reviewers to reason over too many changes and hide payloads in volume.

Defense: never reason manually over full surface first. Reduce to deterministic token streams and consume with Finite State Transducers (FSTs).

## Contract
Every check is expressed as:
1. `extract`: deterministic tokenization of input surface
2. `match`: pattern families over token stream
3. `consume`: FST transition walk
4. `emit`: typed decision (`allow|sanitize|strict|quarantine|deny`) + evidence

## FST Families

### 1) `PathCollisionFST`
Input tokens:
- path root (`loci`, `_loci`, other)
- operation (`A`, `M`, `D`, mode-change)
- semantic key (doc/code/spec/runtime)

Patterns:
- dual-root mutation on same semantic key
- mirrored files with divergence
- mode churn bursts

Consume result:
- `quarantine` if dual-root conflicting writes
- `sanitize` if mirror-only deterministic deltas

### 2) `WorkflowIngressFST`
Input tokens:
- `.github/workflows/*` edits
- script/entrypoint edits
- remote fetch/exec signatures

Patterns:
- workflow add/delete swap clusters
- newly executable non-script files
- suspicious exec chains

Consume result:
- `strict` or `deny` unless explicitly attested

### 3) `TextContamFST`
Input tokens:
- Unicode classes (BiDi/control/ghost)
- line-role (code/spec/doc)
- parser sensitivity zone

Patterns:
- bidi in executable zones
- control chars in identifiers/paths
- ghost-byte concentration bursts

Consume result:
- `quarantine` for executable-zone contamination
- `sanitize` for display-only zones with canonical rewrite

### 4) `ConnectorSurfaceFST`
Input tokens:
- connector/tool invocation traces
- fallback mode toggles
- task dispatch metadata

Patterns:
- connector fallback activation in privileged flows
- hidden task/dispatch asymmetry
- parallel task bursts with default naming

Consume result:
- `strict` on connector ingress
- `quarantine` task artifacts lacking provenance attestation

### 5) `ComplexityBurstFST`
Input tokens:
- files changed, net LOC, top-level spread, generated ratio
- duplicate-surface factor (`_loci` vs `loci`)

Patterns:
- high spread + high duplication + policy-surface touches
- low semantic yield / high file churn

Consume result:
- block broad promotion
- force allowlist promotion batches

## Composition Rule
Run transducers in order:
1. `PathCollisionFST`
2. `WorkflowIngressFST`
3. `TextContamFST`
4. `ConnectorSurfaceFST`
5. `ComplexityBurstFST`

Final decision is lattice-joined by severity:
`allow < sanitize < strict < quarantine < deny`

## Consumption Artifacts
Each transducer must emit:
- `state_trace`: transition path
- `trigger_tokens`: exact matched tokens
- `decision`
- `evidence_ref` (artifact path/hash)

## Operational Use
- Use `recovery/loci_clean` as promotion target.
- Consume `recovery/loci_turd` through FST checks.
- Promote only allowlisted files whose composed decision <= `sanitize`.
- Anything `strict` requires explicit attestation.
- Anything `quarantine|deny` stays in turd.
