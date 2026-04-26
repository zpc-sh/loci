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
