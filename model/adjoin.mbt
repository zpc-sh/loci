///|
/// Locus Adjoin Contract v0.1.
/// Contract: `merkin.locus.adjoin.contract` / `v0.1`.
///
/// The adjoin contract defines composable machine contracts for
/// locus-to-locus composition. Every composition is a recursive
/// expression tree over five operations (`union`, `consume`, `atop`,
/// `subtract`, `yata_union`) with leaves that are either concrete
/// loci or typed-void Yata loci.
///
/// Closure: every operation produces a value that can be a child of
/// any other operation. Determinism: normalized trees with identical
/// leaves produce identical top-level seals. Replay safety: the
/// contract carries references, never imperative execution.
pub(all) enum AdjoinOp {
  Union
  Consume
  Atop
  Subtract
  YataUnion
} derive(Eq, Debug)

///|
pub impl Show for AdjoinOp with output(self, logger) {
  logger.write_string(adjoin_op_tag(self))
}

///|
/// Typed expectation attached to a typed-void Yata locus.
pub(all) enum YataExpectedType {
  Observation
  Compilation
  Delegation
  Resolution
  YataAudit
  YataSynthesis
} derive(Eq, Debug)

///|
pub impl Show for YataExpectedType with output(self, logger) {
  logger.write_string(yata_expected_type_tag(self))
}

///|
/// Concrete locus reference — a leaf in the adjoin expression tree.
pub(all) struct LocusRef {
  locus_id : String
  surface_ref : String
  profile_ref : String
  seal : @hash.Hash
} derive(Debug)

///|
/// Typed-void Yata locus reference. A Yata locus is intentionally
/// unfilled but strongly typed by Yata contract. `min_confidence` is
/// carried as a 0-100 integer percentage.
pub(all) struct YataLocusRef {
  yata_plan_ref : String
  expected_type : YataExpectedType
  void_typed : Bool
  min_confidence : UInt
  seal : @hash.Hash
} derive(Debug)

///|
/// A recursive adjoin expression. Op nodes compose two subtrees
/// under an operation with optional `meta` annotation. Leaves are
/// one of `LocusLeaf` (concrete locus) or `VoidLeaf` (typed void
/// Yata locus).
pub(all) enum AdjoinExpr {
  Op(AdjoinOp, AdjoinExpr, AdjoinExpr, Array[(String, String)])
  LocusLeaf(LocusRef)
  VoidLeaf(YataLocusRef)
} derive(Debug)

///|
/// Top-level adjoin contract envelope.
pub(all) struct AdjoinContract {
  kind : String
  version : String
  contract_id : String
  ratio_loci : String
  expr : AdjoinExpr
  required_surfaces : Array[String]
  boundary_mode : BoundaryMode
  seal : @hash.Hash
} derive(Debug)

///|
/// Validation errors per `LOCUS_ADJOIN_CONTRACT_v0.1`.
pub(all) enum AdjoinError {
  AdjoinBadKind
  AdjoinBadVersion
  AdjoinUnknownOp
  AdjoinMissingRatioLoci
  AdjoinBadLeafShape(String)
  AdjoinMissingSeal(String)
  AdjoinCycleDetected
  AdjoinInvalidYataUnionRight
  AdjoinInvalidVoidTyped
  AdjoinUnsafeBoundaryMode
  AdjoinMissingContractId
  AdjoinEmptyRequiredSurfaces
} derive(Eq, Debug)

///|
pub impl Show for AdjoinError with output(self, logger) {
  logger.write_object(self)
}

///|
/// Canonical kind tag.
pub fn adjoin_kind() -> String {
  "merkin.locus.adjoin.contract"
}

///|
/// Canonical version tag.
pub fn adjoin_version() -> String {
  "v0.1"
}

///|
/// Wire tag for an adjoin op.
pub fn adjoin_op_tag(op : AdjoinOp) -> String {
  match op {
    Union => "union"
    Consume => "consume"
    Atop => "atop"
    Subtract => "subtract"
    YataUnion => "yata_union"
  }
}

///|
/// Parse an adjoin op from its wire tag.
pub fn adjoin_op_parse(tag : String) -> AdjoinOp? {
  match tag {
    "union" => Some(Union)
    "consume" => Some(Consume)
    "atop" => Some(Atop)
    "subtract" => Some(Subtract)
    "yata_union" => Some(YataUnion)
    _ => None
  }
}

///|
/// Wire tag for a typed expectation.
pub fn yata_expected_type_tag(t : YataExpectedType) -> String {
  match t {
    Observation => "Observation"
    Compilation => "Compilation"
    Delegation => "Delegation"
    Resolution => "Resolution"
    YataAudit => "Audit"
    YataSynthesis => "Synthesis"
  }
}

