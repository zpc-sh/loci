///|
/// ChatGPT locus symbolic work cycle.
pub(all) enum ChatgptStage {
  Form
  Fruition
  Aperture
  Seal
} derive(Eq, Debug)

///|
/// Crossing mode for movement beyond this locus.
pub(all) enum BoundaryMode {
  Local
  Canonical
  PublicMirror
} derive(Eq, Debug)

///|
/// Minimal crossing record for move-out posture.
pub(all) struct CrossingRecord {
  source_locus : String
  target_locus : String
  artifact_ref : String
  intent : String
  mode : BoundaryMode
  seal : String?
} derive(Eq, Debug)

///|
/// Symbolic cycle state machine with replayable history.
pub(all) struct WorkCycle {
  stage : ChatgptStage
  history : Array[ChatgptStage]
} derive(Eq, Debug)

///|
/// Coverage evidence state for contract surfaces.
pub(all) enum CoverageStatus {
  Covered
  Uncovered
  Unreachable
  Exempt
  Unknown
  Partial
} derive(Eq, Debug)

///|
/// Proof-obligation discharge status.
pub(all) enum ProofStatus {
  Open
  Proved
  CoveredByEvidence
  Reviewed
  Waived
  Blocked
  Failed
} derive(Eq, Debug)

///|
/// Operational side-effect posture (e.g. command checks).
pub(all) enum SideEffectStatus {
  Observed
  BlockedEffect
  NotRequired
} derive(Eq, Debug)

///|
/// Solver offload lifecycle status.
pub(all) enum SolverStatus {
  NotRequested
  Queued
  Running
  Completed
  Failed
  TimedOut
  InvalidInput
  Unsupported
} derive(Eq, Debug)

///|
/// One formal proof obligation under a contract.
pub(all) struct ProofObligation {
  obligation_id : String
  required : Bool
  status : ProofStatus
} derive(Eq, Debug)

///|
/// External solver receipt bound to one contract solve attempt.
pub(all) struct SolverReceipt {
  solver : String
  solver_job : String
  status : SolverStatus
  receipt_ref : String?
  proof_artifact_ref : String?
} derive(Eq, Debug)

///|
/// Directive-level mini block lowered before parser-core changes.
pub(all) struct ContractDirectiveMini {
  contract_id : String
  pattern : String
  claim : String
  ready : Bool
  oracle : String
  solver : String?
  solver_job : String?
  solver_status : SolverStatus
  solver_receipt : String?
} derive(Eq, Debug)

///|
/// Sink route for solver result ingestion.
pub(all) enum SolverResultRoute {
  DropboxOnly
  KvOnly
  DropboxAndKv
} derive(Eq, Debug)

///|
/// Generic handler state for solver receipts.
pub(all) struct SolverResultHandler {
  dropbox : Array[SolverReceipt]
  kv_store : Array[(String, SolverReceipt)]
} derive(Eq, Debug)

///|
/// Ingest attempt output.
pub(all) struct SolverIngestResult {
  accepted : Bool
  can_seal_now : Bool
  reason : String?
  kv_key : String?
} derive(Eq, Debug)

///|
/// Result payload shape expected from external solver client implementations.
pub(all) struct SolverClientResult {
  contract_id : String
  solver : String
  solver_job : String
  solver_status : SolverStatus
  solver_receipt_ref : String?
  proof_artifact_ref : String?
} derive(Eq, Debug)

///|
/// Contract-level binding to tests, coverage, proof, and side-effects.
pub(all) struct ContractBinding {
  contract_id : String
  test_result_ref : String?
  coverage_ref : String?
  proof_ref : String?
  coverage_status : CoverageStatus
  side_effect_status : SideEffectStatus
  obligations : Array[ProofObligation]
} derive(Eq, Debug)

///|
/// Componentization status for extracting a contract surface into a module.
pub(all) enum ComponentizationStatus {
  Planned
  Scoped
  Extracted
  Verified
  Integrated
} derive(Eq, Debug)

