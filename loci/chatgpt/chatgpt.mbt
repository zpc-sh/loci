///|
fn next_stage(stage : ChatgptStage) -> ChatgptStage {
  match stage {
    Form => Fruition
    Fruition => Aperture
    Aperture => Seal
    Seal => Form
  }
}

///|
fn non_blank(value : String) -> Bool {
  value.length() > 0
}

///|
fn has_ref(value : String?) -> Bool {
  match value {
    Some(v) => non_blank(v)
    None => false
  }
}

///|
fn coverage_bound(status : CoverageStatus, coverage_ref : String?) -> Bool {
  match status {
    Unknown => false
    _ => has_ref(coverage_ref)
  }
}

///|
pub fn WorkCycle::new() -> WorkCycle {
  { stage: Form, history: [Form] }
}

///|
pub fn WorkCycle::advance(self : WorkCycle) -> WorkCycle {
  let next = next_stage(self.stage)
  let history = self.history
  history.push(next)
  { stage: next, history }
}

///|
pub fn WorkCycle::is_cycle_closed(self : WorkCycle) -> Bool {
  self.stage == Form && self.history.length() > 1
}

///|
pub fn CrossingRecord::new(
  source_locus : String,
  target_locus : String,
  artifact_ref : String,
  intent : String,
  mode : BoundaryMode,
  seal? : String? = None,
) -> CrossingRecord {
  { source_locus, target_locus, artifact_ref, intent, mode, seal }
}

///|
pub fn CrossingRecord::is_complete(self : CrossingRecord) -> Bool {
  let has_source_target = non_blank(self.source_locus) &&
    non_blank(self.target_locus)
  let has_artifact_intent = non_blank(self.artifact_ref) &&
    non_blank(self.intent)
  let has_basics = has_source_target && has_artifact_intent
  if !has_basics {
    return false
  }
  match self.mode {
    Local => true
    Canonical | PublicMirror =>
      match self.seal {
        Some(value) => non_blank(value)
        None => false
      }
  }
}

///|
pub fn ProofObligation::new(
  obligation_id : String,
  required : Bool,
  status : ProofStatus,
) -> ProofObligation {
  { obligation_id, required, status }
}

///|
pub fn ProofObligation::is_discharged(self : ProofObligation) -> Bool {
  match self.status {
    Proved | CoveredByEvidence | Reviewed | Waived => true
    Open | Blocked | Failed => false
  }
}

///|
pub fn ContractBinding::new(
  contract_id : String,
  test_result_ref : String?,
  coverage_ref : String?,
  proof_ref : String?,
  coverage_status : CoverageStatus,
  side_effect_status : SideEffectStatus,
  obligations : Array[ProofObligation],
) -> ContractBinding {
  {
    contract_id,
    test_result_ref,
    coverage_ref,
    proof_ref,
    coverage_status,
    side_effect_status,
    obligations,
  }
}

///|
pub fn ContractBinding::is_bound(self : ContractBinding) -> Bool {
  if !non_blank(self.contract_id) {
    return false
  }
  if !has_ref(self.test_result_ref) {
    return false
  }
  if !has_ref(self.proof_ref) {
    return false
  }
  if !coverage_bound(self.coverage_status, self.coverage_ref) {
    return false
  }
  match self.side_effect_status {
    Observed | NotRequired => true
    BlockedEffect => false
  }
}

///|
pub fn ContractBinding::required_open_count(self : ContractBinding) -> Int {
  let mut count = 0
  for obligation in self.obligations {
    if obligation.required && !obligation.is_discharged() {
      count = count + 1
    }
  }
  count
}

///|
pub fn ContractBinding::can_seal(self : ContractBinding) -> Bool {
  self.is_bound() && self.required_open_count() == 0
}
