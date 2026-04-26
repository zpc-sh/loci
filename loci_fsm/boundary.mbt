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
} derive(Eq, Show)

///|
/// Boundary posture outcome emitted by the FSM.
pub(all) enum BoundaryStatus {
  Clean
  Attention
  Containment
} derive(Eq, Show)

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
} derive(Show)

///|
/// Per-crossing outcome recorded by the FSM.
pub(all) struct CrossingReport {
  passport_id : String
  actor_overlay : String
  target_locus : String
  admitted : Bool
  rejection : String?
} derive(Show)

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
  cave : FsmCave
} derive(Show)

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
  {
    ..walked,
    state: next_state,
    crossings: walked.crossings + [report],
    cave,
  }
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
pub fn boundary_status_text(status : BoundaryStatus) -> String {
  match status {
    Clean => "clean"
    Attention => "attention"
    Containment => "containment"
  }
}
