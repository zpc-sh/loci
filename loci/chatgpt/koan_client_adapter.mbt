///|
fn koan_payload_value(
  payload : Array[(String, String)],
  key : String,
) -> String? {
  for entry in payload {
    if entry.0 == key {
      return Some(entry.1)
    }
  }
  None
}

///|
pub fn SolverClientResult::from_koan_payload(
  payload : Array[(String, String)],
  contract_id? : String? = None,
) -> SolverClientResult? {
  let contract_id = match contract_id {
    Some(v) => v
    None =>
      match koan_payload_value(payload, "contract_id") {
        Some(v) => v
        None => return None
      }
  }
  let solver = match koan_payload_value(payload, "solver") {
    Some(v) => v
    None => return None
  }
  let solver_job = match koan_payload_value(payload, "solver_job") {
    Some(v) => v
    None => return None
  }
  let solver_status = match koan_payload_value(payload, "solver_status") {
    Some(v) => parse_solver_status(v)
    None => return None
  }
  if solver_status == NotRequested {
    return None
  }
  let solver_receipt_ref = koan_payload_value(payload, "solver_receipt_ref")
  let proof_artifact_ref = koan_payload_value(payload, "proof_artifact_ref")
  Some(
    SolverClientResult::new(
      contract_id, solver, solver_job, solver_status, solver_receipt_ref, proof_artifact_ref,
    ),
  )
}

///|
pub fn SolverResultHandler::ingest_koan_payload(
  self : SolverResultHandler,
  binding : ContractBinding,
  payload : Array[(String, String)],
  contract_id? : String? = None,
  route? : SolverResultRoute = DropboxAndKv,
) -> (SolverResultHandler, SolverIngestResult) {
  match SolverClientResult::from_koan_payload(payload, contract_id~) {
    Some(client_result) =>
      self.ingest_client_result(binding, client_result, route~)
    None =>
      (
        self,
        {
          accepted: false,
          can_seal_now: false,
          reason: Some("invalid_koan_client_payload"),
          kv_key: None,
        },
      )
  }
}
