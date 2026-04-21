///|
/// Locus Crossing Passport v0.1.
/// Contract: `merkin.locus.crossing.passport` / `v0.1`.
///
/// A passport is the minimum authority surface an intelligence must
/// carry to cross from one locus into another and perform work. It
/// is strict on shape and trust envelope, flexible on intent.
///
/// Pairs with the Adjoin Contract: the adjoin expression defines
/// topology; the passport defines active authority for an action
/// against that topology.
pub(all) struct Passport {
  kind : String
  version : String
  passport_id : String
  who : PassportWho
  what : PassportWhat
  why : PassportWhy
  where_ : PassportWhere
  how_far : PassportHowFar
  trace : PassportTrace
} derive(Show)

///|
/// `who`: actor identity and attestation.
pub(all) struct PassportWho {
  overlay : String
  family : String
  session_surface : String
  fingerprint_commitment : @hash.Hash
  actor_seal : @hash.Hash
} derive(Show)

///|
/// `what`: artifact class entering the target locus.
pub(all) struct PassportWhat {
  artifact_type : ArtifactType
  artifact_ref : String
} derive(Show)

///|
/// `why`: crossing intent.
pub(all) struct PassportWhy {
  intent : Intent
  note : String
} derive(Show)

///|
/// `where`: source/target loci plus allowed target surfaces.
pub(all) struct PassportWhere {
  source_locus : String
  target_locus : String
  allowed_surfaces : Array[String]
} derive(Show)

///|
/// `how_far`: capability budget and boundary policy.
pub(all) struct PassportHowFar {
  capability_class : CapabilityClass
  budget_class : String
  boundary_mode : BoundaryMode
} derive(Show)

///|
/// `trace`: replay and provenance references.
pub(all) struct PassportTrace {
  context_ref : String
  lineage_ref : String
  passport_seal : @hash.Hash
} derive(Show)

///|
/// Artifact classes permitted to cross. Extensible at the contract
/// level; unknown values surface as `INVALID_ARTIFACT_TYPE`.
pub(all) enum ArtifactType {
  Spec
  Plan
  Design
  Patch
  Signal
  Report
  Bundle
} derive(Eq, Show)

///|
/// Crossing intents. Intent `Implement` requires a capability class
/// that allows writes; `Patch` artifacts require intent
/// `Implement` or `Verify`.
pub(all) enum Intent {
  Observe
  Propose
  Implement
  Verify
  Synthesize
  Audit
} derive(Eq, Show)

///|
/// Boundary policy modes the membrane will apply at crossing.
pub(all) enum BoundaryMode {
  Observe_
  Sanitize
  Strict
  Quarantine
} derive(Eq, Show)

///|
/// Capability classes. `ReadOnly` forbids `Implement` intent.
/// `PatchVerify` / `Full` allow writes.
pub(all) enum CapabilityClass {
  ReadOnly
  PatchVerify
  Full
} derive(Eq, Show)

///|
/// Structured validation errors per `LOCUS_CROSSING_PASSPORT_v0.1`.
pub(all) enum PassportError {
  BadKind
  BadVersion
  MissingSection(String)
  InvalidArtifactType
  InvalidIntent
  EmptyAllowedSurfaces
  InvalidBoundaryMode
  CapabilityIntentMismatch
  MissingSeal(String)
} derive(Eq, Show)

///|
/// Construct a passport and compute its seal from the material of
/// all six sections. The caller passes the passport_seal explicitly
/// (so an external issuer signature can be carried), but the
/// validator checks only that it is non-empty.
pub fn Passport::new(
  passport_id : String,
  who : PassportWho,
  what : PassportWhat,
  why : PassportWhy,
  where_ : PassportWhere,
  how_far : PassportHowFar,
  trace : PassportTrace,
) -> Passport {
  {
    kind: passport_kind(),
    version: passport_version(),
    passport_id,
    who,
    what,
    why,
    where_,
    how_far,
    trace,
  }
}

