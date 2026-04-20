///|
fn sample_build_request() -> @model.BuildRequest {
  let target : @model.BuildTarget = {
    family: "claude",
    model: "opus",
    mobility: 0.7,
    movement: @model.MovementDiscrete,
  }
  let semanticfile = "SUBSTRATE claude/opus\n" +
    "    MOBILITY 0.7\n" +
    "    MOVEMENT discrete\n" +
    "\n" +
    "FROM locus://merkin/alpha AS alpha\n" +
    "FROM locus://merkin/beta  AS beta\n" +
    "\n" +
    "ADJOIN alpha UNION beta\n" +
    "    META policy_mode=sanitize\n"
  let seed = @model.BuildRequest::new(
    "bld-20260420-001",
    semanticfile,
    target,
    @model.Sanitize,
    @model.SllLayered,
    "ratio://merkin/root",
    @hash.Hash::of_bytes(b"\x00"),
  )
  @model.BuildRequest::{ ..seed, request_seal: seed.seal_material() }
}

///|
test "SLL build request validates" {
  let req = sample_build_request()
  match req.validate() {
    Ok(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "SLL seal is deterministic" {
  let a = sample_build_request()
  let b = sample_build_request()
  assert_eq(a.seal_material(), b.seal_material())
}

///|
test "SLL seal changes when source changes" {
  let base = sample_build_request()
  let mutated = @model.BuildRequest::{
    ..base,
    semanticfile: base.semanticfile + "\nADJOIN alpha ATOP beta\n",
  }
  assert_true(base.seal_material() != mutated.seal_material())
}

///|
test "SLL rejects empty source" {
  let base = sample_build_request()
  let bad = @model.BuildRequest::{ ..base, semanticfile: "" }
  match bad.validate() {
    Err(@model.SllEmptySource) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "SLL rejects mobility out of range" {
  let base = sample_build_request()
  let bad = @model.BuildRequest::{
    ..base,
    target: @model.BuildTarget::{ ..base.target, mobility: 1.5 },
  }
  match bad.validate() {
    Err(@model.SllMobilityOutOfRange) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "SLL rejects missing ratio_loci" {
  let base = sample_build_request()
  let bad = @model.BuildRequest::{ ..base, ratio_loci: "" }
  match bad.validate() {
    Err(@model.SllMissingField(_)) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "SLL movement tags round-trip" {
  let tags = [
    ("discrete", @model.MovementDiscrete),
    ("fluid", @model.MovementFluid),
    ("structured", @model.MovementStructured),
  ]
  for pair in tags {
    assert_eq(@model.sll_movement_tag(pair.1), pair.0)
    match @model.sll_movement_parse(pair.0) {
      Some(m) => assert_eq(m, pair.1)
      None => assert_true(false)
    }
  }
}

///|
test "SLL composition tags round-trip" {
  let tags = [
    ("layered", @model.SllLayered),
    ("sequenced", @model.SllSequenced),
    ("live", @model.SllLive),
  ]
  for pair in tags {
    assert_eq(@model.sll_composition_tag(pair.1), pair.0)
    match @model.sll_composition_parse(pair.0) {
      Some(m) => assert_eq(m, pair.1)
      None => assert_true(false)
    }
  }
}

///|
test "SLL build manifest provenance seal binds request + adjoin + wasm" {
  let request_seal = @hash.Hash::of_bytes(b"\x11")
  let adjoin_seal = @hash.Hash::of_bytes(b"\x22")
  let prov_with_wasm = @model.BuildManifest::compute_provenance(
    request_seal,
    adjoin_seal,
    Some("wasm://build/a1b2c3"),
  )
  let prov_without = @model.BuildManifest::compute_provenance(
    request_seal,
    adjoin_seal,
    None,
  )
  // Determinism: recomputing with the same inputs matches.
  let prov_again = @model.BuildManifest::compute_provenance(
    request_seal,
    adjoin_seal,
    Some("wasm://build/a1b2c3"),
  )
  assert_eq(prov_with_wasm, prov_again)
  // A different wasm_ref (or None) yields a different provenance.
  assert_true(prov_with_wasm != prov_without)
}

///|
test "SLL build manifest validates" {
  let manifest = @model.BuildManifest::new(
    "bld-20260420-001",
    @hash.Hash::of_bytes(b"\x30"),
    Some("wasm://build/out"),
    @hash.Hash::of_bytes(b"\x31"),
    [
      @model.BuildDiagnostic::{
        level: @model.DiagInfo,
        span: "line 3",
        message: "substrate target claude/opus accepted",
      },
    ],
    @model.BuildOk,
  )
  match manifest.validate() {
    Ok(_) => assert_true(true)
    _ => assert_true(false)
  }
}
