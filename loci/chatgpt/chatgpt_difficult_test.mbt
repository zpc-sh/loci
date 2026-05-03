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
  @test.assert_eq(cycle.history, [
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
  @test.assert_eq(binding.required_open_count(), 1)
  @test.assert_eq(binding.actionable_obligations().length(), 1)
  @test.assert_eq(binding.actionable_obligations()[0].obligation_id, "obl-open")
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

///|
test "solver receipt can seal when completed and receipt is present" {
  let obligations = [
    @chatgpt.ProofObligation::new(
      "obl-covered",
      true,
      @chatgpt.CoveredByEvidence,
    ),
  ]
  let binding = @chatgpt.ContractBinding::new(
    "H-solver-offload-typed-hole",
    Some("loci/chatgpt/tests/chatgpt-contracts.results.muon"),
    Some("loci/chatgpt/coverage/chatgpt-contracts.coverage.muon"),
    Some("loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon"),
    @chatgpt.Covered,
    @chatgpt.Observed,
    obligations,
  )
  let solver = @chatgpt.SolverReceipt::new(
    "z3",
    "solve-job-001",
    @chatgpt.Completed,
    Some("loci/chatgpt/proofs/solve-job-001.receipt.muon"),
    Some("loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon"),
  )
  assert_true(solver.is_verified())
  assert_true(binding.can_seal_with_solver(Some(solver)))
}

///|
test "solver receipt blocks seal when not completed or missing receipt" {
  let obligations = [
    @chatgpt.ProofObligation::new(
      "obl-covered",
      true,
      @chatgpt.CoveredByEvidence,
    ),
  ]
  let binding = @chatgpt.ContractBinding::new(
    "H-solver-offload-typed-hole",
    Some("loci/chatgpt/tests/chatgpt-contracts.results.muon"),
    Some("loci/chatgpt/coverage/chatgpt-contracts.coverage.muon"),
    Some("loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon"),
    @chatgpt.Covered,
    @chatgpt.Observed,
    obligations,
  )

  let running = @chatgpt.SolverReceipt::new(
    "z3",
    "solve-job-002",
    @chatgpt.Running,
    Some("loci/chatgpt/proofs/solve-job-002.receipt.muon"),
    Some("loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon"),
  )
  assert_true(!running.is_verified())
  assert_true(!binding.can_seal_with_solver(Some(running)))

  let missing_receipt = @chatgpt.SolverReceipt::new(
    "z3",
    "solve-job-003",
    @chatgpt.Completed,
    None,
    Some("loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon"),
  )
  assert_true(!missing_receipt.is_verified())
  assert_true(!binding.can_seal_with_solver(Some(missing_receipt)))
}

///|
test "componentization report boundary safe only when all plans are extract-ready" {
  let pending = @chatgpt.ModuleComponentPlan::new(
    "loci.ide",
    "H-loci-ide",
    ["cli/src/commands/ide.ts"],
    "zpc/genius/loci/ide",
    "loci/chatgpt/chatgpt_spec.mbt",
    ["loci/chatgpt/chatgpt_mid_test.mbt"],
    status=@chatgpt.Planned,
  )
  let ready = @chatgpt.ModuleComponentPlan::new(
    "loci.contracts",
    "H-loci-contracts",
    ["loci/chatgpt/LOCI-LINT-MINI-SPEC.md"],
    "zpc/genius/loci/contracts",
    "loci/chatgpt/chatgpt_spec.mbt",
    ["loci/chatgpt/chatgpt_difficult_test.mbt"],
    status=@chatgpt.Verified,
  )
  let report = @chatgpt.ComponentizationReport::new()
    .add_plan(pending)
    .add_plan(ready)
  @test.assert_eq(report.ready_count(), 1)
  assert_true(!report.is_boundary_safe())

  let upgraded = @chatgpt.ModuleComponentPlan::new(
    "loci.ide",
    "H-loci-ide",
    ["cli/src/commands/ide.ts"],
    "zpc/genius/loci/ide",
    "loci/chatgpt/chatgpt_spec.mbt",
    ["loci/chatgpt/chatgpt_mid_test.mbt"],
    status=@chatgpt.Integrated,
  )
  let safe_report = @chatgpt.ComponentizationReport::new()
    .add_plan(upgraded)
    .add_plan(ready)
  @test.assert_eq(safe_report.ready_count(), 2)
  assert_true(safe_report.is_boundary_safe())
}

///|
test "module extraction template status override can force non-ready plan" {
  let template = @chatgpt.ModuleExtractionTemplate::chatgpt_default()
  let planned = template.instantiate(
    "loci.contract.blocks",
    "H-loci-contract-blocks",
    ["loci/chatgpt/LOCI-LINT-MINI-SPEC.md"],
    "contracts/blocks",
    status=Some(@chatgpt.Planned),
  )
  @test.assert_eq(planned.status, @chatgpt.Planned)
  assert_true(!planned.is_ready_for_extract())

  let report = @chatgpt.ComponentizationReport::new().add_plan(planned)
  @test.assert_eq(report.ready_count(), 0)
  assert_true(!report.is_boundary_safe())
}