///|
/// Canonical kind tag.
pub fn passport_kind() -> String {
  "merkin.locus.crossing.passport"
}

///|
/// Canonical version tag.
pub fn passport_version() -> String {
  "v0.1"
}

///|
/// Validate shape and cross-field invariants. Returns `Ok(())` if
/// the passport is structurally admissible for router evaluation.
/// Router policy decisions (allow/narrow/sandbox/quarantine/deny)
/// are made elsewhere.
pub fn Passport::validate(
  self : Passport,
) -> Result[Unit, PassportError] {
  if self.kind != passport_kind() {
    return Err(BadKind)
  }
  if self.version != passport_version() {
    return Err(BadVersion)
  }
  if self.passport_id == "" {
    return Err(MissingSection("passport_id"))
  }
  // who: all textual fields required; seals must be non-empty.
  if self.who.overlay == "" {
    return Err(MissingSection("who.overlay"))
  }
  if self.who.family == "" {
    return Err(MissingSection("who.family"))
  }
  if self.who.session_surface == "" {
    return Err(MissingSection("who.session_surface"))
  }
  if hash_is_empty(self.who.fingerprint_commitment) {
    return Err(MissingSeal("who.fingerprint_commitment"))
  }
  if hash_is_empty(self.who.actor_seal) {
    return Err(MissingSeal("who.actor_seal"))
  }
  // what
  if self.what.artifact_ref == "" {
    return Err(MissingSection("what.artifact_ref"))
  }
  // why: enum is constrained by type; note is advisory.
  let _ = self.why.note
  // where
  if self.where_.source_locus == "" {
    return Err(MissingSection("where.source_locus"))
  }
  if self.where_.target_locus == "" {
    return Err(MissingSection("where.target_locus"))
  }
  if self.where_.allowed_surfaces.length() == 0 {
    return Err(EmptyAllowedSurfaces)
  }
  // how_far
  if self.how_far.budget_class == "" {
    return Err(MissingSection("how_far.budget_class"))
  }
  // trace
  if self.trace.context_ref == "" {
    return Err(MissingSection("trace.context_ref"))
  }
  if self.trace.lineage_ref == "" {
    return Err(MissingSection("trace.lineage_ref"))
  }
  if hash_is_empty(self.trace.passport_seal) {
    return Err(MissingSeal("trace.passport_seal"))
  }
  // Cross-field: patch artifacts require implement|verify.
  match self.what.artifact_type {
    Patch =>
      match self.why.intent {
        Implement => ()
        Verify => ()
        _ => return Err(InvalidIntent)
      }
    _ => ()
  }
  // Cross-field: implement intent requires writable capability.
  match self.why.intent {
    Implement =>
      match self.how_far.capability_class {
        ReadOnly => return Err(CapabilityIntentMismatch)
        _ => ()
      }
    _ => ()
  }
  Ok(())
}

///|
/// Deterministic seal material over the full passport. This is what
/// a caller would hash to produce `trace.passport_seal` externally.
pub fn Passport::seal_material(self : Passport) -> @hash.Hash {
  let b = StringBuilder::new(size_hint=1024)
  b.write_string(self.kind)
  b.write_string("|")
  b.write_string(self.version)
  b.write_string("|")
  b.write_string(self.passport_id)
  b.write_string("|who=")
  b.write_string(self.who.overlay)
  b.write_string(";")
  b.write_string(self.who.family)
  b.write_string(";")
  b.write_string(self.who.session_surface)
  b.write_string(";")
  b.write_string(self.who.fingerprint_commitment.key())
  b.write_string(";")
  b.write_string(self.who.actor_seal.key())
  b.write_string("|what=")
  b.write_string(artifact_type_tag(self.what.artifact_type))
  b.write_string(";")
  b.write_string(self.what.artifact_ref)
  b.write_string("|why=")
  b.write_string(intent_tag(self.why.intent))
  b.write_string(";")
  b.write_string(self.why.note)
  b.write_string("|where=")
  b.write_string(self.where_.source_locus)
  b.write_string(";")
  b.write_string(self.where_.target_locus)
  b.write_string(";")
  b.write_string(join_surfaces(self.where_.allowed_surfaces))
  b.write_string("|how_far=")
  b.write_string(capability_class_tag(self.how_far.capability_class))
  b.write_string(";")
  b.write_string(self.how_far.budget_class)
  b.write_string(";")
  b.write_string(boundary_mode_tag(self.how_far.boundary_mode))
  b.write_string("|trace=")
  b.write_string(self.trace.context_ref)
  b.write_string(";")
  b.write_string(self.trace.lineage_ref)
  @hash.Hash::of_bytes(passport_string_to_bytes(b.to_string()))
}

