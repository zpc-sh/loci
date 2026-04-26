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
