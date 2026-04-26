///|
/// Mu/SLL Build Contract v0.1.
/// Contract: `mu.sll.build.contract.v0`.
///
/// Loci owns the envelope shape and sealing rules; Mu owns compile
/// semantics. A BuildRequest carries a Semanticfile source + target;
/// a BuildManifest carries the compiled adjoin_seal + optional WASM
/// ref + provenance seal. Both envelopes travel through the Loci
/// boundary FSM like any other substrate artifact.
///
/// See `docs/MU_SLL_BUILD_CONTRACT_v0.1.md` and
/// `docs/SLL_REFERENCE_v0.1.md`.
pub(all) struct BuildRequest {
  kind : String
  version : String
  request_id : String
  semanticfile : String
  target : BuildTarget
  boundary_mode : BoundaryMode
  composition_mode : SllCompositionMode
  ratio_loci : String
  request_seal : @hash.Hash
} derive(Debug)

///|
/// Substrate target that the Semanticfile should compile against.
pub(all) struct BuildTarget {
  family : String
  model : String
  mobility : Double
  movement : SllMovementStyle
} derive(Debug)

///|
/// Movement style for the target substrate (Tena heritage; kept for
/// compatibility with the Semanticfile surface).
pub(all) enum SllMovementStyle {
  MovementDiscrete
  MovementFluid
  MovementStructured
} derive(Eq, Debug)

///|
/// Composition mode mirrors the Resonance layer's `ResonanceOp` so
/// compile-time composition shares vocabulary with runtime grain.
pub(all) enum SllCompositionMode {
  SllLayered
  SllSequenced
  SllLive
} derive(Eq, Debug)

///|
/// BuildManifest: the envelope Mu returns to Loci.
pub(all) struct BuildManifest {
  kind : String
  version : String
  request_id : String
  adjoin_seal : @hash.Hash
  wasm_ref : String?
  provenance_seal : @hash.Hash
  diagnostics : Array[BuildDiagnostic]
  status : BuildStatus
} derive(Debug)

///|
/// One diagnostic message from the compile.
pub(all) struct BuildDiagnostic {
  level : DiagnosticLevel
  span : String
  message : String
} derive(Debug)

///|
pub(all) enum DiagnosticLevel {
  DiagInfo
  DiagWarning
  DiagError
} derive(Eq, Debug)

///|
pub(all) enum BuildStatus {
  BuildOk
  BuildWarning
  BuildError
} derive(Eq, Debug)

///|
/// Validation errors for the build contract.
pub(all) enum SllError {
  SllBadKind
  SllBadVersion
  SllMissingField(String)
  SllEmptySource
  SllMobilityOutOfRange
  SllMissingSeal(String)
} derive(Eq, Debug)

///|
pub fn sll_kind() -> String {
  "mu.sll.build.contract"
}

///|
pub fn sll_version() -> String {
  "v0"
}

///|
pub fn sll_movement_tag(m : SllMovementStyle) -> String {
  match m {
    MovementDiscrete => "discrete"
    MovementFluid => "fluid"
    MovementStructured => "structured"
  }
}

///|
pub fn sll_movement_parse(tag : String) -> SllMovementStyle? {
  match tag {
    "discrete" => Some(MovementDiscrete)
    "fluid" => Some(MovementFluid)
    "structured" => Some(MovementStructured)
    _ => None
  }
}

///|
pub fn sll_composition_tag(m : SllCompositionMode) -> String {
  match m {
    SllLayered => "layered"
    SllSequenced => "sequenced"
    SllLive => "live"
  }
}

///|
pub fn sll_composition_parse(tag : String) -> SllCompositionMode? {
  match tag {
    "layered" => Some(SllLayered)
    "sequenced" => Some(SllSequenced)
    "live" => Some(SllLive)
    _ => None
  }
}

///|
/// Construct a build request with envelope kind/version pre-filled.
pub fn BuildRequest::new(
  request_id : String,
  semanticfile : String,
  target : BuildTarget,
  boundary_mode : BoundaryMode,
  composition_mode : SllCompositionMode,
  ratio_loci : String,
  request_seal : @hash.Hash,
) -> BuildRequest {
  {
    kind: sll_kind(),
    version: sll_version(),
    request_id,
    semanticfile,
    target,
    boundary_mode,
    composition_mode,
    ratio_loci,
    request_seal,
  }
}

