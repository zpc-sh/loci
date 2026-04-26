# Claude Work Checklist

Scope: building, architecting, and new feature conception for the Loci/Merkin stack.

Not exhaustive. Add items as holes open; tick them as they land.

---

## Contract & Coverage

- [x] Implement `ContractBinding::can_seal` gate types (`loci/chatgpt/chatgpt.mbt`)
- [x] Wire `move_out_ready` / `crossing_ready` into `locus/locus.mbt`
- [x] Write tests for `ConversationHost` (`daemon/conversation_test.mbt`)
- [x] Unblock Optional Proof conformance test (`conformance/optional_profiles_test.mbt`)
- [x] Close coverage gap holes for `daemon/conversation.mbt` and `model/boundary_fsm.mbt`
- [ ] Import `moon coverage analyze` output into `chatgpt-contracts.coverage.muon` (replace placeholders)
- [ ] Add CI task: `just chatgpt-contract-bind` + drift check on coverage binding

---

## Daemon / CLI Surface

- [x] `ConversationHost` scaffold (`daemon/conversation.mbt`)
- [x] Dialogue append-only spec + append script
- [x] `daemon conv append-dialogue` bridge command
- [ ] `daemon conv design` command wrapper (emits `.plan` from ChatGPT + Codex content)
- [ ] Wire `ConversationHost` into `cmd/main` for `conv design --topic ... --design-out`
- [ ] Tests for accepted/rejected turns saved as plan output

---

## Model Layer

- [x] `BoundaryWalkerFsm::cross` with passport walking and `CrossingReport`
- [x] `YataPlan` wire format + `to_wire()` + round-trip tests
- [x] `SllBuildContract` types
- [ ] `model/yata_proof.mbtp` — formal predicates (wire roundtrip stability, entry-count consistency, address canonicalization idempotence)
- [ ] Lift parser/address helpers to `proof_require` / `proof_ensure` contract-bearing APIs
- [ ] Optional Semantic conformance profile (embedding generation hook)

---

## Move-Out / Canonicalization

- [x] First passport/crossing record emitted
- [x] `just chatgpt-mulsp-handoff-verify` handoff verifier
- [ ] `SLL_DOCKERFILE_PARITY.md` — readable SLL blueprint → Dockerfile parity contract
- [ ] First LMR leaf/root/proof example (OCI artifact in Kyozo Store)
- [ ] Update `MOVE_OUT_MAP.md` with final seal evidence for any completed move-outs
- [ ] Companion doc near `docs/MU_RUNTIME_SPEC.md` for stable locus contracts

---

## Conformance & Hardening

- [x] Core profile: 8 required invariants passing
- [x] Optional Proof profile: `ContractBinding::can_seal` round-trip
- [ ] Optional Semantic: embedding generation profile (needs runtime hook)
- [ ] Optional Batch: ordered batch execution profile
- [ ] MuON artifact parser/validator (`just chatgpt-contract-bind` output)
- [ ] Deterministic hash/seal field in generated MuON binding spec