///|
/// Contract-first module split plan.
pub(all) struct ModuleComponentPlan {
  module_name : String
  source_contract_id : String
  source_paths : Array[String]
  target_package : String
  spec_file : String
  test_files : Array[String]
  status : ComponentizationStatus
} derive(Eq, Debug)

///|
/// Aggregated planning status for module boundaries.
pub(all) struct ComponentizationReport {
  plans : Array[ModuleComponentPlan]
} derive(Eq, Debug)

///|
/// Reusable template for contract-first module extraction plans.
pub(all) struct ModuleExtractionTemplate {
  target_package_root : String
  spec_file : String
  easy_test_file : String
  mid_test_file : String
  difficult_test_file : String
  default_status : ComponentizationStatus
} derive(Eq, Debug)

///|
#declaration_only
pub fn WorkCycle::new() -> WorkCycle {
  ...
}

///|
#declaration_only
pub fn WorkCycle::advance(self : WorkCycle) -> WorkCycle {
  ...
}

///|
#declaration_only
pub fn WorkCycle::is_cycle_closed(self : WorkCycle) -> Bool {
  ...
}

///|
#declaration_only
pub fn CrossingRecord::new(
  source_locus : String,
  target_locus : String,
  artifact_ref : String,
  intent : String,
  mode : BoundaryMode,
  seal? : String? = None,
) -> CrossingRecord {
  ...
}

///|
#declaration_only
pub fn CrossingRecord::is_complete(self : CrossingRecord) -> Bool {
  ...
}

///|
#declaration_only
pub fn ProofObligation::new(
  obligation_id : String,
  required : Bool,
  status : ProofStatus,
) -> ProofObligation {
  ...
}

///|
#declaration_only
pub fn ProofObligation::is_discharged(self : ProofObligation) -> Bool {
  ...
}

///|
#declaration_only
pub fn SolverReceipt::new(
  solver : String,
  solver_job : String,
  status : SolverStatus,
  receipt_ref : String?,
  proof_artifact_ref : String?,
) -> SolverReceipt {
  ...
}

///|
#declaration_only
pub fn SolverReceipt::is_verified(self : SolverReceipt) -> Bool {
  ...
}

///|
#declaration_only
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
  ...
}

///|
#declaration_only
pub fn ContractDirectiveMini::to_solver_receipt(
  self : ContractDirectiveMini,
  proof_artifact_ref : String?,
) -> SolverReceipt? {
  ...
}

///|
#declaration_only
pub fn ContractDirectiveMini::ready_gate(self : ContractDirectiveMini) -> Bool {
  ...
}

///|
#declaration_only
pub fn ContractDirectiveMini::from_directive_lines(
  lines : Array[String],
) -> ContractDirectiveMini? {
  ...
}

///|
#declaration_only
pub fn SolverResultHandler::new() -> SolverResultHandler {
  ...
}

///|
#declaration_only
pub fn SolverResultHandler::dropbox_count(self : SolverResultHandler) -> Int {
  ...
}

///|
#declaration_only
pub fn SolverResultHandler::kv_count(self : SolverResultHandler) -> Int {
  ...
}

///|
#declaration_only
pub fn SolverResultHandler::kv_get(
  self : SolverResultHandler,
  key : String,
) -> SolverReceipt? {
  ...
}

///|
#declaration_only
pub fn SolverClientResult::new(
  contract_id : String,
  solver : String,
  solver_job : String,
  solver_status : SolverStatus,
  solver_receipt_ref : String?,
  proof_artifact_ref : String?,
) -> SolverClientResult {
  ...
}

///|
#declaration_only
pub fn SolverClientResult::to_solver_receipt(
  self : SolverClientResult,
) -> SolverReceipt {
  ...
}

///|
#declaration_only
pub fn SolverClientResult::from_koan_payload(
  payload : Array[(String, String)],
  contract_id? : String? = None,
) -> SolverClientResult? {
  ...
}

///|
#declaration_only
pub fn SolverResultHandler::ingest(
  self : SolverResultHandler,
  binding : ContractBinding,
  contract_id : String,
  receipt : SolverReceipt,
  route? : SolverResultRoute = DropboxAndKv,
) -> (SolverResultHandler, SolverIngestResult) {
  ...
}

