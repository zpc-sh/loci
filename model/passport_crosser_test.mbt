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
test "Passport implements Crosser: admits a well-formed passport at crossing" {
  let passport = crossing_passport_fixture("pass-ok-001")
  let fsm = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://merkin/root")
    .cross(passport as &@loci_fsm.Crosser)
    .mark()
  assert_eq(fsm.state, @loci_fsm.Marked)
  assert_eq(fsm.crossings.length(), 1)
  assert_true(fsm.crossings[0].admitted)
  assert_true(fsm.crossings[0].rejection is None)
  let wire = fsm.emit_stigmergy(note="crossing admitted")
  assert_true(wire.contains("crossings=1"))
  assert_true(wire.contains("admitted=1"))
  assert_true(wire.contains("rejection=none"))
}

///|
test "Passport implements Crosser: records BAD_KIND on broken passport" {
  let base = crossing_passport_fixture("pass-reject-001")
  let broken = @model.Passport::{ ..base, kind: "wrong.kind" }
  let fsm = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://merkin/root")
    .cross(broken as &@loci_fsm.Crosser)
    .mark()
  assert_eq(fsm.crossings.length(), 1)
  assert_eq(fsm.crossings[0].admitted, false)
  assert_true(fsm.crossings[0].rejection == Some("BAD_KIND"))
  let wire = fsm.emit_stigmergy(note="crossing rejected")
  assert_true(wire.contains("admitted=0"))
  assert_true(wire.contains("rejection=BAD_KIND"))
}

///|
test "Passport implements Crosser: surfaces ghost bytes hidden in passport fields" {
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
  let fsm = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://merkin/root")
    .cross(passport as &@loci_fsm.Crosser)
    .mark()
  assert_eq(fsm.status(), @loci_fsm.Attention)
  assert_eq(fsm.ghost_u200b, 1U)
  assert_true(fsm.crossings[0].admitted)
}
