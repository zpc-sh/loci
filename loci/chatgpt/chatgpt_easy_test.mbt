///|
test "work cycle begins at form and advances to fruition" {
  let cycle = @chatgpt.WorkCycle::new().advance()
  assert_eq(cycle.stage, @chatgpt.Fruition)
  assert_eq(cycle.history, [@chatgpt.Form, @chatgpt.Fruition])
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
