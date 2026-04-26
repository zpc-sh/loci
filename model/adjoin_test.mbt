///|
fn locus_leaf_fixture(id : String, seal_byte : Byte) -> @model.AdjoinExpr {
  let digest_bytes = FixedArray::make(1, seal_byte)
  let digest = Bytes::from_array(digest_bytes)
  @model.LocusLeaf(@model.LocusRef::{
    locus_id: id,
    surface_ref: id + ".surface",
    profile_ref: id + ".profile",
    seal: @hash.Hash::of_bytes(digest),
  })
}

///|
fn void_leaf_fixture(
  plan_ref : String,
  seal_byte : Byte,
  confidence : UInt,
) -> @model.AdjoinExpr {
  let digest_bytes = FixedArray::make(1, seal_byte)
  let digest = Bytes::from_array(digest_bytes)
  @model.VoidLeaf(@model.YataLocusRef::{
    yata_plan_ref: plan_ref,
    expected_type: @model.Observation,
    void_typed: true,
    min_confidence: confidence,
    seal: @hash.Hash::of_bytes(digest),
  })
}

///|
fn sample_contract() -> @model.AdjoinContract {
  let root = locus_leaf_fixture("genius://repo/root", b'\xa1')
  let agent = locus_leaf_fixture("genius://repo/agent", b'\xa2')
  let void14 = void_leaf_fixture("merkin.yata.plan#hole-attn-14", b'\xa3', 72U)
  let consume_node = @model.Op(@model.Consume, root, agent, [
    ("policy_mode", "sanitize"),
  ])
  let yata_node = @model.Op(
    @model.YataUnion,
    locus_leaf_fixture("genius://repo/root", b'\xa1'),
    void14,
    [("route_hint", "mu-fsm-observe")],
  )
  let root_expr = @model.Op(@model.Union, consume_node, yata_node, [
    ("federation", "pactis"),
  ])
  @model.AdjoinContract::new(
    "adjoin-20260419-001",
    "ratio://merkin/root",
    root_expr,
    ["finger.plan.wasm", "merkin.yata.plan", "triad-contract"],
    @model.Sanitize,
  )
}

