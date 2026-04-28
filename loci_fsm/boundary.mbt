///|
/// Boundary FSM lifecycle states.
///
/// `Crossing` is entered when a Crosser (e.g. Locus Crossing Passport)
/// is presented at the membrane. It is distinct from `Walking` (scalar
/// inspection) because crossings carry authority material that must be
/// validated, not merely scanned.
pub(all) enum BoundaryFsmState {
  Idle
  Walking
  Crossing
  Marked
  Emitted
  Failed
} derive(Eq, Debug)

///|
pub impl Show for BoundaryFsmState with output(self, logger) {
  logger.write_string(boundary_state_text(self))
}

///|
/// Boundary posture outcome emitted by the FSM.
pub(all) enum BoundaryStatus {
  Clean
  Attention
  Containment
} derive(Eq, Debug)

///|
pub impl Show for BoundaryStatus with output(self, logger) {
  logger.write_string(boundary_status_text(self))
}

///|
/// One scalar finding produced while walking Merkin-boundary fields.
pub(all) struct BoundaryFinding {
  field_key : String
  raw_value : String
  canonical_value : String
  raw_hex : String
  ghost_u200b : UInt
  ghost_u200c : UInt
  ghost_ufeff : UInt
  bidi_controls : UInt
  ascii_controls : UInt
  suspicious : Bool
} derive(Debug)

///|
/// Per-crossing outcome recorded by the FSM.
pub(all) struct CrossingReport {
  passport_id : String
  actor_overlay : String
  target_locus : String
  admitted : Bool
  rejection : String?
} derive(Debug)

///|
/// Locality ingest report for repeated patterned material.
///
/// The report models inertial diff posture:
/// - `stable_fields`: fields unchanged from the last ingest in this locality
/// - `changed_fields`: fields that changed value
/// - `new_fields`: fields first observed in locality history
/// - `duplicate`: true when the full locality signature is unchanged
pub(all) struct LocalityIngestReport {
  locality : String
  field_total : UInt
  stable_fields : UInt
  changed_fields : UInt
  new_fields : UInt
  duplicate : Bool
  inertia_percent : UInt
  prior_signature : String
  current_signature : String
} derive(Debug)

///|
/// Deterministic boundary walker + marker FSM with attached cave.
///
/// The cave records every transition arc the FSM moves through plus any
/// notable artifact (findings, crossings, final stigmergy). Consumers
/// drain the cave for bulk collection.
pub(all) struct BoundaryWalkerFsm {
  actor_overlay : String
  ratio_loci : String
  state : BoundaryFsmState
  walked_scalars : UInt
  findings : Array[BoundaryFinding]
  sanitized_scalars : UInt
  ghost_u200b : UInt
  ghost_u200c : UInt
  ghost_ufeff : UInt
  bidi_controls : UInt
  ascii_controls : UInt
  crossings : Array[CrossingReport]
  locality_signatures : Map[String, String]
  locality_field_values : Map[String, String]
  locality_ingests : UInt
  locality_dedup_hits : UInt
  cave : FsmCave
} derive(Debug)

///|
pub fn BoundaryWalkerFsm::new(
  actor_overlay : String,
  ratio_loci : String,
) -> BoundaryWalkerFsm {
  let actor = fsm_sanitize_line(actor_overlay)
  let loci = fsm_sanitize_line(ratio_loci)
  {
    actor_overlay: actor,
    ratio_loci: loci,
    state: Idle,
    walked_scalars: 0U,
    findings: [],
    sanitized_scalars: 0U,
    ghost_u200b: 0U,
    ghost_u200c: 0U,
    ghost_ufeff: 0U,
    bidi_controls: 0U,
    ascii_controls: 0U,
    crossings: [],
    locality_signatures: {},
    locality_field_values: {},
    locality_ingests: 0U,
    locality_dedup_hits: 0U,
    cave: FsmCave::new(actor + "@" + loci, "boundary-walker-v0"),
  }
}

