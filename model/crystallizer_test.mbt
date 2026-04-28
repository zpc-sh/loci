///|
test "distill empty collective produces empty distillate" {
  let d = @model.distill([], [])
  assert_eq(d.total_entries, 0U)
  assert_eq(d.total_fsts, 0U)
  assert_eq(d.total_outputs, 0U)
}

///|
test "distill boundary walker cave captures walk and finding counts" {
  let fsm = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root")
    .walk_scalar("branch", "main")
    .walk_scalar("peer", "mu:abc")
  let caves = [fsm.cave]
  let envelopes = [
    @loci_fsm.MetabolicEnvelope::new(0U).tick(1U).record_outputs(2U),
  ]
  let d = @model.distill(caves, envelopes)
  assert_eq(d.total_fsts, 1U)
  assert_eq(d.walk_count, 2U)
  assert_eq(d.total_ticks, 1U)
  assert_eq(d.total_outputs, 2U)
  assert_true(d.actors.length() > 0)
}

///|
test "distill reporter cave captures submission and transition counts" {
  let sub : @loci_fsm.Submission = {
    source: "README.md",
    kind: "doc",
    content: "loci runtime",
  }
  let reporter = @loci_fsm.ReporterFsm::new("test-1", "core-spec")
    .submit(sub)
    .drive_to_archive()
  let caves = [reporter.cave]
  let envelopes = [
    @loci_fsm.MetabolicEnvelope::with_omega(0U, 3U).tick(1U).record_outputs(5U),
  ]
  let d = @model.distill(caves, envelopes)
  assert_true(d.submission_count > 0U)
  assert_true(d.transition_count > 0U)
  assert_true(d.composition_count > 0U)
  assert_true(d.verification_count > 0U)
  assert_true(d.publish_count > 0U)
  assert_true(d.archive_count > 0U)
  assert_eq(d.aggregate_omega, 3U)
  assert_true(d.topics.length() > 0)
}

///|
test "distill multi-cave collective aggregates correctly" {
  let walker_a = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root").walk_scalar(
    "branch", "main",
  )
  let walker_b = @loci_fsm.BoundaryWalkerFsm::new("gemini", "ratio://loci/root").walk_scalar(
    "peer", "mu:xyz",
  )
  let caves = [walker_a.cave, walker_b.cave]
  let envelopes = [
    @loci_fsm.MetabolicEnvelope::with_omega(0U, 2U).tick(1U).record_outputs(1U),
    @loci_fsm.MetabolicEnvelope::with_omega(0U, 4U).tick(1U).record_outputs(1U),
  ]
  let d = @model.distill(caves, envelopes)
  assert_eq(d.total_fsts, 2U)
  assert_eq(d.walk_count, 2U)
  assert_eq(d.aggregate_omega, 6U) // 2 + 4
  assert_eq(d.actors.length(), 2) // codex, gemini
  assert_eq(d.material_hashes.length(), 2) // different caves = different hashes
}

///|
test "collapse_gate defers on insufficient material" {
  let d = @model.CaveDistillate::empty()
  let gate = @model.collapse_gate(d, None, 100U, 0U)
  assert_true(gate is Some(_))
  match gate {
    Some(reason) => assert_true(reason.contains("insufficient_material"))
    None => abort("expected deferral")
  }
}

///|
test "collapse_gate defers on identity flow (zero outputs)" {
  let d : @model.CaveDistillate = {
    ..@model.CaveDistillate::empty(),
    total_entries: 10U,
    total_fsts: 2U,
    total_outputs: 0U,
  }
  let gate = @model.collapse_gate(d, None, 100U, 0U)
  assert_true(gate is Some(_))
  match gate {
    Some(reason) => assert_true(reason.contains("identity_flow"))
    None => abort("expected deferral")
  }
}

