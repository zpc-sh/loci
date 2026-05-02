///|
test "public mirror crossing validates all posture fields" {
  let incomplete = @chatgpt.CrossingRecord::new(
    "",
    "docs/public",
    "docs/MU_RUNTIME_SPEC.md",
    "publish spec mirror",
    @chatgpt.PublicMirror,
    seal=Some("sha256:ef01"),
  )
  assert_true(!incomplete.is_complete())

  let ready = @chatgpt.CrossingRecord::new(
    "loci/chatgpt",
    "docs/public",
    "docs/MU_RUNTIME_SPEC.md",
    "publish spec mirror",
    @chatgpt.PublicMirror,
    seal=Some("sha256:ef01"),
  )
  assert_true(ready.is_complete())
}

///|
test "history preserves deterministic stage order" {
  let cycle = @chatgpt.WorkCycle::new().advance().advance().advance()
  assert_eq(cycle.history, [
    @chatgpt.Form,
    @chatgpt.Fruition,
    @chatgpt.Aperture,
    @chatgpt.Seal,
  ])
}

///|
test "contract cannot seal with open required obligations" {
  let obligations = [
    @chatgpt.ProofObligation::new("obl-open", true, @chatgpt.Open),
    @chatgpt.ProofObligation::new("obl-waived", true, @chatgpt.Waived),
  ]
  let binding = @chatgpt.ContractBinding::new(
    "H-cross-conversation-primitive",
    Some("loci/chatgpt/tests/chatgpt-contracts.results.muon"),
    Some("loci/chatgpt/coverage/chatgpt-contracts.coverage.muon"),
    Some("loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon"),
    @chatgpt.Partial,
    @chatgpt.Observed,
    obligations,
  )
  assert_eq(binding.required_open_count(), 1)
  assert_true(!binding.can_seal())
}

///|
test "blocked side effects prevent seal even with discharged obligations" {
  let obligations = [
    @chatgpt.ProofObligation::new(
      "obl-covered",
      true,
      @chatgpt.CoveredByEvidence,
    ),
  ]
  let blocked = @chatgpt.ContractBinding::new(
    "H-contract-test-emit-grammar",
    Some("loci/chatgpt/tests/chatgpt-contracts.results.muon"),
    Some("loci/chatgpt/coverage/chatgpt-contracts.coverage.muon"),
    Some("loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon"),
    @chatgpt.Covered,
    @chatgpt.BlockedEffect,
    obligations,
  )
  assert_true(!blocked.can_seal())

  let ready = @chatgpt.ContractBinding::new(
    "H-contract-test-emit-grammar",
    Some("loci/chatgpt/tests/chatgpt-contracts.results.muon"),
    Some("loci/chatgpt/coverage/chatgpt-contracts.coverage.muon"),
    Some("loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon"),
    @chatgpt.Covered,
    @chatgpt.NotRequired,
    obligations,
  )
  assert_true(ready.can_seal())
}
