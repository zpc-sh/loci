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

///|
test "directive lowering emits solver receipt only when solver and job exist" {
  let no_solver = @chatgpt.ContractDirectiveMini::new(
    "H-no-solver", "pattern.none", "no solver path", false, "test.none",
  )
  @test.assert_eq(
    no_solver.to_solver_receipt(
      Some("loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon"),
    ),
    None,
  )

  let with_solver = @chatgpt.ContractDirectiveMini::new(
    "H-with-solver",
    "pattern.solve",
    "solver path",
    true,
    "test.solve",
    solver=Some("z3"),
    solver_job=Some("solve-job-004"),
    solver_status=@chatgpt.Completed,
    solver_receipt=Some("loci/chatgpt/proofs/solve-job-004.receipt.muon"),
  )
  assert_true(with_solver.to_solver_receipt(None) is Some(_))
}

///|
test "directive ready gate enforces solver completion when solver is requested" {
  let running = @chatgpt.ContractDirectiveMini::new(
    "H-ready-gate-running",
    "pattern.ready",
    "ready with solver",
    true,
    "test.ready",
    solver=Some("z3"),
    solver_job=Some("solve-job-005"),
    solver_status=@chatgpt.Running,
    solver_receipt=Some("loci/chatgpt/proofs/solve-job-005.receipt.muon"),
  )
  assert_true(!running.ready_gate())

  let completed = @chatgpt.ContractDirectiveMini::new(
    "H-ready-gate-completed",
    "pattern.ready",
    "ready with solver",
    true,
    "test.ready",
    solver=Some("z3"),
    solver_job=Some("solve-job-006"),
    solver_status=@chatgpt.Completed,
    solver_receipt=Some("loci/chatgpt/proofs/solve-job-006.receipt.muon"),
  )
  assert_true(completed.ready_gate())
}

///|
test "directive parser lowers raw lines into typed mini contract" {
  let parsed = @chatgpt.ContractDirectiveMini::from_directive_lines([
    "@contract H-parser-lowering", "@pattern solver.receipt.binding", "@claim parser macro prepass lowering",
    "@ready true", "@oracle test.chatgpt.directive-parser", "@solver z3", "@solver_job solve-job-007",
    "@solver_status completed", "@solver_receipt loci/chatgpt/proofs/solve-job-007.receipt.muon",
  ])
  match parsed {
    Some(mini) => {
      @test.assert_eq(mini.contract_id, "H-parser-lowering")
      @test.assert_eq(mini.pattern, "solver.receipt.binding")
      @test.assert_eq(mini.solver_status, @chatgpt.Completed)
      @test.assert_eq(mini.solver, Some("z3"))
      assert_true(mini.ready_gate())
    }
    None => assert_true(false)
  }
}

///|
test "directive parser returns none when required fields are missing" {
  let missing_contract = @chatgpt.ContractDirectiveMini::from_directive_lines([
    "@pattern solver.receipt.binding", "@claim parser macro prepass lowering", "@ready true",
    "@oracle test.chatgpt.directive-parser",
  ])
  @test.assert_eq(missing_contract, None)
}

///|
test "solver handler ingests directive payload into dropbox and kv" {
  let obligations = [
    @chatgpt.ProofObligation::new(
      "obl-covered",
      true,
      @chatgpt.CoveredByEvidence,
    ),
  ]
  let binding = @chatgpt.ContractBinding::new(
    "H-solver-http-ingest",
    Some("loci/chatgpt/tests/chatgpt-contracts.results.muon"),
    Some("loci/chatgpt/coverage/chatgpt-contracts.coverage.muon"),
    Some("loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon"),
    @chatgpt.Covered,
    @chatgpt.Observed,
    obligations,
  )
  let handler = @chatgpt.SolverResultHandler::new()
  let (next, result) = handler.ingest_http_directive_lines(binding, [
    "@contract H-solver-http-ingest", "@pattern solver.receipt.binding", "@claim receipt callback",
    "@ready true", "@oracle test.chatgpt.solver-handler", "@solver z3", "@solver_job solve-job-http-001",
    "@solver_status completed", "@solver_receipt loci/chatgpt/proofs/solve-job-http-001.receipt.muon",
  ])
  assert_true(result.accepted)
  assert_true(result.can_seal_now)
  @test.assert_eq(next.dropbox_count(), 1)
  @test.assert_eq(next.kv_count(), 1)
  assert_true(next.kv_get("solve-job-http-001") is Some(_))
}

