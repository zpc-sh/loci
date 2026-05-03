# Security Smell Skill (v0.1)

## Purpose
Provide a high-signal big-picture detector for adversarial complexity patterns during security scans.

## Inputs
- `recovery/artifacts/only_in_turd.txt`
- `PR baseline numstat` (default `/tmp/pr9_vs_head.numstat`)

## Method
- Run FST checks (`PathCollision`, `WorkflowIngress`, `TextContam`, `ConnectorSurface`, `ComplexityBurst`).
- Compose decision by severity lattice.
- Emit smell resonance score/band:
  - `low`, `elevated`, `high`, `critical`.

## Output Artifact
- `artifacts/security/fst_security_scan.json`

## Interpretation
- `critical` + `quarantine|deny` means promotion freeze and allowlist-only migration.
- `high` + `strict` means explicit attestation needed for each promoted batch.
- `elevated` or below can proceed with normal boundary gates.

## Contractual Use
This skill is mandatory when change volume or surface spread exceeds human-review bounds.
