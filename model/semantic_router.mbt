///|
/// Semantic Router Contract v0.1 — stub.
///
/// The router evaluates every locus crossing before target execution.
/// This arc defines types and the decision-artifact emitter; policy
/// logic is the next arc's work.
///
/// Replay invariant: given the same (passport, inputs, resonance
/// signature) a replay reproduces the same decision envelope
/// byte-for-byte. Widening is forbidden by construction — a router
/// cannot grant more authority than the passport declared.
pub(all) struct RouterInputs {
  passport : Passport
  target_profile : String
  boundary_findings_count : UInt
  boundary_status : BoundaryStatus
  capability_budget_remaining : UInt
  resonance_signature : @hash.Hash?
} derive(Debug)

///|
/// Router actions. `RouteNarrow` carries the reduced surfaces and
/// a replacement capability class; the router may only shrink, not
/// widen. `RouteSandbox` names the execution lane to redirect to.
pub(all) enum RouterAction {
  RouteAllow
  RouteNarrow(Array[String], CapabilityClass)
  RouteSandbox(String)
  RouteQuarantine(String)
  RouteDeny(String)
} derive(Debug)

///|
/// A sealed router decision artifact. Replay checks: kind and
/// version match; decision_seal matches the canonical seal over
/// (passport_seal, resonance_signature, action, reason).
pub(all) struct RouterDecision {
  kind : String
  version : String
  decision_id : String
  passport_id : String
  passport_seal : @hash.Hash
  resonance_signature : @hash.Hash?
  action : RouterAction
  reason : String
  decision_seal : @hash.Hash
} derive(Debug)

///|
/// Router errors.
pub(all) enum RouterError {
  RouterBadKind
  RouterBadVersion
  RouterMissingField(String)
  RouterMissingSeal(String)
} derive(Eq, Debug)

///|
pub fn router_kind() -> String {
  "merkin.semantic.router.decision"
}

///|
pub fn router_version() -> String {
  "v0"
}

///|
/// Tag for a router action on the wire.
pub fn router_action_tag(a : RouterAction) -> String {
  match a {
    RouteAllow => "allow"
    RouteNarrow(_, _) => "narrow"
    RouteSandbox(_) => "sandbox"
    RouteQuarantine(_) => "quarantine"
    RouteDeny(_) => "deny"
  }
}

///|
/// Construct and seal a router decision. This is the full emit path
/// used by whichever Phase-5-filling policy eventually decides the
/// action. The stub just seals what it is handed; a widening check
/// is deferred to the next arc's policy layer.
pub fn RouterDecision::emit(
  decision_id : String,
  passport : Passport,
  resonance_signature : @hash.Hash?,
  action : RouterAction,
  reason : String,
) -> RouterDecision {
  let seal = compute_router_seal(
    decision_id,
    passport.passport_id,
    passport.trace.passport_seal,
    resonance_signature,
    action,
    reason,
  )
  {
    kind: router_kind(),
    version: router_version(),
    decision_id,
    passport_id: passport.passport_id,
    passport_seal: passport.trace.passport_seal,
    resonance_signature,
    action,
    reason,
    decision_seal: seal,
  }
}

///|
pub fn RouterDecision::validate(
  self : RouterDecision,
) -> Result[Unit, RouterError] {
  if self.kind != router_kind() {
    return Err(RouterBadKind)
  }
  if self.version != router_version() {
    return Err(RouterBadVersion)
  }
  if self.decision_id == "" {
    return Err(RouterMissingField("decision_id"))
  }
  if self.passport_id == "" {
    return Err(RouterMissingField("passport_id"))
  }
  if hash_is_empty(self.passport_seal) {
    return Err(RouterMissingSeal("passport_seal"))
  }
  if hash_is_empty(self.decision_seal) {
    return Err(RouterMissingSeal("decision_seal"))
  }
  Ok(())
}

///|
/// Recompute the canonical seal from the decision's own fields.
/// Replay checks: `decision.recompute_seal() == decision.decision_seal`.
pub fn RouterDecision::recompute_seal(self : RouterDecision) -> @hash.Hash {
  compute_router_seal(
    self.decision_id,
    self.passport_id,
    self.passport_seal,
    self.resonance_signature,
    self.action,
    self.reason,
  )
}

///|
fn compute_router_seal(
  decision_id : String,
  passport_id : String,
  passport_seal : @hash.Hash,
  resonance_signature : @hash.Hash?,
  action : RouterAction,
  reason : String,
) -> @hash.Hash {
  let b = StringBuilder::new(size_hint=512)
  b.write_string(router_kind())
  b.write_string("|")
  b.write_string(router_version())
  b.write_string("|")
  b.write_string(decision_id)
  b.write_string("|passport=")
  b.write_string(passport_id)
  b.write_string(";")
  b.write_string(passport_seal.key())
  b.write_string("|resonance=")
  match resonance_signature {
    Some(sig) => b.write_string(sig.key())
    None => b.write_string("none")
  }
  b.write_string("|action=")
  b.write_string(router_action_tag(action))
  b.write_string(";")
  match action {
    RouteAllow => b.write_string("-")
    RouteNarrow(surfaces, cap) => {
      let sorted = router_surfaces_sorted(surfaces)
      for i = 0; i < sorted.length(); i = i + 1 {
        if i > 0 {
          b.write_string(",")
        }
        b.write_string(sorted[i])
      }
      b.write_string("@")
      b.write_string(capability_class_tag(cap))
    }
    RouteSandbox(lane) => b.write_string(lane)
    RouteQuarantine(r) => b.write_string(r)
    RouteDeny(r) => b.write_string(r)
  }
  b.write_string("|reason=")
  b.write_string(reason)
  @hash.Hash::of_bytes(router_string_to_bytes(b.to_string()))
}

///|
fn router_surfaces_sorted(surfaces : Array[String]) -> Array[String] {
  let sorted : Array[String] = []
  for s in surfaces {
    sorted.push(s)
  }
  for i = 1; i < sorted.length(); i = i + 1 {
    let key = sorted[i]
    let mut j = i - 1
    while j >= 0 && sorted[j] > key {
      sorted[j + 1] = sorted[j]
      j = j - 1
    }
    sorted[j + 1] = key
  }
  sorted
}

///|
fn router_string_to_bytes(s : String) -> Bytes {
  let mut total = 0
  for _ch in s {
    total = total + 4
  }
  let buf = FixedArray::make(total, b'\x00')
  let mut pos = 0
  for ch in s {
    let code = ch.to_uint()
    buf[pos] = ((code >> 24) & 0xFFU).to_byte()
    buf[pos + 1] = ((code >> 16) & 0xFFU).to_byte()
    buf[pos + 2] = ((code >> 8) & 0xFFU).to_byte()
    buf[pos + 3] = (code & 0xFFU).to_byte()
    pos = pos + 4
  }
  Bytes::from_array(buf)
}
