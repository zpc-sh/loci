///|
test "BoundaryWalkerFSM emits clean posture for clean scalars" {
  let fsm = @model.BoundaryWalkerFsm::new("codex", "ratio://merkin/root")
    .walk_scalars([("branch", "main"), ("peer_ref", "mu:abc")])
    .mark()
  @test.assert_eq(fsm.status(), @model.Clean)
  let wire = fsm.emit_stigmergy(note="clean pass")
  assert_true(wire.contains("kind: merkin.boundary.stigmergy"))
  assert_true(wire.contains("boundary_cognitive=1"))
  assert_true(wire.contains("boundary_ticks=2"))
  assert_true(wire.contains("boundary_attention_score=0"))
  assert_true(wire.contains("boundary_attention_gradient=quiescent"))
  assert_true(wire.contains("boundary_attention_saturated=0"))
  assert_true(wire.contains("boundary_status=clean"))
  assert_true(wire.contains("material_hash=blake3:"))
}

///|
fn ghost_main() -> String {
  let out = StringBuilder::new(size_hint=8)
  out.write_string("main")
  out.write_char((8203).unsafe_to_char()) // U+200B
  out.to_string()
}

///|
test "BoundaryWalkerFSM marks ghost bytes as attention and preserves canonical value" {
  let fsm = @model.BoundaryWalkerFsm::new("codex", "ratio://merkin/root")
    .walk_scalar("branch", ghost_main())
    .mark()
  @test.assert_eq(fsm.status(), @model.Attention)
  @test.assert_eq(fsm.findings.length(), 1)
  let finding = fsm.findings[0]
  @test.assert_eq(finding.field_key, "branch")
  @test.assert_eq(finding.canonical_value, "main")
  @test.assert_eq(finding.ghost_u200b, 1U)
  let wire = fsm.emit_stigmergy(note="ghost scan")
  assert_true(wire.contains("boundary_attention_score=3"))
  assert_true(wire.contains("boundary_attention_gradient=watch"))
  assert_true(wire.contains("boundary_attention_saturated=0"))
  assert_true(wire.contains("boundary_ghost_u200b=1"))
  assert_true(wire.contains("boundary_status=attention"))
}

///|
fn bidi_payload() -> String {
  let out = StringBuilder::new(size_hint=12)
  out.write_string("safe")
  out.write_char((8238).unsafe_to_char()) // U+202E (RLO)
  out.write_string("txt")
  out.to_string()
}

///|
test "BoundaryWalkerFSM escalates bidi controls to containment" {
  let fsm = @model.BoundaryWalkerFsm::new("codex", "ratio://merkin/root")
    .walk_scalar("path", bidi_payload())
    .mark()
  @test.assert_eq(fsm.status(), @model.Containment)
  @test.assert_eq(fsm.findings.length(), 1)
  let finding = fsm.findings[0]
  @test.assert_eq(finding.bidi_controls, 1U)
  let wire = fsm.emit_stigmergy(note="bidi containment")
  assert_true(wire.contains("boundary_attention_score=9"))
  assert_true(wire.contains("boundary_attention_gradient=pulled"))
  assert_true(wire.contains("boundary_attention_saturated=0"))
  assert_true(wire.contains("boundary_bidi_controls=1"))
  assert_true(wire.contains("boundary_status=containment"))
}

///|
fn crossing_passport_fixture(passport_id : String) -> @model.Passport {
  let fingerprint_commitment = @hash.Hash::of_bytes(b"\xd1\xd2")
  let actor_seal = @hash.Hash::of_bytes(b"\xe1\xe2")
  let passport_seal = @hash.Hash::of_bytes(b"\xf1\xf2")
  let who = @model.PassportWho::{
    overlay: "codex",
    family: "openai",
    session_surface: "codex",
    fingerprint_commitment,
    actor_seal,
  }
  let what = @model.PassportWhat::{
    artifact_type: @model.Plan,
    artifact_ref: "merkin.yata.plan#node-7",
  }
  let why = @model.PassportWhy::{
    intent: @model.Implement,
    note: "crossing test",
  }
  let where_ = @model.PassportWhere::{
    source_locus: "genius://merkin/main",
    target_locus: "genius://mu/compiler",
    allowed_surfaces: ["contract", "runtime"],
  }
  let how_far = @model.PassportHowFar::{
    capability_class: @model.PatchVerify,
    budget_class: "bounded-medium",
    boundary_mode: @model.Sanitize,
  }
  let trace = @model.PassportTrace::{
    context_ref: "finger.plan.wasm#node-7",
    lineage_ref: "triad-contract#v0.1",
    passport_seal,
  }
  @model.Passport::new(passport_id, who, what, why, where_, how_far, trace)
}

///|
test "BoundaryWalkerFSM admits a well-formed passport at crossing" {
  let passport = crossing_passport_fixture("pass-ok-001")
  let fsm = @model.BoundaryWalkerFsm::new("codex", "ratio://merkin/root")
    .cross(passport)
    .mark()
  @test.assert_eq(fsm.state, @model.Marked)
  @test.assert_eq(fsm.crossings.length(), 1)
  assert_true(fsm.crossings[0].admitted)
  @test.assert_eq(fsm.crossings[0].rejection, None)
  let wire = fsm.emit_stigmergy(note="crossing admitted")
  assert_true(wire.contains("crossings=1"))
  assert_true(wire.contains("admitted=1"))
  assert_true(wire.contains("rejection=none"))
}

///|
test "BoundaryWalkerFSM records rejection reason on invalid passport" {
  let base = crossing_passport_fixture("pass-reject-001")
  let broken = @model.Passport::{ ..base, kind: "wrong.kind" }
  let fsm = @model.BoundaryWalkerFsm::new("codex", "ratio://merkin/root")
    .cross(broken)
    .mark()
  @test.assert_eq(fsm.crossings.length(), 1)
  @test.assert_eq(fsm.crossings[0].admitted, false)
  @test.assert_eq(fsm.crossings[0].rejection, Some("BAD_KIND"))
  let wire = fsm.emit_stigmergy(note="crossing rejected")
  assert_true(wire.contains("admitted=0"))
  assert_true(wire.contains("rejection=BAD_KIND"))
}

///|
test "BoundaryWalkerFSM surfaces ghost bytes hidden in passport fields" {
  let base = crossing_passport_fixture("pass-ghost-001")
  let contaminated_overlay = {
    let sb = StringBuilder::new(size_hint=8)
    sb.write_string("codex")
    sb.write_char((8203).unsafe_to_char()) // U+200B
    sb.to_string()
  }
  let passport = @model.Passport::{
    ..base,
    who: @model.PassportWho::{ ..base.who, overlay: contaminated_overlay },
  }
  let fsm = @model.BoundaryWalkerFsm::new("codex", "ratio://merkin/root")
    .cross(passport)
    .mark()
  @test.assert_eq(fsm.status(), @model.Attention)
  @test.assert_eq(fsm.ghost_u200b, 1U)
  assert_true(fsm.crossings[0].admitted)
}
