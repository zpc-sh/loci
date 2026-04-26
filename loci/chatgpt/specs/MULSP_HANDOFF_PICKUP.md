# Mulsp Handoff Pickup (Codex-to-Codex)

Intent: move daemon bridge surface ownership from this repo into `../lang` (`mulsp` first), using a strict membrane crossing with replayable MuON artifacts.

## Boundary Verdict

Membrane/boundary shape is sufficient for handoff.

Reason:
1. Passport contains all required sections (`who/what/why/where/how_far/trace`).
2. Crossing artifact bundle is sealed by deterministic sha256 list.
3. Dialogue/context lineage is included for replay (`chatgpt-codex.muonlog`).
4. Scope is narrowed to explicit target surfaces.

Passport:
- `loci/chatgpt/specs/mulsp-handoff-passport.muon`

Bundle hash list:
- `loci/chatgpt/specs/mulsp-handoff-bundle.sha256`

## Pickup Sequence in `../lang`

1. Verify boundary artifacts from this repo:
- `just chatgpt-mulsp-handoff-verify`
2. Verify bundle hashes against files in this repo.
3. Recreate equivalent surfaces in `../lang` under mulsp ownership:
- contract-binding generation hook
- append-only dialogue hook
- daemon/cli bridge command ownership
4. Keep bridge semantics orchestration-first (emit command), then decide if mulsp should execute or continue delegating.
5. Emit reciprocal passport back to `loci/chatgpt` with `intent: verify` and resulting refs.

## Required artifacts from this repo

- `loci/chatgpt/specs/chatgpt-contract-binding.muon`
- `loci/chatgpt/tests/chatgpt-contracts.tests.muon`
- `loci/chatgpt/tests/chatgpt-contracts.results.muon`
- `loci/chatgpt/coverage/chatgpt-contracts.coverage.muon`
- `loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon`
- `loci/chatgpt/DIALOGUE_APPEND_ONLY_MUON_SPEC.md`
- `loci/chatgpt/dialogue/chatgpt-codex.muonlog`
- `docs/archive/tools/chatgpt-contract-binding-generate.sh`
- `docs/archive/tools/chatgpt-codex-dialogue-append.sh`
- `cmd/main/main.mbt`
- `cmd/main/main_wbtest.mbt`
- `Justfile`

## Mu upstream note

When moving to `../mu`, use:
- source: `loci/chatgpt/DIALOGUE_APPEND_ONLY_MUON_SPEC.md`
- target proposal: `../mu/docs/spec/19_CHATGPT_CODEX_DIALOGUE_MUONLOG.md`
- align language with `../mu/docs/spec/06_muon.md`