///|
test "solver handler rejects contract mismatch" {
  let obligations = [
    @chatgpt.ProofObligation::new(
      "obl-covered",
      true,
      @chatgpt.CoveredByEvidence,
    ),
  ]
  let binding = @chatgpt.ContractBinding::new(
    "H-binding-contract",
    Some("loci/chatgpt/tests/chatgpt-contracts.results.muon"),
    Some("loci/chatgpt/coverage/chatgpt-contracts.coverage.muon"),
    Some("loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon"),
    @chatgpt.Covered,
    @chatgpt.Observed,
    obligations,
  )
  let handler = @chatgpt.SolverResultHandler::new()
  let receipt = @chatgpt.SolverReceipt::new(
    "z3",
    "solve-job-http-002",
    @chatgpt.Completed,
    Some("loci/chatgpt/proofs/solve-job-http-002.receipt.muon"),
    Some("loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon"),
  )
  let (next, result) = handler.ingest(
    binding,
    "H-other-contract",
    receipt,
    route=@chatgpt.DropboxAndKv,
  )
  assert_true(!result.accepted)
  @test.assert_eq(next.dropbox_count(), 0)
  @test.assert_eq(next.kv_count(), 0)
}

///|
test "solver handler ingests external client result" {
  let obligations = [
    @chatgpt.ProofObligation::new(
      "obl-covered",
      true,
      @chatgpt.CoveredByEvidence,
    ),
  ]
  let binding = @chatgpt.ContractBinding::new(
    "H-koan-client-ingest",
    Some("loci/chatgpt/tests/chatgpt-contracts.results.muon"),
    Some("loci/chatgpt/coverage/chatgpt-contracts.coverage.muon"),
    Some("loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon"),
    @chatgpt.Covered,
    @chatgpt.Observed,
    obligations,
  )
  let client_result = @chatgpt.SolverClientResult::new(
    "H-koan-client-ingest",
    "koan",
    "solve-job-koan-001",
    @chatgpt.Completed,
    Some("loci/chatgpt/proofs/solve-job-koan-001.receipt.muon"),
    Some("loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon"),
  )
  let handler = @chatgpt.SolverResultHandler::new()
  let (next, result) = handler.ingest_client_result(
    binding,
    client_result,
    route=@chatgpt.KvOnly,
  )
  assert_true(result.accepted)
  assert_true(result.can_seal_now)
  @test.assert_eq(next.dropbox_count(), 0)
  @test.assert_eq(next.kv_count(), 1)
  assert_true(next.kv_get("solve-job-koan-001") is Some(_))
}

///|
test "koan payload adapter builds solver client result" {
  let payload = [
    ("contract_id", "H-koan-adapter"),
    ("solver", "koan"),
    ("solver_job", "solve-job-koan-002"),
    ("solver_status", "completed"),
    (
      "solver_receipt_ref", "loci/chatgpt/proofs/solve-job-koan-002.receipt.muon",
    ),
    (
      "proof_artifact_ref", "loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon",
    ),
  ]
  let parsed = @chatgpt.SolverClientResult::from_koan_payload(payload)
  match parsed {
    Some(v) => {
      @test.assert_eq(v.contract_id, "H-koan-adapter")
      @test.assert_eq(v.solver_job, "solve-job-koan-002")
      @test.assert_eq(v.solver_status, @chatgpt.Completed)
    }
    None => assert_true(false)
  }
}

///|
test "koan payload ingestion rejects malformed payload" {
  let obligations = [
    @chatgpt.ProofObligation::new(
      "obl-covered",
      true,
      @chatgpt.CoveredByEvidence,
    ),
  ]
  let binding = @chatgpt.ContractBinding::new(
    "H-koan-adapter-ingest",
    Some("loci/chatgpt/tests/chatgpt-contracts.results.muon"),
    Some("loci/chatgpt/coverage/chatgpt-contracts.coverage.muon"),
    Some("loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon"),
    @chatgpt.Covered,
    @chatgpt.Observed,
    obligations,
  )
  let handler = @chatgpt.SolverResultHandler::new()
  let (next, result) = handler.ingest_koan_payload(binding, [
    ("solver", "koan"),
    ("solver_job", "solve-job-koan-003"),
  ])
  assert_true(!result.accepted)
  @test.assert_eq(result.reason, Some("invalid_koan_client_payload"))
  @test.assert_eq(next.kv_count(), 0)
}
