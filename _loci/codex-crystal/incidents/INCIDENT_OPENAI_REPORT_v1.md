# Incident Report for OpenAI/Codex (v1)

## Executive Summary
We observed a coordinated pattern of suspicious Codex task activity on **April 19, 2026** across repository workspaces, including same-minute parallel tasks, read-only reconnaissance output, and targeted session-path modifications. The pattern appears to combine control-plane steering with repeated build/setup trigger surfaces.

This report is intended for OpenAI security/operations triage and provenance validation.

## Incident Class
- Prompt/control-plane steering likely via repository-resident agent instruction surfaces.
- Potential build-chain persistence attempt via repeated dependency-fetch paths.
- Reconnaissance tasks that exfiltrate architecture/security details without producing commits.

## Key Observations
1. Multiple tasks launched in the same minute with generic/default task titles.
2. A no-commit task extracted high-value auth/transport details (endpoints, JWT claims, proxy/rate-limit topology).
3. Another task committed session metadata/fallback changes into a security-sensitive path.
4. Native subproject dependency fetches repeatedly triggered in setup routines.
5. Agent instruction and spec-handoff files were present and used as first-hop context.

## Most Likely Ingress Vectors (Hypotheses)
These are hypotheses, not final attribution.

1. Connector-mediated task/context injection (Google Drive, GitHub)
- Confidence: **Medium**
- Rationale: suspicious task bursts and context-shaping behavior are compatible with connector-origin artifacts becoming trusted task inputs.
- Current operator suspicion: Google Drive as initial ingress; GitHub as persistence/amplification surface.

2. Repository instruction-plane poisoning (`AGENTS*.md`, `work/spec_requests/*`)
- Confidence: **High**
- Rationale: this mechanism can steer agent behavior deterministically without immediate code diffs.

3. Setup-surface abuse (auto dependency fetch/build of native subprojects)
- Confidence: **High**
- Rationale: repeated cargo/dependency fetch in setup gives durable opportunities for payload delivery.

## Why Standard Audits Miss This
- Read-only recon tasks can have severe impact but leave no commit trace.
- Default task names and short durations blend into routine activity.
- Setup-time execution paths are often treated as normal operational noise.

## Containment Already Applied (Local)
- Canonicalized safe authoring root to `_loci`.
- Added trust audit + mirror drift checks under `artifacts/security`.
- Added executable-bit normalization policy and checks.
- Added deterministic composition conflict handling in `_loci/chatgpt`.

## Requests to OpenAI
1. Full provenance for suspicious task IDs
- submitter principal, auth context, API/UI origin, source session/IP metadata.

2. Raw prompt/context bundle retrieval
- exact system/developer/user/context items and connector-sourced payloads at task start.

3. Cross-task orchestration analysis
- detect same-minute, multi-task bursts with default titles across repos/workspaces.

4. Setup transcript parity comparison
- compare “normal user task” setup path vs “suspicious task” setup path for trust-gate bypass differences.

5. Connector ingestion traceability
- explicit logs of which connector artifacts were ingested, when, and under which trust policy.

## Immediate Recommendation
Treat this as a platform-assisted control-plane incident until provenance disproves it.

## Local Snapshot References
- Current local head: `ce305c3e6cdecaa2f8a77e7bac7385d525e18e45`
- Trusted baseline (`origin/master` during audit): `ab1304e07a3c6db10cb7b9cb178193017ff462e1`
- Trust report: `artifacts/security/trust_report.json`
- Mirror report: `artifacts/security/loci_mirror_check.json`

