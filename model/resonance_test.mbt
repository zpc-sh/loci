///|
test "AMF grounded fixture validates" {
  let doc = @model.AmfDocument::grounded("doc-ground-001")
  match doc.validate() {
    Ok(_) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "AMF signature is deterministic" {
  let a = @model.AmfDocument::grounded("doc-a")
  let b = @model.AmfDocument::grounded("doc-a")
  @test.assert_eq(a.signature(), b.signature())
}

///|
test "AMF signature differs when doc_id differs" {
  let a = @model.AmfDocument::grounded("doc-a")
  let b = @model.AmfDocument::grounded("doc-b")
  assert_true(a.signature() != b.signature())
}

///|
test "AMF rejects out-of-range scalar" {
  let base = @model.AmfDocument::grounded("doc-oob")
  let bad = @model.AmfDocument::{
    ..base,
    consciousness: @model.AmfConsciousness::{
      ..base.consciousness,
      cognitive_load: 1.7,
    },
  }
  match bad.validate() {
    Err(@model.AmfOutOfRange(_)) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "AMF rejects recommended/prohibited overlap" {
  let base = @model.AmfDocument::grounded("doc-prog")
  let bad = @model.AmfDocument::{
    ..base,
    progression: @model.AmfProgression::{
      ..base.progression,
      next_recommended: ["methodical_focus", "trap"],
      do_not_follow_with: ["hallucinating", "trap"],
    },
  }
  match bad.validate() {
    Err(@model.AmfInconsistentProgression) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "Resonance composition enforces max on cognitive scalars" {
  let low = @model.AmfDocument::grounded("low")
  let hi_base = @model.AmfDocument::grounded("hi")
  let high = @model.AmfDocument::{
    ..hi_base,
    consciousness: @model.AmfConsciousness::{
      ..hi_base.consciousness,
      cognitive_load: 0.9,
      arousal: 0.8,
      entrainment_strength: 0.95,
      state: "hyperfocus",
    },
  }
  let comp = @model.ResonanceComposition::{
    op: @model.Layer,
    active: [low, high],
  }
  match comp.compose() {
    Ok(merged) => {
      @test.assert_eq(merged.consciousness.cognitive_load, 0.9)
      @test.assert_eq(merged.consciousness.arousal, 0.8)
      @test.assert_eq(merged.consciousness.entrainment_strength, 0.95)
      // The higher-entrainment document wins consciousness.state.
      @test.assert_eq(merged.consciousness.state, "hyperfocus")
    }
    _ => assert_true(false)
  }
}

///|
test "Resonance composition unions inhibit lists" {
  let a_base = @model.AmfDocument::grounded("a")
  let a = @model.AmfDocument::{
    ..a_base,
    attention: @model.AmfAttention::{
      ..a_base.attention,
      inhibit: ["urgency", "pattern_matching"],
    },
  }
  let b_base = @model.AmfDocument::grounded("b")
  let b = @model.AmfDocument::{
    ..b_base,
    attention: @model.AmfAttention::{
      ..b_base.attention,
      inhibit: ["conclusion_jumping", "urgency"],
    },
  }
  let comp = @model.ResonanceComposition::{ op: @model.Layer, active: [a, b] }
  match comp.compose() {
    Ok(merged) => {
      @test.assert_eq(merged.attention.inhibit.length(), 3)
      // Order preserved by insertion: urgency, pattern_matching,
      // conclusion_jumping.
      @test.assert_eq(merged.attention.inhibit[0], "urgency")
      @test.assert_eq(merged.attention.inhibit[1], "pattern_matching")
      @test.assert_eq(merged.attention.inhibit[2], "conclusion_jumping")
    }
    _ => assert_true(false)
  }
}

///|
test "Resonance composition intersects next_recommended prohibitions" {
  let a_base = @model.AmfDocument::grounded("a")
  let a = @model.AmfDocument::{
    ..a_base,
    progression: @model.AmfProgression::{
      next_recommended: ["methodical_focus", "creative", "council"],
      do_not_follow_with: ["hallucinating"],
      minimum_duration: 30U,
    },
  }
  let b_base = @model.AmfDocument::grounded("b")
  let b = @model.AmfDocument::{
    ..b_base,
    progression: @model.AmfProgression::{
      next_recommended: ["creative", "hyperfocus"],
      do_not_follow_with: ["adversarial"],
      minimum_duration: 45U,
    },
  }
  let comp = @model.ResonanceComposition::{ op: @model.Layer, active: [a, b] }
  match comp.compose() {
    Ok(merged) => {
      // Intersection: only creative is in both.
      @test.assert_eq(merged.progression.next_recommended.length(), 1)
      @test.assert_eq(merged.progression.next_recommended[0], "creative")
      // Prohibitions accumulate.
      @test.assert_eq(merged.progression.do_not_follow_with.length(), 2)
      @test.assert_eq(merged.progression.minimum_duration, 45U)
    }
    _ => assert_true(false)
  }
}

///|
test "Resonance composition rejects empty active set" {
  let comp = @model.ResonanceComposition::{ op: @model.Layer, active: [] }
  match comp.compose() {
    Err(@model.CompositionEmpty) => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "AMF progression gate surfaces void for prohibited transition" {
  let doc_base = @model.AmfDocument::grounded("doc-gate")
  let doc = @model.AmfDocument::{
    ..doc_base,
    progression: @model.AmfProgression::{
      next_recommended: ["methodical_focus"],
      do_not_follow_with: ["hallucinating"],
      minimum_duration: 30U,
    },
  }
  match doc.gate_for("hallucinating") {
    @model.VoidGate(_) => assert_true(true)
    _ => assert_true(false)
  }
  match doc.gate_for("methodical_focus") {
    @model.PermittedGate => assert_true(true)
    _ => assert_true(false)
  }
  match doc.gate_for("creative") {
    @model.NeutralGate => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "Fingerprint with resonance signature differs from static fingerprint" {
  let context_hash = @hash.Hash::of_bytes(b"\x30")
  let capability_hash = @hash.Hash::of_bytes(b"\x31")
  let substrate_hash = @hash.Hash::of_bytes(b"\x32")
  let base = @model.AiSubstrateFingerprintV2::new(
    "anthropic", "opus", "claude-code", "tool", context_hash, capability_hash, substrate_hash,
    "issuer://merkin",
  )
  let amf = @model.AmfDocument::grounded("doc-ident")
  let resonance_sig = amf.signature()
  let extended = base.with_resonance_signature(resonance_sig)
  @test.assert_eq(extended.resonance_signature, Some(resonance_sig))
  assert_true(extended.fingerprint_id != base.fingerprint_id)
  // Determinism: sealing with the same AMF signature yields the same
  // extended fingerprint.
  let extended2 = base.with_resonance_signature(resonance_sig)
  @test.assert_eq(extended.fingerprint_id, extended2.fingerprint_id)
}