///|
/// Walk one scalar field and mark suspicious boundary content.
pub fn BoundaryWalkerFsm::walk_scalar(
  self : BoundaryWalkerFsm,
  field_key : String,
  value : String,
) -> BoundaryWalkerFsm {
  let normalized_key = fsm_sanitize_line(field_key)
  let scan = scan_scalar(value)
  let finding : BoundaryFinding = {
    field_key: normalized_key,
    raw_value: value,
    canonical_value: scan.canonical,
    raw_hex: scan.raw_hex,
    ghost_u200b: scan.ghost_u200b,
    ghost_u200c: scan.ghost_u200c,
    ghost_ufeff: scan.ghost_ufeff,
    bidi_controls: scan.bidi_controls,
    ascii_controls: scan.ascii_controls,
    suspicious: scan.suspicious,
  }
  let findings = if finding.suspicious {
    self.findings + [finding]
  } else {
    self.findings
  }
  let from_state = boundary_state_text(self.state)
  let next_state = match self.state {
    Idle => Walking
    Walking => Walking
    Crossing => Walking
    Marked => Marked
    Emitted => Walking
    Failed => Failed
  }
  let to_state = boundary_state_text(next_state)
  let cave = self.cave.tick()
  let cave = if finding.suspicious {
    cave.deposit(
      kind="finding",
      key=normalized_key,
      value=scan.canonical,
      from_state~,
      to_state~,
    )
  } else {
    cave.deposit(
      kind="walk",
      key=normalized_key,
      value=scan.canonical,
      from_state~,
      to_state~,
    )
  }
  {
    ..self,
    state: next_state,
    walked_scalars: self.walked_scalars + 1U,
    findings,
    sanitized_scalars: self.sanitized_scalars +
    (if scan.sanitized { 1U } else { 0U }),
    ghost_u200b: self.ghost_u200b + scan.ghost_u200b,
    ghost_u200c: self.ghost_u200c + scan.ghost_u200c,
    ghost_ufeff: self.ghost_ufeff + scan.ghost_ufeff,
    bidi_controls: self.bidi_controls + scan.bidi_controls,
    ascii_controls: self.ascii_controls + scan.ascii_controls,
    cave,
  }
}

///|
/// Walk many scalar fields.
pub fn BoundaryWalkerFsm::walk_scalars(
  self : BoundaryWalkerFsm,
  fields : Array[(String, String)],
) -> BoundaryWalkerFsm {
  let mut cur = self
  for pair in fields {
    let key = pair.0
    let value = pair.1
    cur = cur.walk_scalar(key, value)
  }
  cur
}

///|
/// Mark walk complete before emission.
pub fn BoundaryWalkerFsm::mark(self : BoundaryWalkerFsm) -> BoundaryWalkerFsm {
  let from_state = boundary_state_text(self.state)
  let next_state = match self.state {
    BoundaryFsmState::Failed => BoundaryFsmState::Failed
    _ => BoundaryFsmState::Marked
  }
  let to_state = boundary_state_text(next_state)
  let cave = self.cave.deposit(
    kind="transition",
    key="mark",
    value="ready-to-emit",
    from_state~,
    to_state~,
  )
  { ..self, state: next_state, cave }
}

///|
/// Evaluate a Crosser at the membrane. The FSM:
///   1. Walks every textual scalar of the credential so hidden ghost
///      bytes or bidi controls in authority material are surfaced as
///      findings.
///   2. Runs `Crosser::validate` to check shape and cross-field
///      invariants.
///   3. Records a `CrossingReport` regardless of outcome so replay
///      always sees every attempted crossing.
///
/// This method does not issue a command; it only produces posture.
/// Router policy evaluates `crossings` + `findings` and decides
/// allow/narrow/sandbox/quarantine/deny downstream.
pub fn BoundaryWalkerFsm::cross(
  self : BoundaryWalkerFsm,
  crosser : &Crosser,
) -> BoundaryWalkerFsm {
  let walked = self.walk_scalars(crosser.scalars())
  let (admitted, rejection) = match crosser.validate() {
    Admitted => (true, None)
    Rejected(tag) => (false, Some(tag))
  }
  let report : CrossingReport = {
    passport_id: fsm_sanitize_line(crosser.passport_id()),
    actor_overlay: fsm_sanitize_line(crosser.actor_overlay()),
    target_locus: fsm_sanitize_line(crosser.target_locus()),
    admitted,
    rejection,
  }
  let from_state = boundary_state_text(walked.state)
  let next_state = match walked.state {
    BoundaryFsmState::Failed => BoundaryFsmState::Failed
    _ => BoundaryFsmState::Crossing
  }
  let to_state = boundary_state_text(next_state)
  let cave = walked.cave.deposit(
    kind="crossing",
    key=report.passport_id,
    value=if admitted {
      "admitted"
    } else {
      match rejection {
        Some(tag) => "rejected:" + tag
        None => "rejected"
      }
    },
    from_state~,
    to_state~,
  )
  { ..walked, state: next_state, crossings: walked.crossings + [report], cave }
}

