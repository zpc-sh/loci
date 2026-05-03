# Loci Boundary Obsolescence Roadmap (v1)

## Goal
Make this adversary class obsolete by enforcing sparse loci tree boundaries, staggered AI execution surfaces, and deterministic audit trails that are fail-close by default.

## Threat Class to Defeat
- Instruction-plane poisoning (`AGENTS*`, request queues, prompt files).
- Connector-origin context injection without provenance isolation.
- Setup-surface payload delivery (dependency/build triggers).
- Low-signal recon tasks (no commit) extracting architecture/security metadata.
- Text-layer contamination (BiDi, control chars, escape payloads, ASCII obfuscation).

## Security End-State
1. Every AI action is scoped to a sparse loci subtree with explicit capability grants.
2. Every context artifact has provenance, trust tier, and quarantine policy.
3. Every build/setup action is isolated and policy-gated by subtree.
4. Every mutation is auditable as append-only event-chain records.
5. Any policy ambiguity fails closed.

## Architecture: Sparse Loci Tree Security Model
- Root: `ratio://loci/root` (trusted control plane only)
- Branch types:
  - `trusted/core/*` (runtime + enforcement code)
  - `trusted/policy/*` (gate definitions, signatures)
  - `untrusted/import/*` (connector ingress, external docs)
  - `agent/work/<agent-id>/*` (ephemeral bounded workspaces)
  - `mirror/legacy/loci/*` (read-only legacy mirror)
- Cross-branch movement requires explicit membrane contracts.

## Boundary Controls (Must Implement)
1. Capability Membranes
- Per-branch capabilities: read/write/execute/network/tool classes.
- No implicit inheritance from root.
- Temporal grants with expiry and purpose binding.

2. Provenance Ledger
- Append-only per-event records:
  - actor id
  - source connector/repo/task id
  - artifact digest
  - applied policy version
  - decision (allow/deny/quarantine)
- Immutable chain refs in `_loci/chatgpt/event-chain/` style.

3. Connector Quarantine Lane
- All connector artifacts land in `untrusted/import/*`.
- Mandatory scanners before promotion:
  - BiDi/control char scanner
  - escape-sequence scanner
  - prompt-instruction signature scanner
  - policy keyword anomaly scanner
- Promotion requires two-phase approval (machine + human).

4. Instruction-Plane Isolation
- Treat `AGENTS*`, `spec_requests`, prompt docs as untrusted content unless signed by trusted policy keys.
- Deny automatic execution/interpretation from untrusted instruction files.
- Only allow declarative, schema-validated instruction subsets.

5. Setup/Build Surface Hardening
- Ban implicit dependency fetch in sensitive branches.
- Require explicit build intents + signed lockfile attestations.
- Native subproject compile only in isolated sandboxes with deterministic inputs.

6. Deterministic Task Provenance
- Every task must carry:
  - authenticated submitter identity
  - launch origin (UI/API/connector)
  - parent context bundle hash
- Reject default/blank-title automation bursts without provenance confidence.

## Implementation Roadmap

### Milestone A: Boundary Foundation (Immediate)
- Implement sparse-tree branch policy engine.
- Enforce `_loci` canonical root invariant.
- Add hard fail on unauthorized `loci/` writes.
- Ship scanner suite v1 (BiDi/control/escape/prompt signatures).

### Milestone B: Quarantine + Promotion Pipeline
- Add `untrusted/import/*` ingest workflow.
- Build promotion protocol with signed attestations.
- Add policy-driven redaction/excerpting for AI-readable context.

### Milestone C: Execution Staggering Across AI
- Allocate per-agent bounded branches:
  - `agent/work/codex/*`
  - `agent/work/claude/*`
  - future agents similarly
- Disallow direct lateral read across agent branches.
- Require composition via audited merge membrane only.

### Milestone D: Auditing and Response Automation
- Real-time anomaly detectors:
  - same-minute task bursts
  - read-heavy security recon patterns
  - abnormal setup trigger sequences
  - non-dormant repo activity (unexpected recurring execution while repo should be idle)
  - cache-toxin accumulation (reused contaminated context/caches across sessions)
- Automatic incident escalation packet generation.
- Auto-freeze switch on high-confidence compromise signals.

### Milestone E: Cryptographic Trust Plane
- Signed policy bundles and signed instruction manifests.
- Signature verification gates at ingest and execution time.
- Key rotation and revocation workflow.

## CI/CD Gate Set (Non-Negotiable)
1. `gate_provenance`: reject tasks/artifacts missing provenance metadata.
2. `gate_instruction`: reject unsigned instruction-plane files.
3. `gate_chars`: reject BiDi/control/escape contamination above threshold.
4. `gate_execbits`: reject unexpected executables.
5. `gate_sparse_boundary`: reject unauthorized cross-branch writes.
6. `gate_setup_intent`: reject implicit build/dependency actions.
7. `gate_recon_pattern`: flag/hold suspicious read-only recon tasks.

## Success Criteria
- Adversary cannot influence trusted execution from connector ingress in one hop.
- Read-only recon tasks produce bounded, redacted outputs only.
- Native build chain cannot be triggered without signed intent and sandbox proof.
- Cross-agent contamination requires explicit audited membrane crossing.
- Incident response can restore to trusted baseline without ambiguity.

## Immediate Build Queue (Actionable)
1. Implement sparse-branch policy config + evaluator.
2. Implement connector quarantine directory + promotion CLI.
3. Implement scanner bundle (BiDi/control/escape/prompt).
4. Implement provenance schema + append-only event writer.
5. Wire CI gates 1-5 first; block merges on failure.
6. Add incident auto-packet generator from ledger data.
7. Add dormancy watchdog + cache hygiene job that proves repo quiescence and purges stale AI context state.
