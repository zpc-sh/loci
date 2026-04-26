///|
test "cycle closure is true after full round-trip" {
  let cycle = @chatgpt.WorkCycle::new().advance().advance().advance().advance()
  @test.assert_eq(cycle.stage, @chatgpt.Form)
  assert_true(cycle.is_cycle_closed())
  @test.assert_eq(cycle.history.length(), 5)
}

///|
test "canonical crossing requires seal" {
  let missing = @chatgpt.CrossingRecord::new(
    "loci/chatgpt",
    "model",
    "model/yata.mbt",
    "move stable contract to runtime package",
    @chatgpt.Canonical,
  )
  assert_true(!missing.is_complete())

  let sealed_record = @chatgpt.CrossingRecord::new(
    "loci/chatgpt",
    "model",
    "model/yata.mbt",
    "move stable contract to runtime package",
    @chatgpt.Canonical,
    seal=Some("sha256:abcd"),
  )
  assert_true(sealed_record.is_complete())
}

///|
test "contract binding requires tests coverage and proof refs" {
  let obligations = [
    @chatgpt.ProofObligation::new(
      "obl-coverage-proof-binding",
      true,
      @chatgpt.CoveredByEvidence,
    ),
  ]
  let missing_coverage = @chatgpt.ContractBinding::new(
    "H-contract-coverage-proof-binding",
    Some("loci/chatgpt/tests/chatgpt-contracts.results.muon"),
    None,
    Some("loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon"),
    @chatgpt.Unknown,
    @chatgpt.Observed,
    obligations,
  )
  assert_true(!missing_coverage.is_bound())

  let bound = @chatgpt.ContractBinding::new(
    "H-contract-coverage-proof-binding",
    Some("loci/chatgpt/tests/chatgpt-contracts.results.muon"),
    Some("loci/chatgpt/coverage/chatgpt-contracts.coverage.muon"),
    Some("loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon"),
    @chatgpt.Covered,
    @chatgpt.Observed,
    obligations,
  )
  assert_true(bound.is_bound())
}
