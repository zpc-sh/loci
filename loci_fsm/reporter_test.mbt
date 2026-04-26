///|
test "ReporterFsm starts in idle with empty cave" {
  let r = @loci_fsm.ReporterFsm::new("docs-1", "core-spec")
  assert_eq(r.state, @loci_fsm.RIdle)
  assert_eq(r.cave.depth(), 0U)
  assert_eq(r.collected.length(), 0)
}

///|
test "ReporterFsm submit + drive_to_archive walks every state and deposits artifacts" {
  let r = @loci_fsm.ReporterFsm::new("docs-1", "core-spec")
    .submit({ source: "README.md", kind: "doc", content: "loci is a runtime" })
    .submit({ source: "AGENTS.md", kind: "doc", content: "agent conventions" })
    .drive_to_archive()
  assert_eq(r.state, @loci_fsm.RArchive)
  assert_true(r.verified)
  assert_true(r.published)
  let kinds = r.cave.snapshot()
  let mut saw_submission = false
  let mut saw_collected = false
  let mut saw_sifted = false
  let mut saw_composition = false
  let mut saw_verification = false
  let mut saw_publish = false
  let mut saw_archive = false
  for e in kinds {
    if e.kind == "submission" {
      saw_submission = true
    }
    if e.kind == "collected" {
      saw_collected = true
    }
    if e.kind == "sifted" {
      saw_sifted = true
    }
    if e.kind == "composition" {
      saw_composition = true
    }
    if e.kind == "verification" {
      saw_verification = true
    }
    if e.kind == "publish" {
      saw_publish = true
    }
    if e.kind == "archive" {
      saw_archive = true
    }
  }
  assert_true(saw_submission)
  assert_true(saw_collected)
  assert_true(saw_sifted)
  assert_true(saw_composition)
  assert_true(saw_verification)
  assert_true(saw_publish)
  assert_true(saw_archive)
}

///|
test "ReporterFsm with no submissions defers from observe" {
  let r = @loci_fsm.ReporterFsm::new("docs-2", "empty").drive_to_archive()
  // No pending → Idle stays Idle (drive breaks early).
  assert_eq(r.state, @loci_fsm.RIdle)
}

///|
test "ReporterFsm rejects unknown event but records it in cave" {
  let r = @loci_fsm.ReporterFsm::new("docs-3", "topic")
    .send(@loci_fsm.VerifyOk) // not legal from RIdle
  assert_eq(r.state, @loci_fsm.RIdle)
  let rejects = r.cave.collect("rejected_event")
  assert_eq(rejects.length(), 1)
  assert_eq(rejects[0].key, "verify_ok")
}

///|
test "ReporterFsm manual_pause from any state goes to defer" {
  let r = @loci_fsm.ReporterFsm::new("docs-4", "topic")
    .submit({ source: "x", kind: "doc", content: "y" })
    .send(@loci_fsm.Tick) // Idle -> Observe
    .send(@loci_fsm.SubmissionReceived) // Observe -> Collect
    .send(@loci_fsm.ManualPause)
  assert_eq(r.state, @loci_fsm.RDefer)
}

///|
test "ReporterFsm cave drain returns every entry and empties cave" {
  let r = @loci_fsm.ReporterFsm::new("docs-5", "core-spec")
    .submit({ source: "a", kind: "doc", content: "alpha" })
    .drive_to_archive()
  let depth_before = r.cave.depth()
  assert_true(depth_before > 0U)
  let (r2, entries) = r.drain()
  assert_eq(entries.length(), depth_before.reinterpret_as_int())
  assert_eq(r2.cave.depth(), 0U)
}

///|
test "reporter_run_wire returns a cave wire with material_hash" {
  let csv = "README.md|doc|loci runtime\nAGENTS.md|doc|conventions"
  let wire = @loci_fsm.reporter_run_wire("collector-1", "core-spec", csv)
  assert_true(wire.contains("kind: loci.fsm.cave"))
  assert_true(wire.contains("personality=reporter-v0"))
  assert_true(wire.contains("material_hash=blake3:"))
  assert_true(wire.contains("kind=submission"))
  assert_true(wire.contains("kind=archive"))
}

///|
test "reporter_summary_wire returns a compact posture line" {
  let csv = "a|doc|alpha"
  let wire = @loci_fsm.reporter_summary_wire("c2", "topic-x", csv)
  assert_true(wire.contains("kind: loci.reporter.summary"))
  assert_true(wire.contains("state=archive"))
  assert_true(wire.contains("verified=1"))
  assert_true(wire.contains("published=1"))
}

///|
test "boundary_walk_wire returns a stigmergy wire" {
  let wire = @loci_fsm.boundary_walk_wire(
    "codex", "ratio://merkin/root", "branch=main,peer=mu:abc", "wasm-walk",
  )
  assert_true(wire.contains("kind: merkin.boundary.stigmergy"))
  assert_true(wire.contains("boundary_ticks=2"))
  assert_true(wire.contains("boundary_status=clean"))
}

///|
test "personality_registry exposes both personas" {
  let reg = @loci_fsm.personality_registry()
  assert_eq(reg.length(), 2)
  let bw = @loci_fsm.personality_by_name("boundary-walker")
  let rep = @loci_fsm.personality_by_name("reporter")
  assert_true(bw is Some(_))
  assert_true(rep is Some(_))
  match bw {
    Some(p) => {
      assert_eq(p.initial_state, "idle")
      assert_true(p.cave_kinds.length() > 0)
    }
    None => abort("missing boundary-walker")
  }
}
