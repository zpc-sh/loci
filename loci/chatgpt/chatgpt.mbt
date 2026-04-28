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
fn proof_gate_has_required_open(
  obligation : ProofObligation,
) -> Bool where {
  proof_ensure: result => {
    result == (obligation.required && !obligation.is_discharged())
  },
} {
  let actionable = obligation.required && !obligation.is_discharged()
  proof_assert actionable ==
    (obligation.required && !obligation.is_discharged())
  actionable
}

///|
fn directive_value(line : String, key : String) -> String? {
  let prefix = "@" + key + " "
  if !line.has_prefix(prefix) {
    return None
  }
  match line.strip_prefix(prefix) {
    Some(rest) => {
      let value = rest.trim().to_string()
      if non_blank(value) {
        Some(value)
      } else {
        None
      }
    }
    None => None
  }
}

///|
fn parse_solver_status(value : String) -> SolverStatus {
  match value {
    "none" => NotRequested
    "queued" => Queued
    "running" => Running
    "completed" => Completed
    "failed" => Failed
    "timed_out" => TimedOut
    "invalid_input" => InvalidInput
    "unsupported" => Unsupported
    _ => NotRequested
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
pub fn SolverReceipt::new(
  solver : String,
  solver_job : String,
  status : SolverStatus,
  receipt_ref : String?,
  proof_artifact_ref : String?,
) -> SolverReceipt {
  { solver, solver_job, status, receipt_ref, proof_artifact_ref }
}

///|
pub fn SolverReceipt::is_verified(
  self : SolverReceipt,
) -> Bool where {
  proof_ensure: result => {
    result ==
    (
      self.status == Completed &&
      non_blank(self.solver) &&
      non_blank(self.solver_job) &&
      has_ref(self.receipt_ref)
    )
  },
} {
  if self.status != Completed {
    return false
  }
  let core_fields_present = non_blank(self.solver) && non_blank(self.solver_job)
  let receipt_present = has_ref(self.receipt_ref)
  let verified = core_fields_present && receipt_present
  proof_assert verified ==
    (
      self.status == Completed &&
      non_blank(self.solver) &&
      non_blank(self.solver_job) &&
      has_ref(self.receipt_ref)
    )
  verified
}

///|
pub fn ContractDirectiveMini::new(
  contract_id : String,
  pattern : String,
  claim : String,
  ready : Bool,
  oracle : String,
  solver? : String? = None,
  solver_job? : String? = None,
  solver_status? : SolverStatus = NotRequested,
  solver_receipt? : String? = None,
) -> ContractDirectiveMini {
  {
    contract_id,
    pattern,
    claim,
    ready,
    oracle,
    solver,
    solver_job,
    solver_status,
    solver_receipt,
  }
}

///|
pub fn ContractDirectiveMini::to_solver_receipt(
  self : ContractDirectiveMini,
  proof_artifact_ref : String?,
) -> SolverReceipt? {
  match self.solver {
    None => None
    Some(solver_name) =>
      match self.solver_job {
        None => None
        Some(job_id) =>
          Some(
            SolverReceipt::new(
              solver_name,
              job_id,
              self.solver_status,
              self.solver_receipt,
              proof_artifact_ref,
            ),
          )
      }
  }
}

///|
pub fn ContractDirectiveMini::ready_gate(
  self : ContractDirectiveMini,
) -> Bool where {
  proof_ensure: result => {
    result ==
    (
      !self.ready ||
      !has_ref(self.solver) ||
      (
        self.solver_status == Completed &&
        has_ref(self.solver_job) &&
        has_ref(self.solver_receipt)
      )
    )
  },
} {
  if !self.ready {
    return true
  }
  let solver_requested = has_ref(self.solver)
  if !solver_requested {
    return true
  }
  let gate_passed = self.solver_status == Completed &&
    has_ref(self.solver_job) &&
    has_ref(self.solver_receipt)
  proof_assert gate_passed ==
    (
      self.solver_status == Completed &&
      has_ref(self.solver_job) &&
      has_ref(self.solver_receipt)
    )
  gate_passed
}

///|
pub fn ContractDirectiveMini::from_directive_lines(
  lines : Array[String],
) -> ContractDirectiveMini? {
  let mut contract_id : String? = None
  let mut pattern : String? = None
  let mut claim : String? = None
  let mut oracle : String? = None
  let mut ready = false
  let mut solver : String? = None
  let mut solver_job : String? = None
  let mut solver_status = NotRequested
  let mut solver_receipt : String? = None

  for line in lines {
    match directive_value(line, "contract") {
      Some(v) => contract_id = Some(v)
      None => ()
    }
    match directive_value(line, "pattern") {
      Some(v) => pattern = Some(v)
      None => ()
    }
    match directive_value(line, "claim") {
      Some(v) => claim = Some(v)
      None => ()
    }
    match directive_value(line, "oracle") {
      Some(v) => oracle = Some(v)
      None => ()
    }
    match directive_value(line, "ready") {
      Some(v) => ready = v == "true"
      None => ()
    }
    match directive_value(line, "solver") {
      Some(v) => solver = Some(v)
      None => ()
    }
    match directive_value(line, "solver_job") {
      Some(v) => solver_job = Some(v)
      None => ()
    }
    match directive_value(line, "solver_status") {
      Some(v) => solver_status = parse_solver_status(v)
      None => ()
    }
    match directive_value(line, "solver_receipt") {
      Some(v) => solver_receipt = Some(v)
      None => ()
    }
  }

  let contract_id = match contract_id {
    Some(v) => v
    None => return None
  }
  let pattern = match pattern {
    Some(v) => v
    None => return None
  }
  let claim = match claim {
    Some(v) => v
    None => return None
  }
  let oracle = match oracle {
    Some(v) => v
    None => return None
  }
  Some(
    ContractDirectiveMini::new(
      contract_id,
      pattern,
      claim,
      ready,
      oracle,
      solver~,
      solver_job~,
      solver_status~,
      solver_receipt~,
    ),
  )
}

///|
fn kv_upsert(
  entries : Array[(String, SolverReceipt)],
  key : String,
  value : SolverReceipt,
) -> Array[(String, SolverReceipt)] {
  let updated : Array[(String, SolverReceipt)] = []
  let mut replaced = false
  for entry in entries {
    if entry.0 == key {
      updated.push((key, value))
      replaced = true
    } else {
      updated.push(entry)
    }
  }
  if !replaced {
    updated.push((key, value))
  }
  updated
}

///|
fn kv_lookup(
  entries : Array[(String, SolverReceipt)],
  key : String,
) -> SolverReceipt? {
  for entry in entries {
    if entry.0 == key {
      return Some(entry.1)
    }
  }
  None
}

///|
pub fn SolverResultHandler::new() -> SolverResultHandler {
  { dropbox: [], kv_store: [] }
}

///|
pub fn SolverResultHandler::dropbox_count(self : SolverResultHandler) -> Int {
  self.dropbox.length()
}

///|
pub fn SolverResultHandler::kv_count(self : SolverResultHandler) -> Int {
  self.kv_store.length()
}

///|
pub fn SolverResultHandler::kv_get(
  self : SolverResultHandler,
  key : String,
) -> SolverReceipt? {
  kv_lookup(self.kv_store, key)
}

///|
pub fn SolverClientResult::new(
  contract_id : String,
  solver : String,
  solver_job : String,
  solver_status : SolverStatus,
  solver_receipt_ref : String?,
  proof_artifact_ref : String?,
) -> SolverClientResult {
  {
    contract_id,
    solver,
    solver_job,
    solver_status,
    solver_receipt_ref,
    proof_artifact_ref,
  }
}

///|
pub fn SolverClientResult::to_solver_receipt(
  self : SolverClientResult,
) -> SolverReceipt {
  SolverReceipt::new(
    self.solver,
    self.solver_job,
    self.solver_status,
    self.solver_receipt_ref,
    self.proof_artifact_ref,
  )
}

///|
pub fn SolverResultHandler::ingest(
  self : SolverResultHandler,
  binding : ContractBinding,
  contract_id : String,
  receipt : SolverReceipt,
  route? : SolverResultRoute = DropboxAndKv,
) -> (SolverResultHandler, SolverIngestResult) {
  if !non_blank(contract_id) {
    return (
      self,
      {
        accepted: false,
        can_seal_now: false,
        reason: Some("missing_contract_id"),
        kv_key: None,
      },
    )
  }
  if contract_id != binding.contract_id {
    return (
      self,
      {
        accepted: false,
        can_seal_now: false,
        reason: Some("contract_id_mismatch"),
        kv_key: None,
      },
    )
  }
  if !receipt.is_verified() {
    return (
      self,
      {
        accepted: false,
        can_seal_now: false,
        reason: Some("invalid_solver_receipt"),
        kv_key: None,
      },
    )
  }

  let next_dropbox = self.dropbox
  let mut next_kv = self.kv_store
  let mut kv_key : String? = None
  match route {
    DropboxOnly => next_dropbox.push(receipt)
    KvOnly => {
      next_kv = kv_upsert(next_kv, receipt.solver_job, receipt)
      kv_key = Some(receipt.solver_job)
    }
    DropboxAndKv => {
      next_dropbox.push(receipt)
      next_kv = kv_upsert(next_kv, receipt.solver_job, receipt)
      kv_key = Some(receipt.solver_job)
    }
  }

  let next_handler = { dropbox: next_dropbox, kv_store: next_kv }
  let can_seal_now = binding.can_seal_with_solver(Some(receipt))
  let reason = if can_seal_now {
    None
  } else {
    Some("binding_not_sealable_yet")
  }
  (next_handler, { accepted: true, can_seal_now, reason, kv_key })
}

///|
pub fn SolverResultHandler::ingest_client_result(
  self : SolverResultHandler,
  binding : ContractBinding,
  client_result : SolverClientResult,
  route? : SolverResultRoute = DropboxAndKv,
) -> (SolverResultHandler, SolverIngestResult) {
  self.ingest(
    binding,
    client_result.contract_id,
    client_result.to_solver_receipt(),
    route~,
  )
}

///|
pub fn SolverResultHandler::ingest_http_directive_lines(
  self : SolverResultHandler,
  binding : ContractBinding,
  lines : Array[String],
  route? : SolverResultRoute = DropboxAndKv,
) -> (SolverResultHandler, SolverIngestResult) {
  let directive = match ContractDirectiveMini::from_directive_lines(lines) {
    None =>
      return (
        self,
        {
          accepted: false,
          can_seal_now: false,
          reason: Some("invalid_directive_payload"),
          kv_key: None,
        },
      )
    Some(v) => v
  }
  let receipt = match directive.to_solver_receipt(binding.proof_ref) {
    None =>
      return (
        self,
        {
          accepted: false,
          can_seal_now: false,
          reason: Some("missing_solver_receipt_payload"),
          kv_key: None,
        },
      )
    Some(v) => v
  }
  self.ingest(binding, directive.contract_id, receipt, route~)
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
pub fn ContractBinding::required_open_count(
  self : ContractBinding,
) -> Int where {
  proof_ensure: result => result >= 0,
  proof_ensure: result => result <= self.obligations.length(),
} {
  let mut count = 0
  for obligation in self.obligations {
    if proof_gate_has_required_open(obligation) {
      proof_assert count < self.obligations.length()
      count = count + 1
      proof_assert count <= self.obligations.length()
    }
  }
  count
}

///|
pub fn ContractBinding::actionable_obligations(
  self : ContractBinding,
) -> Array[ProofObligation] where {
  proof_ensure: result => result.length() <= self.obligations.length(),
} {
  let actionable : Array[ProofObligation] = []
  for obligation in self.obligations {
    if proof_gate_has_required_open(obligation) {
      actionable.push(obligation)
      proof_assert actionable.length() <= self.obligations.length()
    }
  }
  actionable
}

///|
pub fn ContractBinding::can_seal(self : ContractBinding) -> Bool {
  self.is_bound() && self.actionable_obligations().length() == 0
}

///|
pub fn ContractBinding::can_seal_with_solver(
  self : ContractBinding,
  solver_receipt : SolverReceipt?,
) -> Bool where {
  proof_ensure: result => !result || self.can_seal(),
} {
  if !self.can_seal() {
    return false
  }
  match solver_receipt {
    None => true
    Some(receipt) => {
      let solver_verified = receipt.is_verified()
      if !solver_verified {
        return false
      }
      match receipt.proof_artifact_ref {
        Some(proof_artifact) =>
          if has_ref(self.proof_ref) {
            proof_assert non_blank(proof_artifact)
            self.proof_ref == Some(proof_artifact)
          } else {
            true
          }
        None => true
      }
    }
  }
}

///|
fn componentization_status_text(status : ComponentizationStatus) -> String {
  match status {
    Planned => "planned"
    Scoped => "scoped"
    Extracted => "extracted"
    Verified => "verified"
    Integrated => "integrated"
  }
}

///|
fn has_non_blank_entries(values : Array[String]) -> Bool {
  if values.length() == 0 {
    return false
  }
  for value in values {
    if !non_blank(value) {
      return false
    }
  }
  true
}

///|
fn join_package_path(root : String, suffix : String) -> String {
  if !non_blank(suffix) {
    return root
  }
  root + "/" + suffix
}

///|
pub fn ModuleComponentPlan::new(
  module_name : String,
  source_contract_id : String,
  source_paths : Array[String],
  target_package : String,
  spec_file : String,
  test_files : Array[String],
  status? : ComponentizationStatus = Planned,
) -> ModuleComponentPlan {
  {
    module_name,
    source_contract_id,
    source_paths,
    target_package,
    spec_file,
    test_files,
    status,
  }
}

///|
pub fn ModuleComponentPlan::is_ready_for_extract(
  self : ModuleComponentPlan,
) -> Bool where {
  proof_ensure: result => !result || has_non_blank_entries(self.source_paths),
  proof_ensure: result => !result || has_non_blank_entries(self.test_files),
} {
  let metadata_ready = non_blank(self.module_name) &&
    non_blank(self.source_contract_id) &&
    non_blank(self.target_package) &&
    non_blank(self.spec_file) &&
    has_non_blank_entries(self.source_paths) &&
    has_non_blank_entries(self.test_files)
  if !metadata_ready {
    return false
  }
  match self.status {
    Scoped | Extracted | Verified | Integrated => true
    Planned => false
  }
}

///|
pub fn ModuleComponentPlan::to_contract_lines(
  self : ModuleComponentPlan,
) -> Array[String] {
  let lines = [
    "@pattern module.componentization",
    "@contract " + self.source_contract_id,
    "@module " + self.module_name,
    "@target_package " + self.target_package,
    "@spec_file " + self.spec_file,
    "@status " + componentization_status_text(self.status),
    "@ready " + (if self.is_ready_for_extract() { "true" } else { "false" }),
  ]
  for path in self.source_paths {
    lines.push("@source_path " + path)
  }
  for test_file in self.test_files {
    lines.push("@test_file " + test_file)
  }
  lines
}

///|
pub fn ComponentizationReport::new() -> ComponentizationReport {
  { plans: [] }
}

///|
pub fn ComponentizationReport::add_plan(
  self : ComponentizationReport,
  plan : ModuleComponentPlan,
) -> ComponentizationReport {
  let plans = self.plans
  plans.push(plan)
  { plans, }
}

///|
pub fn ComponentizationReport::ready_count(
  self : ComponentizationReport,
) -> Int {
  let mut count = 0
  for plan in self.plans {
    if plan.is_ready_for_extract() {
      count = count + 1
    }
  }
  count
}

///|
pub fn ComponentizationReport::is_boundary_safe(
  self : ComponentizationReport,
) -> Bool where {
  proof_ensure: result => !result || self.ready_count() == self.plans.length(),
} {
  self.plans.length() > 0 && self.ready_count() == self.plans.length()
}

///|
pub fn ModuleExtractionTemplate::chatgpt_default() -> ModuleExtractionTemplate {
  {
    target_package_root: "zpc/genius/loci/chatgpt",
    spec_file: "loci/chatgpt/chatgpt_spec.mbt",
    easy_test_file: "loci/chatgpt/chatgpt_easy_test.mbt",
    mid_test_file: "loci/chatgpt/chatgpt_mid_test.mbt",
    difficult_test_file: "loci/chatgpt/chatgpt_difficult_test.mbt",
    default_status: Scoped,
  }
}

///|
pub fn ModuleExtractionTemplate::required_test_files(
  self : ModuleExtractionTemplate,
) -> Array[String] {
  [self.easy_test_file, self.mid_test_file, self.difficult_test_file]
}

///|
pub fn ModuleExtractionTemplate::instantiate(
  self : ModuleExtractionTemplate,
  module_name : String,
  source_contract_id : String,
  source_paths : Array[String],
  target_package_suffix : String,
  status? : ComponentizationStatus? = None,
) -> ModuleComponentPlan {
  let target_package = join_package_path(
    self.target_package_root,
    target_package_suffix,
  )
  let final_status = match status {
    Some(value) => value
    None => self.default_status
  }
  ModuleComponentPlan::new(
    module_name,
    source_contract_id,
    source_paths,
    target_package,
    self.spec_file,
    self.required_test_files(),
    status=final_status,
  )
}
