///|
test "cycle closure is true after full round-trip" {
  let cycle = @chatgpt.WorkCycle::new().advance().advance().advance().advance()
  assert_eq(cycle.stage, @chatgpt.Form)
  assert_true(cycle.is_cycle_closed())
  assert_eq(cycle.history.length(), 5)
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
