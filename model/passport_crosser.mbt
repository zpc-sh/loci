///|
/// Adapter: implement the loci_fsm.Crosser trait for `Passport`. This
/// is the only place where the passport contract meets the FSM module,
/// so loci_fsm stays free of host-specific credential schemas.
impl @loci_fsm.Crosser for Passport with scalars(self : Passport) -> Array[
  (String, String),
] {
  [
    ("passport.kind", self.kind),
    ("passport.passport_id", self.passport_id),
    ("passport.who.overlay", self.who.overlay),
    ("passport.who.family", self.who.family),
    ("passport.who.session_surface", self.who.session_surface),
    ("passport.what.artifact_ref", self.what.artifact_ref),
    ("passport.why.note", self.why.note),
    ("passport.where.source_locus", self.where_.source_locus),
    ("passport.where.target_locus", self.where_.target_locus),
    ("passport.how_far.budget_class", self.how_far.budget_class),
    ("passport.trace.context_ref", self.trace.context_ref),
    ("passport.trace.lineage_ref", self.trace.lineage_ref),
  ]
}

///|
impl @loci_fsm.Crosser for Passport with validate(
  self : Passport,
) -> @loci_fsm.CrossResult {
  match self.validate() {
    Ok(_) => Admitted
    Err(e) => Rejected(passport_error_tag(e))
  }
}

///|
impl @loci_fsm.Crosser for Passport with passport_id(self : Passport) -> String {
  self.passport_id
}

///|
impl @loci_fsm.Crosser for Passport with actor_overlay(
  self : Passport,
) -> String {
  self.who.overlay
}

///|
impl @loci_fsm.Crosser for Passport with target_locus(
  self : Passport,
) -> String {
  self.where_.target_locus
}

///|
/// Deterministic textual tag for a passport validation error.
/// Stable so router policies can match on it.
pub fn passport_error_tag(e : PassportError) -> String {
  match e {
    BadKind => "BAD_KIND"
    BadVersion => "BAD_VERSION"
    MissingSection(section) => "MISSING_SECTION:" + section
    InvalidArtifactType => "INVALID_ARTIFACT_TYPE"
    InvalidIntent => "INVALID_INTENT"
    EmptyAllowedSurfaces => "EMPTY_ALLOWED_SURFACES"
    InvalidBoundaryMode => "INVALID_BOUNDARY_MODE"
    CapabilityIntentMismatch => "CAPABILITY_INTENT_MISMATCH"
    MissingSeal(field) => "MISSING_SEAL:" + field
  }
}