///|
/// Locality-aware ingest of patterned fields.
///
/// This path is optimized for repeated scans of the same patterned file
/// or contract source. It performs a full scalar walk (so boundary posture
/// still updates), then computes an inertial diff against locality memory.
pub fn BoundaryWalkerFsm::ingest_locality_pattern(
  self : BoundaryWalkerFsm,
  locality : String,
  fields : Array[(String, String)],
) -> (BoundaryWalkerFsm, LocalityIngestReport) {
  let loc = fsm_sanitize_line(locality)
  let walked = self.walk_scalars(fields)

  let mut stable_fields = 0U
  let mut changed_fields = 0U
  let mut new_fields = 0U
  let signatures : Array[String] = []
  let next_field_values = walked.locality_field_values

  for pair in fields {
    let key = fsm_sanitize_line(pair.0)
    let scan = scan_scalar(pair.1)
    let canonical = scan.canonical
    let field_ref = locality_field_ref(loc, key)
    signatures.push(key + "=" + canonical)
    match walked.locality_field_values.get(field_ref) {
      Some(prev) =>
        if prev == canonical {
          stable_fields = stable_fields + 1U
        } else {
          changed_fields = changed_fields + 1U
        }
      None => new_fields = new_fields + 1U
    }
    next_field_values[field_ref] = canonical
  }

  signatures.sort()
  let current_signature = diff_join(signatures, "|")
  let prior_signature = match walked.locality_signatures.get(loc) {
    Some(sig) => sig
    None => "none"
  }
  let duplicate = prior_signature == current_signature
  let field_total = fields.length().reinterpret_as_uint()
  let inertia_percent = if field_total == 0U {
    100U
  } else {
    stable_fields * 100U / field_total
  }

  let next_signatures = walked.locality_signatures
  next_signatures[loc] = current_signature

  let from_state = boundary_state_text(walked.state)
  let to_state = from_state
  let kind = if duplicate { "locality-dedup" } else { "locality-ingest" }
  let value = "inertia=" +
    inertia_percent.to_string() +
    ";stable=" +
    stable_fields.to_string() +
    ";changed=" +
    changed_fields.to_string() +
    ";new=" +
    new_fields.to_string()
  let cave = walked.cave.deposit(kind~, key=loc, value~, from_state~, to_state~)

  let next = {
    ..walked,
    locality_signatures: next_signatures,
    locality_field_values: next_field_values,
    locality_ingests: walked.locality_ingests + 1U,
    locality_dedup_hits: walked.locality_dedup_hits +
    (if duplicate { 1U } else { 0U }),
    cave,
  }
  let report : LocalityIngestReport = {
    locality: loc,
    field_total,
    stable_fields,
    changed_fields,
    new_fields,
    duplicate,
    inertia_percent,
    prior_signature,
    current_signature,
  }
  (next, report)
}

///|
pub fn BoundaryWalkerFsm::status(self : BoundaryWalkerFsm) -> BoundaryStatus {
  if self.bidi_controls > 0U || self.ascii_controls > 0U {
    Containment
  } else if self.ghost_u200b > 0U ||
    self.ghost_u200c > 0U ||
    self.ghost_ufeff > 0U {
    Attention
  } else {
    Clean
  }
}

///|
fn boundary_state_text(state : BoundaryFsmState) -> String {
  match state {
    Idle => "idle"
    Walking => "walking"
    Crossing => "crossing"
    Marked => "marked"
    Emitted => "emitted"
    Failed => "failed"
  }
}

///|
fn locality_field_ref(locality : String, key : String) -> String {
  locality + "::" + key
}

///|
fn diff_join(items : Array[String], sep : String) -> String {
  let builder = StringBuilder::new()
  for i = 0; i < items.length(); i = i + 1 {
    if i > 0 {
      builder.write_string(sep)
    }
    builder.write_string(items[i])
  }
  let out = builder.to_string()
  if out == "" {
    "none"
  } else {
    out
  }
}

///|
pub fn boundary_status_text(status : BoundaryStatus) -> String {
  match status {
    Clean => "clean"
    Attention => "attention"
    Containment => "containment"
  }
}
