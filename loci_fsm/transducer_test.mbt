///|
test "BoundaryWalkerFsm transduce Scalar produces cave outputs and advances state" {
  let fsm = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root")
  assert_eq(fsm.state_tag(), "idle")
  let (next, outputs) = fsm.transduce(@loci_fsm.Scalar("branch", "main"))
  assert_eq(next.state_tag(), "walking")
  assert_eq(next.accepting(), false)
  assert_true(outputs.length() > 0)
  // Every output from a scalar walk should be a CaveDeposit
  let mut cave_count = 0
  for out in outputs {
    match out {
      CaveDeposit(_) => cave_count = cave_count + 1
      _ => ()
    }
  }
  assert_true(cave_count > 0)
}

///|
test "BoundaryWalkerFsm transduce Event mark transitions to marked" {
  let fsm = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root")
  let (walked, _) = fsm.transduce(@loci_fsm.Scalar("a", "alpha"))
  let (marked, _) = walked.transduce(@loci_fsm.Event("mark"))
  assert_eq(marked.state_tag(), "marked")
}

///|
test "BoundaryWalkerFsm transduce Event emit_stigmergy produces Emission output" {
  let fsm = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root")
  let (walked, _) = fsm.transduce(@loci_fsm.Scalar("branch", "main"))
  let (marked, _) = walked.transduce(@loci_fsm.Event("mark"))
  let (_, outputs) = marked.transduce(@loci_fsm.Event("emit_stigmergy"))
  let mut saw_emission = false
  for out in outputs {
    match out {
      Emission(wire) => {
        assert_true(wire.contains("kind: merkin.boundary.stigmergy"))
        saw_emission = true
      }
      _ => ()
    }
  }
  assert_true(saw_emission)
}

///|
test "BoundaryWalkerFsm transduce_batch walks multiple scalars" {
  let fsm = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root")
  let inputs : Array[@loci_fsm.TransducerInput] = [
    Scalar("branch", "main"),
    Scalar("peer_ref", "mu:abc"),
    Event("mark"),
  ]
  let (next, outputs) = @loci_fsm.transduce_batch(fsm, inputs)
  assert_eq(next.state_tag(), "marked")
  // Should have cave deposits from 2 walks + 1 mark
  assert_true(outputs.length() >= 3)
}

///|
test "BoundaryWalkerFsm transducer cave outputs match direct FSM cave entries" {
  // Prove the transducer wrapper produces identical cave data to direct calls.
  let actor = "codex"
  let loci = "ratio://loci/root"
  let key = "branch"
  let value = "main"

  // Direct FSM path
  let direct = @loci_fsm.BoundaryWalkerFsm::new(actor, loci)
    .walk_scalar(key, value)
    .mark()
  let direct_entries = direct.cave.snapshot()

  // Transducer path
  let fst = @loci_fsm.BoundaryWalkerFsm::new(actor, loci)
  let (fst_walked, _) = fst.transduce(@loci_fsm.Scalar(key, value))
  let (fst_marked, _) = fst_walked.transduce(@loci_fsm.Event("mark"))
  let fst_entries = fst_marked.cave.snapshot()

  // Same number of cave entries
  assert_eq(direct_entries.length(), fst_entries.length())
  // Same state
  assert_eq(direct.state, fst_marked.state)
  // Same material hash (deterministic)
  assert_eq(direct.cave.material_hash(), fst_marked.cave.material_hash())
}

///|
test "BoundaryWalkerFsm personality_name returns boundary-walker" {
  let fsm = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root")
  assert_eq(fsm.personality_name(), "boundary-walker")
}

///|
test "ReporterFsm transduce SubmitWork deposits submission" {
  let r = @loci_fsm.ReporterFsm::new("fst-1", "core-spec")
  let sub : @loci_fsm.Submission = {
    source: "README.md",
    kind: "doc",
    content: "loci runtime",
  }
  let (next, outputs) = r.transduce(@loci_fsm.SubmitWork(sub))
  assert_eq(next.state_tag(), "idle") // submit doesn't change state
  assert_true(outputs.length() > 0)
  let mut saw_submission = false
  for out in outputs {
    match out {
      CaveDeposit(e) => if e.kind == "submission" { saw_submission = true }
      _ => ()
    }
  }
  assert_true(saw_submission)
}

