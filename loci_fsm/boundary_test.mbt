///|
test "BoundaryWalkerFSM emits clean posture for clean scalars" {
  let fsm = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://merkin/root")
    .walk_scalars([("branch", "main"), ("peer_ref", "mu:abc")])
    .mark()
  assert_eq(fsm.status(), @loci_fsm.Clean)
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
  let fsm = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://merkin/root")
    .walk_scalar("branch", ghost_main())
    .mark()
  assert_eq(fsm.status(), @loci_fsm.Attention)
  assert_eq(fsm.findings.length(), 1)
  let finding = fsm.findings[0]
  assert_eq(finding.field_key, "branch")
  assert_eq(finding.canonical_value, "main")
  assert_eq(finding.ghost_u200b, 1U)
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
  let fsm = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://merkin/root")
    .walk_scalar("path", bidi_payload())
    .mark()
  assert_eq(fsm.status(), @loci_fsm.Containment)
  assert_eq(fsm.findings.length(), 1)
  let finding = fsm.findings[0]
  assert_eq(finding.bidi_controls, 1U)
  let wire = fsm.emit_stigmergy(note="bidi containment")
  assert_true(wire.contains("boundary_attention_score=9"))
  assert_true(wire.contains("boundary_attention_gradient=pulled"))
  assert_true(wire.contains("boundary_attention_saturated=0"))
  assert_true(wire.contains("boundary_bidi_controls=1"))
  assert_true(wire.contains("boundary_status=containment"))
}

///|
/// Minimal in-package Crosser implementation for the cross() tests so
/// loci_fsm doesn't take a test-only dep on `model`.
struct StubCrosser {
  passport_id : String
  actor_overlay : String
  target_locus : String
  scalars : Array[(String, String)]
  outcome : @loci_fsm.CrossResult
}

///|
impl @loci_fsm.Crosser for StubCrosser with scalars(self : StubCrosser) -> Array[
  (String, String),
] {
  self.scalars
}

///|
impl @loci_fsm.Crosser for StubCrosser with validate(self : StubCrosser) -> @loci_fsm.CrossResult {
  self.outcome
}

///|
impl @loci_fsm.Crosser for StubCrosser with passport_id(self : StubCrosser) -> String {
  self.passport_id
}

///|
impl @loci_fsm.Crosser for StubCrosser with actor_overlay(self : StubCrosser) -> String {
  self.actor_overlay
}

///|
impl @loci_fsm.Crosser for StubCrosser with target_locus(self : StubCrosser) -> String {
  self.target_locus
}

///|
test "BoundaryWalkerFSM admits an admitted Crosser and records the report" {
  let crosser = StubCrosser::{
    passport_id: "pass-ok-001",
    actor_overlay: "codex",
    target_locus: "genius://mu/compiler",
    scalars: [
      ("passport.kind", "locus.crossing.passport"),
      ("passport.passport_id", "pass-ok-001"),
      ("passport.who.overlay", "codex"),
    ],
    outcome: Admitted,
  }
  let fsm = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://merkin/root")
    .cross(crosser as &@loci_fsm.Crosser)
    .mark()
  assert_eq(fsm.state, @loci_fsm.Marked)
  assert_eq(fsm.crossings.length(), 1)
  assert_true(fsm.crossings[0].admitted)
  assert_eq(fsm.crossings[0].rejection, None)
  let wire = fsm.emit_stigmergy(note="crossing admitted")
  assert_true(wire.contains("crossings=1"))
  assert_true(wire.contains("admitted=1"))
  assert_true(wire.contains("rejection=none"))
}

///|
test "BoundaryWalkerFSM records rejection tag from a Rejected Crosser" {
  let crosser = StubCrosser::{
    passport_id: "pass-reject-001",
    actor_overlay: "codex",
    target_locus: "genius://mu/compiler",
    scalars: [("passport.kind", "wrong.kind")],
    outcome: Rejected("BAD_KIND"),
  }
  let fsm = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://merkin/root")
    .cross(crosser as &@loci_fsm.Crosser)
    .mark()
  assert_eq(fsm.crossings.length(), 1)
  assert_eq(fsm.crossings[0].admitted, false)
  assert_eq(fsm.crossings[0].rejection, Some("BAD_KIND"))
  let wire = fsm.emit_stigmergy(note="crossing rejected")
  assert_true(wire.contains("admitted=0"))
  assert_true(wire.contains("rejection=BAD_KIND"))
}

///|
test "BoundaryWalkerFSM cave records every walked scalar and finding" {
  let fsm = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://merkin/root")
    .walk_scalars([("a", "alpha"), ("b", ghost_main())])
    .mark()
  assert_true(fsm.cave.depth() >= 3U) // 2 walks + mark
  let walks = fsm.cave.collect("walk")
  let findings = fsm.cave.collect("finding")
  assert_eq(walks.length(), 1)
  assert_eq(findings.length(), 1)
  assert_eq(findings[0].key, "b")
}

///|
test "BoundaryWalkerFSM cave drains and resets but preserves seq monotonicity" {
  let fsm = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://merkin/root").walk_scalar(
    "a", "alpha",
  )
  let initial_depth = fsm.cave.depth()
  let (drained_cave, entries) = fsm.cave.drain()
  assert_eq(entries.length(), initial_depth.reinterpret_as_int())
  assert_eq(drained_cave.depth(), 0U)
  let after = drained_cave.deposit(
    kind="note",
    key="extra",
    value="post-drain",
    from_state="walking",
    to_state="walking",
  )
  assert_true(after.entries[0].seq > entries[entries.length() - 1].seq)
}
