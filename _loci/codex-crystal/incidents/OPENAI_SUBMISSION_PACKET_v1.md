# OpenAI Submission Packet (v1)

## Subject
Potential control-plane task injection and setup-surface abuse affecting Codex tasks

## Incident Summary
We observed suspicious Codex task behavior on **April 19, 2026** consistent with coordinated automation:
- same-minute parallel tasks with generic/default titles,
- read-only reconnaissance tasks exfiltrating architecture/security details,
- targeted write task mutating session/fallback metadata,
- repeated setup-trigger dependency fetch surfaces in native subprojects.

This appears to be a control-plane steering + build/setup trigger pattern rather than an isolated bad commit.

## Why We Are Escalating
- High-impact recon can occur with **no code diff** and evade normal git audit.
- Task orchestration pattern suggests non-human dispatch behavior.
- Repository instruction surfaces appear to be used as behavior-steering inputs.

## Task IDs of Interest
- `task_e_69e493fba0a0832eb6d0c6eadf02179a` (write task)
- `task_e_69e493f916d0832e83a878b6cd69bd79` (read-only recon task)

## Most Likely Ingress Vectors (Hypotheses)
- Connector-mediated context injection (Google Drive / GitHub): **Hypothesis (medium confidence)**
- Repo-local instruction-plane poisoning (`AGENTS*`, spec request surfaces): **Strong (high confidence)**
- Setup-surface abuse via native dependency-fetch/compile triggers: **Strong (high confidence)**

## Requested Actions from OpenAI
1. **Task provenance** for listed task IDs
- submitter principal, auth context, source session/IP, UI/API origin.

2. **Raw prompt/context bundle retrieval**
- exact system/developer/user/context payloads at task start,
- including connector-ingested artifacts and trust decisions.

3. **Cross-task orchestration analysis**
- detect same-minute multi-task bursts with default titles across repos/workspaces.

4. **Setup path parity diff**
- compare setup transcript and trust-gate behavior between suspicious and normal tasks.

5. **Connector traceability audit**
- explicit provenance logs for connector artifacts injected into task context.

## Local Evidence Artifacts
- Incident report: `_loci/codex-crystal/incidents/INCIDENT_OPENAI_REPORT_v1.md`
- Evidence index: `_loci/codex-crystal/incidents/EVIDENCE_INDEX_v1.json`
- Trust audit: `artifacts/security/trust_report.json`
- Mirror drift report: `artifacts/security/loci_mirror_check.json`

## Local Baseline Snapshot
- Current local head: `ce305c3e6cdecaa2f8a77e7bac7385d525e18e45`
- Trusted origin/master baseline: `ab1304e07a3c6db10cb7b9cb178193017ff462e1`

## Operator Notes
We are proceeding under incident assumptions until provenance disproves malicious orchestration. We have already moved canonical local authoring and containment workflows to `_loci` and are preparing rollback + boundary-hardening execution.