///|
/// Parse a typed expectation from its wire tag.
pub fn yata_expected_type_parse(tag : String) -> YataExpectedType? {
  match tag {
    "Observation" => Some(Observation)
    "Compilation" => Some(Compilation)
    "Delegation" => Some(Delegation)
    "Resolution" => Some(Resolution)
    "Audit" => Some(YataAudit)
    "Synthesis" => Some(YataSynthesis)
    _ => None
  }
}

///|
/// Deterministic seal of an adjoin expression tree. Walks children
/// in canonical order and folds their seals into the parent's
/// material.
pub fn AdjoinExpr::seal(self : AdjoinExpr) -> @hash.Hash {
  let b = StringBuilder::new(size_hint=512)
  adjoin_expr_write(b, self)
  @hash.Hash::of_bytes(adjoin_string_to_bytes(b.to_string()))
}

///|
fn adjoin_expr_write(b : StringBuilder, e : AdjoinExpr) -> Unit {
  match e {
    LocusLeaf(leaf) => {
      b.write_string("locus(")
      b.write_string(leaf.locus_id)
      b.write_string(",")
      b.write_string(leaf.surface_ref)
      b.write_string(",")
      b.write_string(leaf.profile_ref)
      b.write_string(",")
      b.write_string(leaf.seal.key())
      b.write_string(")")
    }
    VoidLeaf(leaf) => {
      b.write_string("yata(")
      b.write_string(leaf.yata_plan_ref)
      b.write_string(",")
      b.write_string(yata_expected_type_tag(leaf.expected_type))
      b.write_string(",")
      b.write_string(if leaf.void_typed { "1" } else { "0" })
      b.write_string(",")
      b.write_string(leaf.min_confidence.to_string())
      b.write_string(",")
      b.write_string(leaf.seal.key())
      b.write_string(")")
    }
    Op(op, left, right, meta) => {
      b.write_string(adjoin_op_tag(op))
      b.write_string("(")
      adjoin_expr_write(b, left)
      b.write_string("|")
      adjoin_expr_write(b, right)
      b.write_string("|meta=")
      adjoin_meta_write(b, meta)
      b.write_string(")")
    }
  }
}

///|
fn adjoin_meta_write(b : StringBuilder, meta : Array[(String, String)]) -> Unit {
  // Sort meta by key for canonical ordering. Array is small so a
  // simple insertion sort is fine.
  let sorted = adjoin_meta_sorted(meta)
  if sorted.length() == 0 {
    b.write_string("{}")
    return
  }
  b.write_string("{")
  b.write_string(sorted[0].0)
  b.write_string("=")
  b.write_string(sorted[0].1)
  for i = 1; i < sorted.length(); i = i + 1 {
    b.write_string(",")
    b.write_string(sorted[i].0)
    b.write_string("=")
    b.write_string(sorted[i].1)
  }
  b.write_string("}")
}

///|
fn adjoin_meta_sorted(
  meta : Array[(String, String)],
) -> Array[(String, String)] {
  let sorted : Array[(String, String)] = []
  for pair in meta {
    sorted.push(pair)
  }
  for i = 1; i < sorted.length(); i = i + 1 {
    let key = sorted[i]
    let mut j = i - 1
    while j >= 0 && sorted[j].0 > key.0 {
      sorted[j + 1] = sorted[j]
      j = j - 1
    }
    sorted[j + 1] = key
  }
  sorted
}

///|
/// Seal an adjoin contract. Top-level seal is deterministic over
/// (kind, version, contract_id, ratio_loci, expr_seal,
/// required_surfaces, boundary_mode).
pub fn AdjoinContract::compute_seal(
  kind : String,
  version : String,
  contract_id : String,
  ratio_loci : String,
  expr : AdjoinExpr,
  required_surfaces : Array[String],
  boundary_mode : BoundaryMode,
) -> @hash.Hash {
  let b = StringBuilder::new(size_hint=512)
  b.write_string(kind)
  b.write_string("|")
  b.write_string(version)
  b.write_string("|")
  b.write_string(contract_id)
  b.write_string("|")
  b.write_string(ratio_loci)
  b.write_string("|expr=")
  b.write_string(expr.seal().key())
  b.write_string("|surfaces=")
  let sorted = adjoin_surfaces_sorted(required_surfaces)
  for i = 0; i < sorted.length(); i = i + 1 {
    if i > 0 {
      b.write_string(",")
    }
    b.write_string(sorted[i])
  }
  b.write_string("|boundary=")
  b.write_string(boundary_mode_tag(boundary_mode))
  @hash.Hash::of_bytes(adjoin_string_to_bytes(b.to_string()))
}

