///|
test "work cycle begins at form and advances to fruition" {
  let cycle = @chatgpt.WorkCycle::new().advance()
  @test.assert_eq(cycle.stage, @chatgpt.Fruition)
  @test.assert_eq(cycle.history, [@chatgpt.Form, @chatgpt.Fruition])
}

///|
test "local crossing can be complete without seal" {
  let record = @chatgpt.CrossingRecord::new(
    "loci/chatgpt",
    "docs",
    "docs/new/rfc-3027-loci.md",
    "lower profile into canonical docs",
    @chatgpt.Local,
  )
  assert_true(record.is_complete())
}

///|
test "proof obligation discharged statuses are accepted" {
  let proved = @chatgpt.ProofObligation::new("obl-1", true, @chatgpt.Proved)
  let reviewed = @chatgpt.ProofObligation::new("obl-2", true, @chatgpt.Reviewed)
  assert_true(proved.is_discharged())
  assert_true(reviewed.is_discharged())
}

///|
test "module component plan is extract-ready when scoped and complete" {
  let plan = @chatgpt.ModuleComponentPlan::new(
    "ide.socket.bridge",
    "H-loci-ide-socket",
    ["cli/src/commands/ide.ts", "loci/chatgpt/LOCI_IDE_SOCKET_DOGFOOD.md"],
    "zpc/genius/loci/chatgpt/componentization",
    "loci/chatgpt/chatgpt_spec.mbt",
    ["loci/chatgpt/chatgpt_mid_test.mbt"],
    status=@chatgpt.Scoped,
  )
  assert_true(plan.is_ready_for_extract())
}