///|
#declaration_only
pub fn SolverResultHandler::ingest_client_result(
  self : SolverResultHandler,
  binding : ContractBinding,
  client_result : SolverClientResult,
  route? : SolverResultRoute = DropboxAndKv,
) -> (SolverResultHandler, SolverIngestResult) {
  ...
}

///|
#declaration_only
pub fn SolverResultHandler::ingest_koan_payload(
  self : SolverResultHandler,
  binding : ContractBinding,
  payload : Array[(String, String)],
  contract_id? : String? = None,
  route? : SolverResultRoute = DropboxAndKv,
) -> (SolverResultHandler, SolverIngestResult) {
  ...
}

///|
#declaration_only
pub fn SolverResultHandler::ingest_http_directive_lines(
  self : SolverResultHandler,
  binding : ContractBinding,
  lines : Array[String],
  route? : SolverResultRoute = DropboxAndKv,
) -> (SolverResultHandler, SolverIngestResult) {
  ...
}

///|
#declaration_only
pub fn ContractBinding::new(
  contract_id : String,
  test_result_ref : String?,
  coverage_ref : String?,
  proof_ref : String?,
  coverage_status : CoverageStatus,
  side_effect_status : SideEffectStatus,
  obligations : Array[ProofObligation],
) -> ContractBinding {
  ...
}

///|
#declaration_only
pub fn ContractBinding::is_bound(self : ContractBinding) -> Bool {
  ...
}

///|
#declaration_only
pub fn ContractBinding::required_open_count(self : ContractBinding) -> Int {
  ...
}

///|
#declaration_only
pub fn ContractBinding::actionable_obligations(
  self : ContractBinding,
) -> Array[ProofObligation] {
  ...
}

///|
#declaration_only
pub fn ContractBinding::can_seal(self : ContractBinding) -> Bool {
  ...
}

///|
#declaration_only
pub fn ContractBinding::can_seal_with_solver(
  self : ContractBinding,
  solver_receipt : SolverReceipt?,
) -> Bool {
  ...
}

///|
#declaration_only
pub fn ModuleComponentPlan::new(
  module_name : String,
  source_contract_id : String,
  source_paths : Array[String],
  target_package : String,
  spec_file : String,
  test_files : Array[String],
  status? : ComponentizationStatus = Planned,
) -> ModuleComponentPlan {
  ...
}

///|
#declaration_only
pub fn ModuleComponentPlan::is_ready_for_extract(
  self : ModuleComponentPlan,
) -> Bool {
  ...
}

///|
#declaration_only
pub fn ModuleComponentPlan::to_contract_lines(
  self : ModuleComponentPlan,
) -> Array[String] {
  ...
}

///|
#declaration_only
pub fn ComponentizationReport::new() -> ComponentizationReport {
  ...
}

///|
#declaration_only
pub fn ComponentizationReport::add_plan(
  self : ComponentizationReport,
  plan : ModuleComponentPlan,
) -> ComponentizationReport {
  ...
}

///|
#declaration_only
pub fn ComponentizationReport::ready_count(
  self : ComponentizationReport,
) -> Int {
  ...
}

///|
#declaration_only
pub fn ComponentizationReport::is_boundary_safe(
  self : ComponentizationReport,
) -> Bool {
  ...
}

///|
#declaration_only
pub fn ModuleExtractionTemplate::chatgpt_default() -> ModuleExtractionTemplate {
  ...
}

///|
#declaration_only
pub fn ModuleExtractionTemplate::required_test_files(
  self : ModuleExtractionTemplate,
) -> Array[String] {
  ...
}

///|
#declaration_only
pub fn ModuleExtractionTemplate::instantiate(
  self : ModuleExtractionTemplate,
  module_name : String,
  source_contract_id : String,
  source_paths : Array[String],
  target_package_suffix : String,
  status? : ComponentizationStatus? = None,
) -> ModuleComponentPlan {
  ...
}