///|
fn adjoin_surfaces_sorted(surfaces : Array[String]) -> Array[String] {
  let sorted : Array[String] = []
  for s in surfaces {
    sorted.push(s)
  }
  for i = 1; i < sorted.length(); i = i + 1 {
    let key = sorted[i]
    let mut j = i - 1
    while j >= 0 && sorted[j] > key {
      sorted[j + 1] = sorted[j]
      j = j - 1
    }
    sorted[j + 1] = key
  }
  sorted
}

///|
/// Construct an adjoin contract, computing the canonical seal over
/// its normalized form.
pub fn AdjoinContract::new(
  contract_id : String,
  ratio_loci : String,
  expr : AdjoinExpr,
  required_surfaces : Array[String],
  boundary_mode : BoundaryMode,
) -> AdjoinContract {
  let seal = AdjoinContract::compute_seal(
    adjoin_kind(),
    adjoin_version(),
    contract_id,
    ratio_loci,
    expr,
    required_surfaces,
    boundary_mode,
  )
  {
    kind: adjoin_kind(),
    version: adjoin_version(),
    contract_id,
    ratio_loci,
    expr,
    required_surfaces,
    boundary_mode,
    seal,
  }
}

///|
/// Validate a contract's shape and cross-field invariants.
/// Does not resolve external references — that is the router's job.
pub fn AdjoinContract::validate(
  self : AdjoinContract,
) -> Result[Unit, AdjoinError] {
  if self.kind != adjoin_kind() {
    return Err(AdjoinBadKind)
  }
  if self.version != adjoin_version() {
    return Err(AdjoinBadVersion)
  }
  if self.contract_id == "" {
    return Err(AdjoinMissingContractId)
  }
  if self.ratio_loci == "" {
    return Err(AdjoinMissingRatioLoci)
  }
  if self.required_surfaces.length() == 0 {
    return Err(AdjoinEmptyRequiredSurfaces)
  }
  // Boundary mode is strong-typed via enum; the unsafe case is an
  // implementation-defined policy. For v0.1 every declared mode is
  // admissible; we keep `AdjoinUnsafeBoundaryMode` in the enum so
  // policy layers can reject stricter-than-quarantine or custom
  // modes later without breaking the contract shape.
  validate_adjoin_expr(self.expr)
}

///|
/// Recursively validate an adjoin expression subtree.
pub fn validate_adjoin_expr(expr : AdjoinExpr) -> Result[Unit, AdjoinError] {
  match expr {
    LocusLeaf(leaf) => {
      if leaf.locus_id == "" {
        return Err(AdjoinBadLeafShape("locus_id"))
      }
      if hash_is_empty(leaf.seal) {
        return Err(AdjoinMissingSeal("locus." + leaf.locus_id))
      }
      Ok(())
    }
    VoidLeaf(leaf) => {
      if leaf.yata_plan_ref == "" {
        return Err(AdjoinBadLeafShape("yata_plan_ref"))
      }
      if !leaf.void_typed {
        return Err(AdjoinInvalidVoidTyped)
      }
      if leaf.min_confidence > 100U {
        return Err(AdjoinBadLeafShape("min_confidence"))
      }
      if hash_is_empty(leaf.seal) {
        return Err(AdjoinMissingSeal("yata_locus." + leaf.yata_plan_ref))
      }
      Ok(())
    }
    Op(op, left, right, _) => {
      match op {
        YataUnion =>
          match right {
            VoidLeaf(void_leaf) =>
              if !void_leaf.void_typed {
                return Err(AdjoinInvalidVoidTyped)
              }
            _ => return Err(AdjoinInvalidYataUnionRight)
          }
        _ => ()
      }
      match validate_adjoin_expr(left) {
        Err(e) => return Err(e)
        Ok(_) => ()
      }
      match validate_adjoin_expr(right) {
        Err(e) => return Err(e)
        Ok(_) => ()
      }
      Ok(())
    }
  }
}

///|
/// Re-seal a contract after any transformation. Used in round-trip
/// tests to verify normalization is idempotent.
pub fn AdjoinContract::reseal(self : AdjoinContract) -> AdjoinContract {
  {
    ..self,
    seal: AdjoinContract::compute_seal(
      self.kind,
      self.version,
      self.contract_id,
      self.ratio_loci,
      self.expr,
      self.required_surfaces,
      self.boundary_mode,
    ),
  }
}

///|
fn adjoin_string_to_bytes(s : String) -> Bytes {
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
