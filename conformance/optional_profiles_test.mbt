///|
/// Optional profile placeholders.
/// These are intentionally skipped until runtime interfaces exist.
#skip("Semantic profile runtime hooks not implemented in this repository")
test "Optional Semantic: embedding generation profile" {
  assert_true(true)
}

///|
test "Optional Proof: proof round-trip via ContractBinding::can_seal" {
  let obligations = [
    @chatgpt.ProofObligation::new(
      "obl-proof-1",
      true,
      @chatgpt.CoveredByEvidence,
    ),
  ]
  let binding = @chatgpt.ContractBinding::new(
    "H-contract-coverage-proof-binding",
    Some("loci/chatgpt/tests/chatgpt-contracts.results.muon"),
    Some("loci/chatgpt/coverage/chatgpt-contracts.coverage.muon"),
    Some("loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon"),
    @chatgpt.Covered,
    @chatgpt.NotRequired,
    obligations,
  )
  assert_true(binding.can_seal())
}

///|
#skip("Batch profile runtime hooks not implemented in this repository")
test "Optional Batch: ordered batch execution profile" {
  assert_true(true)
}

///|
#skip("Offload profile runtime hooks not implemented in this repository")
test "Optional Offload: accumulate/offload/execute profile" {
  assert_true(true)
}
