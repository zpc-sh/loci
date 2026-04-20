///|
fn sample_session() -> @model.SessionIdentity {
  @model.SessionIdentity::new("sonnet", "a7f3c")
}

///|
fn sample_residue() -> @model.Residue {
  @model.Residue::new("adversary", "sonnet", "a7f3c", "2026-04-20T00:00:00Z")
    .set_picked_up("haiku-11111-exit.md")
    .add_did("audited path handling")
    .add_left_open("validate formatting")
    .set_recommendation("opus")
}

///|
fn array_contains(items : Array[String], target : String) -> Bool {
  for item in items {
    if item == target {
      return true
    }
  }
  false
}

///|
test "LocusRuntime default config and path helpers" {
  let runtime = @locus.LocusRuntime::default(sample_session())
  assert_eq(runtime.locus_path("adversary"), "loci/adversary")
  assert_eq(runtime.residue_path("adversary"), "loci/adversary/residue")
}

///|
test "LocusRuntime scaffold_paths emits root subdirs and README" {
  let runtime = @locus.LocusRuntime::new(
    { loci_root: "workspaces", store_path: "/tmp/store" },
    sample_session(),
  )
  let paths = runtime.scaffold_paths("adversary")
  assert_eq(paths[0], "workspaces/adversary")
  assert_eq(paths.length(), @model.locus_subdirs().length() + 2)
  assert_true(array_contains(paths, "workspaces/adversary/residue"))
  assert_eq(paths[paths.length() - 1], "workspaces/adversary/README.md")
}

///|
test "LocusRuntime scaffold_readme includes tags only when present" {
  let runtime = @locus.LocusRuntime::default(sample_session())
  let with_tags = runtime.scaffold_readme(
    @model.Locus::with_tags("adversary", "prove safety", ["smt", "proof"]),
  )
  assert_true(with_tags.contains("# adversary"))
  assert_true(with_tags.contains("**Spirit**: prove safety"))
  assert_true(with_tags.contains("**Tags**: smt, proof"))

  let without_tags = runtime.scaffold_readme(
    @model.Locus::new("fresh", "bootstrap"),
  )
  assert_true(!without_tags.contains("**Tags**:"))
}

///|
test "format_where renders populated and empty rows" {
  let residue = sample_residue()
  let out = @locus.format_where([
    ("adversary", Some(residue)),
    ("greenfield", None),
  ])
  assert_true(out.contains("LOCUS           LAST VISIT        TIER    OPEN THREADS"))
  assert_true(out.contains("adversary"))
  assert_true(out.contains("2026-04-20T00:00:00Z"))
  assert_true(out.contains("sonnet"))
  assert_true(out.contains("validate formatting"))
  assert_true(out.contains("greenfield"))
  assert_true(out.contains("(none logged)") || out.contains("—"))
}

///|
test "format_enter_preamble handles first and returning entry" {
  let first = @locus.format_enter_preamble("adversary", None)
  assert_true(first.contains("You are entering: adversary"))
  assert_true(first.contains("First entry — no prior residue."))

  let returning = @locus.format_enter_preamble("adversary", Some(sample_residue()))
  assert_true(returning.contains("Last Claude here: sonnet/a7f3c"))
  assert_true(returning.contains("Open threads from last residue:"))
  assert_true(returning.contains("! validate formatting"))
}

///|
test "format_residue and format_trail include optional fields" {
  let residue = sample_residue()
  let residue_out = @locus.format_residue(residue)
  assert_true(residue_out.contains("residue/sonnet-a7f3c-exit.md"))
  assert_true(residue_out.contains("Picked up from: haiku-11111-exit.md"))
  assert_true(residue_out.contains("- audited path handling"))
  assert_true(residue_out.contains("- validate formatting"))
  assert_true(residue_out.contains("Next Claude: opus"))

  let cold = @model.Residue::new("adversary", "haiku", "11111", "2026-04-19T23:00:00Z")
  let trail = @locus.format_trail("adversary", [residue, cold])
  assert_true(trail.contains("Trail for: adversary  (2 sessions)"))
  assert_true(trail.contains("[2] sonnet/a7f3c"))
  assert_true(trail.contains("[1] haiku/11111"))
  assert_true(trail.contains("Entry context: cold entry (no prior residue)"))
  assert_true(trail.contains("Exit residue: → residue/haiku-11111-exit.md"))
}
