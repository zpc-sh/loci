///|
/// Outcome of evaluating a `Crosser` at a membrane.
pub(all) enum CrossResult {
  Admitted
  Rejected(String)
} derive(Eq, Debug)

///|
/// Crosser is the abstraction over membrane-crossing credentials
/// (e.g. a Locus Crossing Passport, a capability token, an OAuth bundle).
///
/// Hosts implement this trait for their own credential type and then
/// pass values to `BoundaryWalkerFsm::cross`. This keeps loci-fsm free
/// of host-specific credential schemas while retaining the boundary
/// walker's contract: every textual scalar is walked, validation is
/// recorded, the crossing is logged regardless of outcome.
pub(open) trait Crosser {
  /// All textual scalars the FSM should walk before validation.
  /// Each pair is `(field_key, value)`. Field keys should be stable
  /// dotted identifiers so downstream consumers can grep them.
  scalars(self : Self) -> Array[(String, String)]
  /// Validate the credential. Return a stable rejection tag on failure
  /// so replay always yields the same posture.
  validate(self : Self) -> CrossResult
  /// Stable id used in crossing reports.
  passport_id(self : Self) -> String
  /// Actor overlay (who is presenting the credential).
  actor_overlay(self : Self) -> String
  /// Target locus (what the actor is trying to enter).
  target_locus(self : Self) -> String
}

///|
pub fn cross_result_tag(r : CrossResult) -> String {
  match r {
    Admitted => "ADMITTED"
    Rejected(tag) => tag
  }
}