///|
test "ReporterFsm transduce Tick advances from idle to observe" {
  let r = @loci_fsm.ReporterFsm::new("fst-2", "topic")
  let sub : @loci_fsm.Submission = {
    source: "a.md",
    kind: "doc",
    content: "alpha",
  }
  let (with_sub, _) = r.transduce(@loci_fsm.SubmitWork(sub))
  let (ticked, _) = with_sub.transduce(@loci_fsm.Tick)
  assert_eq(ticked.state_tag(), "observe")
}

///|
test "ReporterFsm transduce Event drive_to_archive runs full lifecycle" {
  let r = @loci_fsm.ReporterFsm::new("fst-3", "core-spec")
  let sub : @loci_fsm.Submission = {
    source: "README.md",
    kind: "doc",
    content: "loci runtime",
  }
  let (with_sub, _) = r.transduce(@loci_fsm.SubmitWork(sub))
  let (archived, outputs) = with_sub.transduce(
    @loci_fsm.Event("drive_to_archive"),
  )
  assert_eq(archived.state_tag(), "archive")
  assert_true(archived.accepting())
  // Should include an Emission (summary wire) among outputs
  let mut saw_emission = false
  for out in outputs {
    match out {
      Emission(wire) => {
        assert_true(wire.contains("kind: loci.reporter.summary"))
        saw_emission = true
      }
      _ => ()
    }
  }
  assert_true(saw_emission)
}

///|
test "ReporterFsm transducer cave outputs match direct FSM cave entries" {
  let sub : @loci_fsm.Submission = {
    source: "README.md",
    kind: "doc",
    content: "loci runtime",
  }

  // Direct FSM path
  let direct = @loci_fsm.ReporterFsm::new("match-1", "topic")
    .submit(sub)
    .drive_to_archive()
  let direct_hash = direct.cave.material_hash()

  // Transducer path
  let fst = @loci_fsm.ReporterFsm::new("match-1", "topic")
  let (with_sub, _) = fst.transduce(@loci_fsm.SubmitWork(sub))
  let (archived, _) = with_sub.transduce(@loci_fsm.Event("drive_to_archive"))
  let fst_hash = archived.cave.material_hash()

  // Same final state
  assert_eq(direct.state, archived.state)
  // Same cave material hash (deterministic)
  assert_eq(direct_hash, fst_hash)
}

///|
test "ReporterFsm personality_name returns reporter" {
  let r = @loci_fsm.ReporterFsm::new("fst-4", "topic")
  assert_eq(r.personality_name(), "reporter")
}

///|
test "transduce_to_result returns correct TransduceResult" {
  let fsm = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root")
  let (_, result) = @loci_fsm.transduce_to_result(
    fsm,
    @loci_fsm.Scalar("branch", "main"),
  )
  assert_eq(result.state_tag, "walking")
  assert_eq(result.accepting, false)
  assert_true(result.outputs.length() > 0)
}

///|
test "unrecognized TransducerInput is a no-op for both transducers" {
  let bw = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root")
  let sub : @loci_fsm.Submission = { source: "x", kind: "doc", content: "y" }
  let (bw2, bw_out) = bw.transduce(@loci_fsm.SubmitWork(sub))
  assert_eq(bw2.state_tag(), "idle") // SubmitWork is not a boundary input
  assert_eq(bw_out.length(), 0) // no outputs

  let r = @loci_fsm.ReporterFsm::new("fst-5", "topic")
  let (r2, r_out) = r.transduce(@loci_fsm.Scalar("a", "b"))
  assert_eq(r2.state_tag(), "idle") // Scalar is not a reporter input
  assert_eq(r_out.length(), 0)
}
