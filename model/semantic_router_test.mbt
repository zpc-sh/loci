///|
fn router_sample_passport() -> @model.Passport {
  let fingerprint_commitment = @hash.Hash::of_bytes(b"\x70")
  let actor_seal = @hash.Hash::of_bytes(b"\x71")
  let passport_seal = @hash.Hash::of_bytes(b"\x72")
  @model.Passport::new(
    "pass-router-001",
    @model.PassportWho::{
      overlay: "codex",
      family: "openai",
      session_surface: "codex",
      fingerprint_commitment,
      actor_seal,
    },
    @model.PassportWhat::{
      artifact_type: @model.Plan,
      artifact_ref: "merkin.yata.plan#router-1",
    },
    @model.PassportWhy::{
      intent: @model.Implement,
      note: "router stub round-trip",
    },
    @model.PassportWhere::{
      source_locus: "genius://merkin/main",
      target_locus: "genius://mu/compiler",
      allowed_surfaces: ["contract", "runtime"],
    },
    @model.PassportHowFar::{
      capability_class: @model.PatchVerify,
      budget_class: "bounded-medium",
      boundary_mode: @model.Sanitize,
    },
    @model.PassportTrace::{
      context_ref: "finger.plan.wasm#router-1",
      lineage_ref: "triad-contract#v0.1",
      passport_seal,
    },
  )
}

///|
test "Router decision seals the passport trail" {
  let passport = router_sample_passport()
  let decision = @model.RouterDecision::emit(
    "dec-001",
    passport,
    None,
    @model.RouteAllow,
    "stub allow for test",
  )
  match decision.validate() {
    Ok(_) => assert_true(true)
    _ => assert_true(false)
  }
  assert_eq(decision.recompute_seal(), decision.decision_seal)
  assert_eq(decision.passport_id, passport.passport_id)
  assert_eq(decision.passport_seal, passport.trace.passport_seal)
}

///|
test "Router decision carries the resonance signature" {
  let passport = router_sample_passport()
  let amf = @model.AmfDocument::grounded("doc-router")
  let sig = amf.signature()
  let decision = @model.RouterDecision::emit(
    "dec-res-001",
    passport,
    Some(sig),
    @model.RouteAllow,
    "resonance-aware allow",
  )
  assert_eq(decision.resonance_signature, Some(sig))
  // Recomputing without the resonance signature gives a different
  // seal — resonance is cryptographically inside the decision.
  let without = @model.RouterDecision::emit(
    "dec-res-001",
    passport,
    None,
    @model.RouteAllow,
    "resonance-aware allow",
  )
  assert_true(without.decision_seal != decision.decision_seal)
}

///|
test "Router narrow action seals sorted surfaces" {
  let passport = router_sample_passport()
  let a = @model.RouterDecision::emit(
    "dec-narrow-001",
    passport,
    None,
    @model.RouteNarrow(["runtime", "contract"], @model.ReadOnly),
    "narrow per profile",
  )
  let b = @model.RouterDecision::emit(
    "dec-narrow-001",
    passport,
    None,
    @model.RouteNarrow(["contract", "runtime"], @model.ReadOnly),
    "narrow per profile",
  )
  // Same narrowing set + same capability → same seal regardless of
  // surface ordering.
  assert_eq(a.decision_seal, b.decision_seal)
}

///|
test "Router actions produce distinct seals" {
  let passport = router_sample_passport()
  let allow = @model.RouterDecision::emit(
    "dec-all", passport, None, @model.RouteAllow, "ok",
  )
  let deny = @model.RouterDecision::emit(
    "dec-all", passport, None, @model.RouteDeny("policy"), "ok",
  )
  let sandbox = @model.RouterDecision::emit(
    "dec-all", passport, None, @model.RouteSandbox("lane-a"), "ok",
  )
  let quarantine = @model.RouterDecision::emit(
    "dec-all", passport, None, @model.RouteQuarantine("needs-review"), "ok",
  )
  assert_true(allow.decision_seal != deny.decision_seal)
  assert_true(allow.decision_seal != sandbox.decision_seal)
  assert_true(allow.decision_seal != quarantine.decision_seal)
  assert_true(deny.decision_seal != sandbox.decision_seal)
  assert_true(deny.decision_seal != quarantine.decision_seal)
}

///|
test "Router action tags are stable" {
  assert_eq(@model.router_action_tag(@model.RouteAllow), "allow")
  assert_eq(
    @model.router_action_tag(@model.RouteNarrow([], @model.ReadOnly)),
    "narrow",
  )
  assert_eq(@model.router_action_tag(@model.RouteSandbox("x")), "sandbox")
  assert_eq(@model.router_action_tag(@model.RouteQuarantine("r")), "quarantine")
  assert_eq(@model.router_action_tag(@model.RouteDeny("r")), "deny")
}

///|
test "Router decision rejects missing seal" {
  let passport = router_sample_passport()
  let decision = @model.RouterDecision::emit(
    "dec-bad",
    passport,
    None,
    @model.RouteAllow,
    "ok",
  )
  let bad = @model.RouterDecision::{
    ..decision,
    decision_seal: @hash.Hash::{ alg: @hash.Blake3, digest: b"" },
  }
  match bad.validate() {
    Err(@model.RouterMissingSeal(_)) => assert_true(true)
    _ => assert_true(false)
  }
}