///|
test "Adjoin packet sample validates" {
  let contract = sample_contract()
  match contract.validate() {
    Ok(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "Adjoin seal is deterministic across reconstruction" {
  let a = sample_contract()
  let b = sample_contract()
  @test.assert_eq(a.seal, b.seal)
  // Resealing is idempotent.
  @test.assert_eq(a.reseal().seal, a.seal)
}

///|
test "Adjoin seal changes when a leaf changes" {
  let a = sample_contract()
  let alt_root = locus_leaf_fixture("genius://repo/root", b'\xb1')
  let alt_agent = locus_leaf_fixture("genius://repo/agent", b'\xa2')
  let alt_consume = @model.Op(@model.Consume, alt_root, alt_agent, [
    ("policy_mode", "sanitize"),
  ])
  let b = @model.AdjoinContract::new(
    "adjoin-20260419-001",
    "ratio://merkin/root",
    @model.Op(
      @model.Union,
      alt_consume,
      @model.Op(
        @model.YataUnion,
        locus_leaf_fixture("genius://repo/root", b'\xa1'),
        void_leaf_fixture("merkin.yata.plan#hole-attn-14", b'\xa3', 72U),
        [("route_hint", "mu-fsm-observe")],
      ),
      [("federation", "pactis")],
    ),
    ["finger.plan.wasm", "merkin.yata.plan", "triad-contract"],
    @model.Sanitize,
  )
  assert_true(a.seal != b.seal)
}

///|
test "Adjoin meta ordering is canonicalized" {
  let leaf_a = locus_leaf_fixture("genius://a", b'\x01')
  let leaf_b = locus_leaf_fixture("genius://b", b'\x02')
  let first = @model.Op(@model.Union, leaf_a, leaf_b, [
    ("alpha", "1"),
    ("beta", "2"),
  ])
  let second = @model.Op(
    @model.Union,
    locus_leaf_fixture("genius://a", b'\x01'),
    locus_leaf_fixture("genius://b", b'\x02'),
    [("beta", "2"), ("alpha", "1")],
  )
  @test.assert_eq(first.seal(), second.seal())
}

///|
test "Adjoin rejects missing ratio_loci" {
  let contract = @model.AdjoinContract::{ ..sample_contract(), ratio_loci: "" }
  match contract.validate() {
    Err(@model.AdjoinMissingRatioLoci) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "Adjoin rejects empty required_surfaces" {
  let contract = @model.AdjoinContract::{
    ..sample_contract(),
    required_surfaces: [],
  }
  match contract.validate() {
    Err(@model.AdjoinEmptyRequiredSurfaces) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "Adjoin rejects leaf with missing seal" {
  let empty_hash = @hash.Hash::{ alg: @hash.Blake3, digest: b"" }
  let bad_leaf = @model.LocusLeaf(@model.LocusRef::{
    locus_id: "genius://repo/bad",
    surface_ref: "x",
    profile_ref: "y",
    seal: empty_hash,
  })
  let contract = @model.AdjoinContract::new(
    "c-bad-seal",
    "ratio://merkin/root",
    bad_leaf,
    ["finger.plan.wasm"],
    @model.Sanitize,
  )
  match contract.validate() {
    Err(@model.AdjoinMissingSeal(_)) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "Adjoin rejects yata_union with non-void right" {
  let left = locus_leaf_fixture("genius://a", b'\x11')
  let right_concrete = locus_leaf_fixture("genius://b", b'\x12')
  let expr = @model.Op(@model.YataUnion, left, right_concrete, [])
  let contract = @model.AdjoinContract::new(
    "c-bad-yata",
    "ratio://merkin/root",
    expr,
    ["finger.plan.wasm"],
    @model.Sanitize,
  )
  match contract.validate() {
    Err(@model.AdjoinInvalidYataUnionRight) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "Adjoin rejects void_typed=false leaf" {
  let bad_void = @model.VoidLeaf(@model.YataLocusRef::{
    yata_plan_ref: "merkin.yata.plan#x",
    expected_type: @model.Resolution,
    void_typed: false,
    min_confidence: 50U,
    seal: @hash.Hash::of_bytes(b"\x22"),
  })
  let contract = @model.AdjoinContract::new(
    "c-bad-void",
    "ratio://merkin/root",
    bad_void,
    ["finger.plan.wasm"],
    @model.Sanitize,
  )
  match contract.validate() {
    Err(@model.AdjoinInvalidVoidTyped) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "Adjoin op wire tags round-trip" {
  let ops = [
    ("union", @model.Union),
    ("consume", @model.Consume),
    ("atop", @model.Atop),
    ("subtract", @model.Subtract),
    ("yata_union", @model.YataUnion),
  ]
  for pair in ops {
    @test.assert_eq(@model.adjoin_op_tag(pair.1), pair.0)
    match @model.adjoin_op_parse(pair.0) {
      Some(op) => @test.assert_eq(op, pair.1)
      None => assert_true(false)
    }
  }
  @test.assert_eq(@model.adjoin_op_parse("nonsense"), None)
}

///|
test "Adjoin expected-type wire tags round-trip" {
  let types = [
    ("Observation", @model.Observation),
    ("Compilation", @model.Compilation),
    ("Delegation", @model.Delegation),
    ("Resolution", @model.Resolution),
    ("Audit", @model.YataAudit),
    ("Synthesis", @model.YataSynthesis),
  ]
  for pair in types {
    @test.assert_eq(@model.yata_expected_type_tag(pair.1), pair.0)
    match @model.yata_expected_type_parse(pair.0) {
      Some(t) => @test.assert_eq(t, pair.1)
      None => assert_true(false)
    }
  }
}

///|
test "Adjoin closure: yata_union output can feed into consume" {
  // Exercises the closure invariant: an op output is itself a tree
  // node and can feed into any other op.
  let l1 = locus_leaf_fixture("genius://x", b'\x51')
  let v1 = void_leaf_fixture("merkin.yata.plan#slot-1", b'\x52', 80U)
  let yata_union_node = @model.Op(@model.YataUnion, l1, v1, [])
  let outer_left = locus_leaf_fixture("genius://outer", b'\x53')
  let outer = @model.Op(@model.Consume, outer_left, yata_union_node, [])
  let contract = @model.AdjoinContract::new(
    "c-closure",
    "ratio://merkin/root",
    outer,
    ["finger.plan.wasm"],
    @model.Sanitize,
  )
  match contract.validate() {
    Ok(_) => assert_true(true)
    _ => assert_true(false)
  }
}
