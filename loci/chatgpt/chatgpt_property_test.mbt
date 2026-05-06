///|
fn all_proof_statuses() -> Array[@chatgpt.ProofStatus] {
  [
    @chatgpt.Open,
    @chatgpt.Proved,
    @chatgpt.CoveredByEvidence,
    @chatgpt.Reviewed,
    @chatgpt.Waived,
    @chatgpt.Blocked,
    @chatgpt.Failed,
  ]
}

///|
fn all_solver_statuses() -> Array[@chatgpt.SolverStatus] {
  [
    @chatgpt.NotRequested,
    @chatgpt.Queued,
    @chatgpt.Running,
    @chatgpt.Completed,
    @chatgpt.Failed,
    @chatgpt.TimedOut,
    @chatgpt.InvalidInput,
    @chatgpt.Unsupported,
  ]
}

///|
test "property required_open_count stays within bounds" {
  for status in all_proof_statuses() {
    let binding = @chatgpt.ContractBinding::new(
      "H-prop-open-count",
      Some("loci/chatgpt/tests/chatgpt-contracts.results.muon"),
      Some("loci/chatgpt/coverage/chatgpt-contracts.coverage.muon"),
      Some("loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon"),
      @chatgpt.Covered,
      @chatgpt.Observed,
      [
        @chatgpt.ProofObligation::new("obl-a", true, status),
        @chatgpt.ProofObligation::new("obl-b", false, status),
      ],
    )
    let count = binding.required_open_count()
    assert_true(count >= 0)
    assert_true(count <= binding.obligations.length())
  }
}

///|
test "property actionable length matches required_open_count" {
  for status in all_proof_statuses() {
    let binding = @chatgpt.ContractBinding::new(
      "H-prop-actionable-count",
      Some("loci/chatgpt/tests/chatgpt-contracts.results.muon"),
      Some("loci/chatgpt/coverage/chatgpt-contracts.coverage.muon"),
      Some("loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon"),
      @chatgpt.Covered,
      @chatgpt.Observed,
      [
        @chatgpt.ProofObligation::new("obl-a", true, status),
        @chatgpt.ProofObligation::new("obl-b", true, @chatgpt.Waived),
      ],
    )
    @test.assert_eq(
      binding.actionable_obligations().length(),
      binding.required_open_count(),
    )
  }
}

///|
test "property can_seal_with_solver implies can_seal" {
  let binding = @chatgpt.ContractBinding::new(
    "H-prop-solver-implies-seal",
    Some("loci/chatgpt/tests/chatgpt-contracts.results.muon"),
    Some("loci/chatgpt/coverage/chatgpt-contracts.coverage.muon"),
    Some("loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon"),
    @chatgpt.Covered,
    @chatgpt.Observed,
    [
      @chatgpt.ProofObligation::new(
        "obl-covered",
        true,
        @chatgpt.CoveredByEvidence,
      ),
    ],
  )
  for status in all_solver_statuses() {
    let receipt = @chatgpt.SolverReceipt::new(
      "z3",
      "prop-job",
      status,
      Some("loci/chatgpt/proofs/prop-job.receipt.muon"),
      Some("loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon"),
    )
    let with_solver = binding.can_seal_with_solver(Some(receipt))
    if with_solver {
      assert_true(binding.can_seal())
    }
  }
}

///|
test "property non-completed solver status is never verified" {
  for status in all_solver_statuses() {
    if status != @chatgpt.Completed {
      let receipt = @chatgpt.SolverReceipt::new(
        "z3",
        "prop-job-non-complete",
        status,
        Some("loci/chatgpt/proofs/prop-job-non-complete.receipt.muon"),
        Some("loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon"),
      )
      assert_true(!receipt.is_verified())
    }
  }
}