///|
/// Deterministic seal material for a build request. Callers hash
/// this to produce `request_seal`.
pub fn BuildRequest::seal_material(self : BuildRequest) -> @hash.Hash {
  let b = StringBuilder::new(size_hint=1024)
  b.write_string(self.kind)
  b.write_string("|")
  b.write_string(self.version)
  b.write_string("|")
  b.write_string(self.request_id)
  b.write_string("|target=")
  b.write_string(self.target.family)
  b.write_string("/")
  b.write_string(self.target.model)
  b.write_string(";mobility=")
  b.write_string(self.target.mobility.to_string())
  b.write_string(";movement=")
  b.write_string(sll_movement_tag(self.target.movement))
  b.write_string("|boundary=")
  b.write_string(boundary_mode_tag(self.boundary_mode))
  b.write_string("|composition=")
  b.write_string(sll_composition_tag(self.composition_mode))
  b.write_string("|ratio=")
  b.write_string(self.ratio_loci)
  b.write_string("|source=")
  b.write_string(self.semanticfile)
  @hash.Hash::of_bytes(sll_string_to_bytes(b.to_string()))
}

///|
pub fn BuildRequest::validate(self : BuildRequest) -> Result[Unit, SllError] {
  if self.kind != sll_kind() {
    return Err(SllBadKind)
  }
  if self.version != sll_version() {
    return Err(SllBadVersion)
  }
  if self.request_id == "" {
    return Err(SllMissingField("request_id"))
  }
  if self.ratio_loci == "" {
    return Err(SllMissingField("ratio_loci"))
  }
  if self.semanticfile == "" {
    return Err(SllEmptySource)
  }
  if self.target.family == "" {
    return Err(SllMissingField("target.family"))
  }
  if self.target.model == "" {
    return Err(SllMissingField("target.model"))
  }
  if self.target.mobility < 0.0 || self.target.mobility > 1.0 {
    return Err(SllMobilityOutOfRange)
  }
  if hash_is_empty(self.request_seal) {
    return Err(SllMissingSeal("request_seal"))
  }
  Ok(())
}

///|
pub fn BuildManifest::new(
  request_id : String,
  adjoin_seal : @hash.Hash,
  wasm_ref : String?,
  provenance_seal : @hash.Hash,
  diagnostics : Array[BuildDiagnostic],
  status : BuildStatus,
) -> BuildManifest {
  {
    kind: sll_kind(),
    version: sll_version(),
    request_id,
    adjoin_seal,
    wasm_ref,
    provenance_seal,
    diagnostics,
    status,
  }
}

///|
/// Deterministic provenance seal material: binds request seal to
/// the adjoin seal that represents the compiled op graph plus the
/// optional WASM ref. Replaying (request, adjoin, wasm) must
/// reproduce this exact hash.
pub fn BuildManifest::compute_provenance(
  request_seal : @hash.Hash,
  adjoin_seal : @hash.Hash,
  wasm_ref : String?,
) -> @hash.Hash {
  let b = StringBuilder::new(size_hint=256)
  b.write_string("provenance|")
  b.write_string(request_seal.key())
  b.write_string("|")
  b.write_string(adjoin_seal.key())
  b.write_string("|wasm=")
  match wasm_ref {
    Some(r) => b.write_string(r)
    None => b.write_string("none")
  }
  @hash.Hash::of_bytes(sll_string_to_bytes(b.to_string()))
}

///|
pub fn BuildManifest::validate(self : BuildManifest) -> Result[Unit, SllError] {
  if self.kind != sll_kind() {
    return Err(SllBadKind)
  }
  if self.version != sll_version() {
    return Err(SllBadVersion)
  }
  if self.request_id == "" {
    return Err(SllMissingField("request_id"))
  }
  if hash_is_empty(self.adjoin_seal) {
    return Err(SllMissingSeal("adjoin_seal"))
  }
  if hash_is_empty(self.provenance_seal) {
    return Err(SllMissingSeal("provenance_seal"))
  }
  Ok(())
}

///|
fn sll_string_to_bytes(s : String) -> Bytes {
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