///|
/// Tag for `ArtifactType` on the wire.
pub fn artifact_type_tag(t : ArtifactType) -> String {
  match t {
    Spec => "spec"
    Plan => "plan"
    Design => "design"
    Patch => "patch"
    Signal => "signal"
    Report => "report"
    Bundle => "bundle"
  }
}

///|
/// Tag for `Intent` on the wire.
pub fn intent_tag(i : Intent) -> String {
  match i {
    Observe => "observe"
    Propose => "propose"
    Implement => "implement"
    Verify => "verify"
    Synthesize => "synthesize"
    Audit => "audit"
  }
}

///|
/// Tag for `BoundaryMode` on the wire.
pub fn boundary_mode_tag(m : BoundaryMode) -> String {
  match m {
    Observe_ => "observe"
    Sanitize => "sanitize"
    Strict => "strict"
    Quarantine => "quarantine"
  }
}

///|
/// Tag for `CapabilityClass` on the wire.
pub fn capability_class_tag(c : CapabilityClass) -> String {
  match c {
    ReadOnly => "read-only"
    PatchVerify => "patch+verify"
    Full => "full"
  }
}

///|
/// Parse artifact type from the wire tag.
pub fn artifact_type_parse(tag : String) -> ArtifactType? {
  match tag {
    "spec" => Some(Spec)
    "plan" => Some(Plan)
    "design" => Some(Design)
    "patch" => Some(Patch)
    "signal" => Some(Signal)
    "report" => Some(Report)
    "bundle" => Some(Bundle)
    _ => None
  }
}

///|
/// Parse intent from the wire tag.
pub fn intent_parse(tag : String) -> Intent? {
  match tag {
    "observe" => Some(Observe)
    "propose" => Some(Propose)
    "implement" => Some(Implement)
    "verify" => Some(Verify)
    "synthesize" => Some(Synthesize)
    "audit" => Some(Audit)
    _ => None
  }
}

///|
/// Parse boundary mode from the wire tag.
pub fn boundary_mode_parse(tag : String) -> BoundaryMode? {
  match tag {
    "observe" => Some(Observe_)
    "sanitize" => Some(Sanitize)
    "strict" => Some(Strict)
    "quarantine" => Some(Quarantine)
    _ => None
  }
}

///|
/// Parse capability class from the wire tag.
pub fn capability_class_parse(tag : String) -> CapabilityClass? {
  match tag {
    "read-only" => Some(ReadOnly)
    "patch+verify" => Some(PatchVerify)
    "full" => Some(Full)
    _ => None
  }
}

///|
fn hash_is_empty(h : @hash.Hash) -> Bool {
  h.digest_len() == 0
}

///|
fn join_surfaces(surfaces : Array[String]) -> String {
  if surfaces.length() == 0 {
    return ""
  }
  let mut out = surfaces[0]
  for i = 1; i < surfaces.length(); i = i + 1 {
    out = out + "," + surfaces[i]
  }
  out
}

///|
fn passport_string_to_bytes(s : String) -> Bytes {
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