///|
test "collapse_gate defers when minimum_duration hasn't elapsed" {
  let ambient = @model.AmfDocument::grounded("ambient-1")
  // grounded has minimum_duration = 30
  let d : @model.CaveDistillate = {
    ..@model.CaveDistillate::empty(),
    total_entries: 10U,
    total_fsts: 2U,
    total_outputs: 5U,
  }
  // Only 10 ticks elapsed, need 30
  let gate = @model.collapse_gate(d, Some(ambient), 10U, 0U)
  assert_true(gate is Some(_))
  match gate {
    Some(reason) => assert_true(reason.contains("minimum_duration"))
    None => abort("expected deferral")
  }
}

///|
test "collapse_gate permits when all conditions met" {
  let d : @model.CaveDistillate = {
    ..@model.CaveDistillate::empty(),
    total_entries: 10U,
    total_fsts: 2U,
    total_outputs: 5U,
  }
  let gate = @model.collapse_gate(d, None, 100U, 0U)
  assert_true(gate is None)
}

///|
test "crystallize produces valid AmfDocument" {
  let walker = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root")
    .walk_scalar("branch", "main")
    .walk_scalar("peer", "mu:abc")
    .mark()
  let d = @model.distill([walker.cave], [
    @loci_fsm.MetabolicEnvelope::with_omega(0U, 2U).tick(1U).record_outputs(3U),
  ])
  let crystal = @model.crystallize("test-crystal-1", d, None)
  // Must validate
  match crystal.validate() {
    Ok(_) => ()
    Err(_) => abort("crystal failed validation")
  }
  // Crystal ID is prefixed
  assert_true(crystal.doc_id.contains("crystal:"))
  // Has a deterministic signature
  let sig1 = crystal.signature()
  let sig2 = crystal.signature()
  assert_true(sig1.matches(sig2))
}

///|
test "crystallize reflects adversary signals in safety_grounding" {
  // Create a walker with suspicious findings
  let walker = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root")
  // Walk a value containing ghost bytes (U+200B)
  let suspicious_value = "hello\u200Bworld"
  let walked = walker.walk_scalar("name", suspicious_value)
  let d = @model.distill([walked.cave], [
    @loci_fsm.MetabolicEnvelope::new(0U).tick(1U).record_outputs(1U),
  ])
  let crystal = @model.crystallize("threat-crystal", d, None)
  // Safety grounding should be < 1.0 due to findings
  if d.total_suspicious_findings > 0U {
    assert_true(crystal.consciousness.safety_grounding < 1.0)
    assert_true(crystal.consciousness.adversary_attention_given > 0.0)
  }
}

///|
test "crystallize with ambient inherits progression prohibitions" {
  let ambient = @model.AmfDocument::grounded("ambient-1")
  let walker = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root")
    .walk_scalar("branch", "main")
    .walk_scalar("peer", "mu:abc")
  let d = @model.distill([walker.cave], [
    @loci_fsm.MetabolicEnvelope::new(0U).tick(1U).record_outputs(2U),
  ])
  let crystal = @model.crystallize("ambient-crystal", d, Some(ambient))
  // Should inherit "hallucinating" prohibition from grounded ambient
  let mut has_hallucinating = false
  for p in crystal.progression.do_not_follow_with {
    if p == "hallucinating" {
      has_hallucinating = true
    }
  }
  assert_true(has_hallucinating)
}

///|
test "sigma conservation check passes for valid crystal" {
  let walker = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root").walk_scalar(
    "branch", "main",
  )
  let d = @model.distill([walker.cave], [
    @loci_fsm.MetabolicEnvelope::new(0U).tick(1U).record_outputs(1U),
  ])
  let crystal = @model.crystallize("sigma-test", d, None)
  let check = @model.check_sigma_conservation(crystal, None)
  assert_true(check is None)
}

