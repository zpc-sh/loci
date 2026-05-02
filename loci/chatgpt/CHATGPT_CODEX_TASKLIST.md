# ChatGPT/Codex Tasklist

Purpose: concrete check-off list for the ChatGPT/Codex locus pipeline.

## 1. Contract Binding Core

- [x] Add contract gate types in `loci/chatgpt/chatgpt_spec.mbt`
- [x] Implement `ContractBinding::is_bound` and `ContractBinding::can_seal` in `loci/chatgpt/chatgpt.mbt`
- [x] Add black-box tests for open/blocked/discharged seal behavior
- [x] Add integration consumer in `locus` (`move_out_ready`, `crossing_ready`)

## 2. MuON-First Artifacts (no JSON dependency for binding refs)

- [x] Switch binding refs in tests from `.json` to `.muon`
- [x] Add generator script: `docs/archive/tools/chatgpt-contract-binding-generate.sh`
- [x] Add `just` task: `just chatgpt-contract-bind`
- [x] Generate MuON artifacts:
- [x] `loci/chatgpt/specs/chatgpt-contract-binding.muon`
- [x] `loci/chatgpt/tests/chatgpt-contracts.tests.muon`
- [x] `loci/chatgpt/tests/chatgpt-contracts.results.muon`
- [x] `loci/chatgpt/coverage/chatgpt-contracts.coverage.muon`
- [x] `loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon`
- [x] Generate docs summary: `loci/chatgpt/GENERATED_CONTRACT_BINDING.md`

## 3. Validation Loop

- [x] Run `moon check`
- [x] Run `moon test`
- [x] Run `moon info && moon fmt`
- [ ] Run `just test-yata` and record result in MuON result ledger
- [ ] Bind `moon coverage analyze` output into `chatgpt-contracts.coverage.muon` (replace placeholders)

## 4. Daemon/CLI Automation Surface

- [x] Add daemon categorical command for binding/doc generation (`daemon yata ...`)
- [x] Add CLI usage/help lines for the new command
- [x] Add tests for command output contract

## 4b. Meta Dialogue Surface

- [x] Define append-only MuON dialogue spec for ChatGPT/Codex
- [x] Add append script (`chatgpt-codex-dialogue-append.sh`)
- [x] Add bridge command mapping (`daemon conv append-dialogue`)
- [x] Add whitebox tests for action mapping and bridge command shape
- [x] Seed dialogue ledger: `loci/chatgpt/dialogue/chatgpt-codex.muonlog`

## 5. Move-Out / Canonicalization

- [ ] Decide first canonical consumer (`model` or `daemon`) for `ContractBinding::can_seal`
- [x] Emit first passport/crossing record for a real move-out
- [x] Add deterministic pickup verifier (`just chatgpt-mulsp-handoff-verify`)
- [ ] Update `MOVE_OUT_MAP.md` with final destination and seal evidence
- [ ] Add companion doc near `docs/MU_RUNTIME_SPEC.md` once stable

## 6. Optional Hardening

- [ ] Add parser/validator for generated MuON artifacts
- [ ] Add deterministic hash/seal field in MuON binding spec output
- [ ] Add CI task to run `just chatgpt-contract-bind` + drift check
