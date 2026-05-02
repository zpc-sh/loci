///|
fn sample_binding(
  proof_status : @chatgpt.ProofStatus,
  side_effect_status : @chatgpt.SideEffectStatus,
) -> @chatgpt.ContractBinding {
  let obligations = [@chatgpt.ProofObligation::new("obl", true, proof_status)]
  @chatgpt.ContractBinding::new(
    "H-contract-coverage-proof-binding",
    Some("loci/chatgpt/tests/chatgpt-contracts.results.muon"),
    Some("loci/chatgpt/coverage/chatgpt-contracts.coverage.muon"),
    Some("loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon"),
    @chatgpt.Covered,
    side_effect_status,
    obligations,
  )
}

///|
test "locus move_out_ready follows contract seal gate" {
  let blocked = sample_binding(@chatgpt.Open, @chatgpt.Observed)
  assert_true(!@locus.move_out_ready(blocked))

  let ready = sample_binding(@chatgpt.CoveredByEvidence, @chatgpt.NotRequired)
  assert_true(@locus.move_out_ready(ready))
}

///|
test "crossing_ready requires both crossing and binding readiness" {
  let sealed_binding = sample_binding(
    @chatgpt.CoveredByEvidence,
    @chatgpt.Observed,
  )
  let incomplete_crossing = @chatgpt.CrossingRecord::new(
    "loci/chatgpt",
    "docs",
    "docs/MU_RUNTIME_SPEC.md",
    "publish profile",
    @chatgpt.Canonical,
  )
  assert_true(!@locus.crossing_ready(incomplete_crossing, sealed_binding))

  let complete_crossing = @chatgpt.CrossingRecord::new(
    "loci/chatgpt",
    "docs",
    "docs/MU_RUNTIME_SPEC.md",
    "publish profile",
    @chatgpt.Canonical,
    seal=Some("sha256:42"),
  )
  assert_true(@locus.crossing_ready(complete_crossing, sealed_binding))
}
