# ChatGPT/Codex Append-Only MuON Dialogue Spec

Spec identity: `loci.chatgpt.codex_dialogue.muonlog.v1`

Status: local draft, intended to upstream into Mu.

Upstream target:
- `../mu/docs/spec/19_CHATGPT_CODEX_DIALOGUE_MUONLOG.md` (proposed new spec slot)

## Purpose

Provide one linear, append-only dialogue ledger for ChatGPT/Codex design work in this embedded locus.

This is intentionally **not** a branchable debate tree.

## File

- `loci/chatgpt/dialogue/chatgpt-codex.muonlog`

## Header (single document prelude)

```muon
kind: :loci_append_only_muonlog
version: "v1"
locus: "loci/chatgpt"
participants: [:chatgpt :codex]
branching: :forbidden
policy: :append_only
identity_policy: :loci_marks_actor
```

## Entry shape

```muon
entry: {
  seq: 42
  ts: "2026-04-26T07:30:00Z"
  speaker: :codex
  loci_mark: { actor: :codex repo: "koan" source: :loci }
  kind: :contract_spec_proof_design
  topic: "meta-codex"
  refs: ["loci/chatgpt/specs/chatgpt-contract-binding.muon"]
  content: "Propose tightening seal_rule for blocked side effects."
  nucleant: { id: "N-loci-ide-socket" repo: "koan" status: :in_progress }
  merge_replacement: { mode: :nucleant_chain key: "N-loci-ide-socket:koan:42" }
}
```

## Invariants

1. `seq` MUST be strictly increasing by append order.
2. Existing entries MUST NOT be edited or deleted.
3. `branching` remains `:forbidden` for this log.
4. `speaker` identity is locus-owned (`identity_policy: :loci_marks_actor`) and MUST NOT rely on self-attestation.
5. `loci_mark.repo` SHOULD identify the actor origin repository.
6. When `nucleant` is present, `merge_replacement.mode` MUST be `:nucleant_chain`.
7. `merge_replacement` entries are the canonical PR/MR replacement surface for this workflow.
8. References SHOULD point at concrete repo artifacts.

## Nucleant Mapping (PR/MR Replacement)

The append-only MuON chain is the merge-request replacement when bounded by one `nucleant.id`.

- Open/update work by appending entries with the same `nucleant.id`.
- Express per-repo progress with `nucleant.repo` + `nucleant.status`.
- Use `merge_replacement.key` as deterministic chain address for review and replay.
- Generate finger plan over nucleant state to produce merge posture.

## CLI/Tooling

Append bridge script:
- `docs/archive/tools/chatgpt-codex-dialogue-append.sh`

Daemon bridge command:
- `moon run cmd/main -- daemon conv append-dialogue --topic meta-codex --nucleant-id N-loci-ide-socket --repo-mark koan --content-file /tmp/msg.txt`

## Contribution plan to Mu

1. Copy this spec into `../mu/docs/spec/` as new item `19_...`.
2. Align wording with MuON conformance language from `../mu/docs/spec/06_muon.md`.
3. Add Mu-side conformance fixture for `seq` monotonicity and append-only policy.
4. Add conformance checks for `identity_policy: :loci_marks_actor` and `merge_replacement.mode: :nucleant_chain`.