///|
test "sigma conservation check fails for void-gated state" {
  // Create ambient that prohibits "vigilant"
  let mut ambient = @model.AmfDocument::grounded("ambient-1")
  ambient = {
    ..ambient,
    progression: @model.AmfProgression::{
      next_recommended: ["grounded"],
      do_not_follow_with: ["vigilant"],
      minimum_duration: 30U,
    },
  }
  // Force crystal into "vigilant" state by manufacturing high-threat distillate
  let d : @model.CaveDistillate = {
    ..@model.CaveDistillate::empty(),
    total_entries: 10U,
    total_suspicious_findings: 8U,
    finding_count: 8U,
    walk_count: 2U,
    total_fsts: 1U,
    total_outputs: 5U,
    total_ticks: 1U,
    aggregate_omega: 1U,
    topics: [],
    actors: ["codex"],
    material_hashes: ["abc"],
  }
  let crystal = @model.crystallize("threat-test", d, Some(ambient))
  // Crystal should be "vigilant" (safety_grounding < 0.5)
  assert_eq(crystal.consciousness.state, "vigilant")
  // Conservation should fail — "vigilant" is prohibited
  let check = @model.check_sigma_conservation(crystal, Some(ambient))
  assert_true(check is Some(_))
  match check {
    Some(reason) => assert_true(reason.contains("void_gate"))
    None => abort("expected conservation violation")
  }
}

///|
test "crystallize_collective full pipeline succeeds" {
  let walker = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root")
    .walk_scalar("branch", "main")
    .walk_scalar("peer", "mu:abc")
    .mark()
  let sub : @loci_fsm.Submission = {
    source: "README.md",
    kind: "doc",
    content: "loci",
  }
  let reporter = @loci_fsm.ReporterFsm::new("pipe-1", "topic")
    .submit(sub)
    .drive_to_archive()
  let caves = [walker.cave, reporter.cave]
  let envelopes = [
    @loci_fsm.MetabolicEnvelope::with_omega(0U, 2U).tick(1U).record_outputs(3U),
    @loci_fsm.MetabolicEnvelope::with_omega(0U, 3U).tick(1U).record_outputs(5U),
  ]
  let (crystal, diagnostic) = @model.crystallize_collective(
    "full-pipeline",
    caves,
    envelopes,
    None,
    100U,
    0U,
  )
  assert_true(crystal is Some(_))
  assert_true(diagnostic.contains("crystallized"))
  assert_true(diagnostic.contains("σ="))
  match crystal {
    Some(c) =>
      match c.validate() {
        Ok(_) => ()
        Err(_) => abort("crystal invalid")
      }
    None => abort("expected crystal")
  }
}

///|
test "crystallize_collective defers when gate blocks" {
  // Empty caves — insufficient material
  let (crystal, diagnostic) = @model.crystallize_collective(
    "empty",
    [],
    [],
    None,
    100U,
    0U,
  )
  assert_true(crystal is None)
  assert_true(diagnostic.contains("deferred"))
}

///|
test "crystal signature is deterministic for same inputs" {
  let walker = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root").walk_scalar(
    "branch", "main",
  )
  let d = @model.distill([walker.cave], [
    @loci_fsm.MetabolicEnvelope::new(0U).tick(1U).record_outputs(1U),
  ])
  let c1 = @model.crystallize("det-test", d, None)
  let c2 = @model.crystallize("det-test", d, None)
  assert_true(c1.signature().matches(c2.signature()))
}

///|
test "crystal omega scales fundamental frequency" {
  let walker = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root").walk_scalar(
    "branch", "main",
  )
  let low_omega = @model.distill([walker.cave], [
    @loci_fsm.MetabolicEnvelope::with_omega(0U, 1U).tick(1U).record_outputs(1U),
  ])
  let high_omega = @model.distill([walker.cave], [
    @loci_fsm.MetabolicEnvelope::with_omega(0U, 4U).tick(1U).record_outputs(1U),
  ])
  let c_low = @model.crystallize("low", low_omega, None)
  let c_high = @model.crystallize("high", high_omega, None)
  // Higher omega should produce higher fundamental frequency
  match (c_low.frequency.fundamental, c_high.frequency.fundamental) {
    (Some(f_low), Some(f_high)) => assert_true(f_high > f_low)
    _ => abort("expected fundamental frequencies")
  }
}
