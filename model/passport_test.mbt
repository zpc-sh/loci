///|
/// Helper: a fully valid passport fixture matching the packet example.
fn valid_passport_fixture() -> @model.Passport {
  let fingerprint_commitment = @hash.Hash::of_bytes(b"\xa1\xa2\xa3")
  let actor_seal = @hash.Hash::of_bytes(b"\xb1\xb2\xb3")
  let passport_seal = @hash.Hash::of_bytes(b"\xc1\xc2\xc3")
  let who = @model.PassportWho::{
    overlay: "codex",
    family: "openai",
    session_surface: "codex",
    fingerprint_commitment,
    actor_seal,
  }
  let what = @model.PassportWhat::{
    artifact_type: @model.Plan,
    artifact_ref: "merkin.yata.plan#hole-902",
  }
  let why = @model.PassportWhy::{
    intent: @model.Implement,
    note: "cross-locus compiler handoff",
  }
  let where_ = @model.PassportWhere::{
    source_locus: "genius://merkin/main",
    target_locus: "genius://mu/compiler",
    allowed_surfaces: ["contract", "runtime", "federation"],
  }
  let how_far = @model.PassportHowFar::{
    capability_class: @model.PatchVerify,
    budget_class: "bounded-medium",
    boundary_mode: @model.Sanitize,
  }
  let trace = @model.PassportTrace::{
    context_ref: "finger.plan.wasm#node-22",
    lineage_ref: "triad-contract#v0.1",
    passport_seal,
  }
  @model.Passport::new(
    "pass-20260419-001", who, what, why, where_, how_far, trace,
  )
}

///|
test "Passport validates the packet example" {
  let p = valid_passport_fixture()
  match p.validate() {
    Ok(_) => assert_true(true)
    Err(e) => {
      assert_true(false)
      let _ = e
    }
  }
}

///|
test "Passport seal is deterministic across reconstruction" {
  let a = valid_passport_fixture()
  let b = valid_passport_fixture()
  @test.assert_eq(a.seal_material(), b.seal_material())
}

///|
test "Passport BadKind when kind is wrong" {
  let p = valid_passport_fixture()
  let mutated = @model.Passport::{ ..p, kind: "something.else" }
  match mutated.validate() {
    Err(@model.BadKind) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "Passport BadVersion when version is wrong" {
  let p = valid_passport_fixture()
  let mutated = @model.Passport::{ ..p, version: "v0.0" }
  match mutated.validate() {
    Err(@model.BadVersion) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "Passport MissingSection on empty passport_id" {
  let p = valid_passport_fixture()
  let mutated = @model.Passport::{ ..p, passport_id: "" }
  match mutated.validate() {
    Err(@model.MissingSection("passport_id")) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "Passport MissingSection on empty who.family" {
  let p = valid_passport_fixture()
  let mutated = @model.Passport::{
    ..p,
    who: @model.PassportWho::{ ..p.who, family: "" },
  }
  match mutated.validate() {
    Err(@model.MissingSection("who.family")) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "Passport MissingSeal on empty fingerprint_commitment" {
  let p = valid_passport_fixture()
  let empty = @hash.Hash::{ alg: @hash.Blake3, digest: b"" }
  let mutated = @model.Passport::{
    ..p,
    who: @model.PassportWho::{ ..p.who, fingerprint_commitment: empty },
  }
  match mutated.validate() {
    Err(@model.MissingSeal("who.fingerprint_commitment")) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "Passport MissingSeal on empty passport_seal" {
  let p = valid_passport_fixture()
  let empty = @hash.Hash::{ alg: @hash.Blake3, digest: b"" }
  let mutated = @model.Passport::{
    ..p,
    trace: @model.PassportTrace::{ ..p.trace, passport_seal: empty },
  }
  match mutated.validate() {
    Err(@model.MissingSeal("trace.passport_seal")) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "Passport EmptyAllowedSurfaces when list is empty" {
  let p = valid_passport_fixture()
  let mutated = @model.Passport::{
    ..p,
    where_: @model.PassportWhere::{ ..p.where_, allowed_surfaces: [] },
  }
  match mutated.validate() {
    Err(@model.EmptyAllowedSurfaces) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "Passport CapabilityIntentMismatch when implement meets read-only" {
  let p = valid_passport_fixture()
  let mutated = @model.Passport::{
    ..p,
    how_far: @model.PassportHowFar::{
      ..p.how_far,
      capability_class: @model.ReadOnly,
    },
  }
  match mutated.validate() {
    Err(@model.CapabilityIntentMismatch) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "Passport InvalidIntent when patch is paired with observe" {
  let p = valid_passport_fixture()
  let mutated = @model.Passport::{
    ..p,
    what: @model.PassportWhat::{ ..p.what, artifact_type: @model.Patch },
    why: @model.PassportWhy::{ ..p.why, intent: @model.Observe },
    how_far: @model.PassportHowFar::{
      ..p.how_far,
      capability_class: @model.Full,
    },
  }
  match mutated.validate() {
    Err(@model.InvalidIntent) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "Passport wire tags round-trip through parse helpers" {
  let tags = [
    ("spec", @model.Spec),
    ("plan", @model.Plan),
    ("design", @model.Design),
    ("patch", @model.Patch),
    ("signal", @model.Signal),
    ("report", @model.Report),
    ("bundle", @model.Bundle),
  ]
  for pair in tags {
    @test.assert_eq(@model.artifact_type_tag(pair.1), pair.0)
    match @model.artifact_type_parse(pair.0) {
      Some(v) => @test.assert_eq(v, pair.1)
      None => assert_true(false)
    }
  }
  @test.assert_eq(@model.artifact_type_parse("unknown"), None)
}

///|
test "Passport boundary_mode and capability_class parse round-trip" {
  @test.assert_eq(@model.boundary_mode_tag(@model.Sanitize), "sanitize")
  @test.assert_eq(@model.boundary_mode_parse("sanitize"), Some(@model.Sanitize))
  @test.assert_eq(@model.boundary_mode_parse("nonsense"), None)
  @test.assert_eq(@model.capability_class_tag(@model.Full), "full")
  @test.assert_eq(@model.capability_class_parse("full"), Some(@model.Full))
  @test.assert_eq(@model.capability_class_parse("god-mode"), None)
}

///|
test "Passport observe intent with read-only capability is admissible" {
  let p = valid_passport_fixture()
  let mutated = @model.Passport::{
    ..p,
    what: @model.PassportWhat::{ ..p.what, artifact_type: @model.Signal },
    why: @model.PassportWhy::{ ..p.why, intent: @model.Observe },
    how_far: @model.PassportHowFar::{
      ..p.how_far,
      capability_class: @model.ReadOnly,
    },
  }
  match mutated.validate() {
    Ok(_) => assert_true(true)
    _ => assert_true(false)
  }
}
