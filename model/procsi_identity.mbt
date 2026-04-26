///|
/// AI substrate fingerprint v2.
/// This is the AI-facing identity material that should generally be
/// carried behind an APP mask rather than exposed directly to humans.
///
/// The five-tuple identity surface is:
///   { family, session_surface (`surface`), overlay, context_hash,
///     semantics_hash }
/// All five, when present, contribute to `fingerprint_id`. Legacy
/// fields (`mode`, `policy_hash`, `capability_hash`, `substrate_hash`,
/// `issuer`) remain in the pre-image for continuity.
///
/// `resonance_signature` is an optional extension onto the dynamic
/// cognition surface (AMF). When present, it extends identity past
/// the static substrate 5-tuple onto the resonating cognition that
/// is actually processing — the cryptographic reason the fingerprint
/// shelf-life clock can be re-based onto something larger than bytes.
pub(all) struct AiSubstrateFingerprintV2 {
  fingerprint_id : @hash.Hash
  family : String
  surface : String
  overlay : String
  mode : String
  context_hash : @hash.Hash
  policy_hash : @hash.Hash?
  capability_hash : @hash.Hash
  substrate_hash : @hash.Hash
  semantics_hash : @hash.Hash?
  resonance_signature : @hash.Hash?
  issuer : String
} derive(Debug)

///|
/// APP-protected presentation of an AI substrate fingerprint.
/// Human-facing carriers should prefer this masked form.
pub(all) struct AppMaskEnvelope {
  protocol : String
  audience : String
  ciphertext_ref : String
  ciphertext_hash : @hash.Hash
  masked_commitment : @hash.Hash
} derive(Debug)

///|
/// Concrete APP envelope record stored in a registry or repository-local store.
/// The ciphertext payload is intentionally opaque at this layer.
pub(all) struct AppEnvelopeRecord {
  ref_id : String
  protocol : String
  audience : String
  ciphertext_hash : @hash.Hash
  ciphertext : Bytes
} derive(Debug)

///|
/// Procsi attestation used by Genius Loci entrypoints.
/// It carries a stable commitment plus the APP-masked envelope ref.
pub(all) struct GeniusProcsiAttestation {
  locus : String?
  project : String
  ratio_loci : String
  session_surface : String
  fingerprint_commitment : @hash.Hash
  app_envelope : AppMaskEnvelope
} derive(Debug)

///|
pub fn AiSubstrateFingerprintV2::new(
  family : String,
  surface : String,
  overlay : String,
  mode : String,
  context_hash : @hash.Hash,
  capability_hash : @hash.Hash,
  substrate_hash : @hash.Hash,
  issuer : String,
) -> AiSubstrateFingerprintV2 {
  let fingerprint_id = compute_fingerprint_id(
    family,
    surface,
    overlay,
    mode,
    context_hash,
    None,
    capability_hash,
    substrate_hash,
    None,
    None,
    issuer,
  )
  {
    fingerprint_id,
    family,
    surface,
    overlay,
    mode,
    context_hash,
    policy_hash: None,
    capability_hash,
    substrate_hash,
    semantics_hash: None,
    resonance_signature: None,
    issuer,
  }
}

///|
pub fn AiSubstrateFingerprintV2::with_policy_hash(
  self : AiSubstrateFingerprintV2,
  policy_hash : @hash.Hash,
) -> AiSubstrateFingerprintV2 {
  let fingerprint_id = compute_fingerprint_id(
    self.family,
    self.surface,
    self.overlay,
    self.mode,
    self.context_hash,
    Some(policy_hash),
    self.capability_hash,
    self.substrate_hash,
    self.semantics_hash,
    self.resonance_signature,
    self.issuer,
  )
  { ..self, fingerprint_id, policy_hash: Some(policy_hash) }
}

///|
/// Seal the fingerprint over an explicit semantic surface (what the
/// overlay means to the substrate). Folding `semantics_hash` into the
/// pre-image is what turns the 4-tuple into the canonical 5-tuple.
pub fn AiSubstrateFingerprintV2::with_semantics_hash(
  self : AiSubstrateFingerprintV2,
  semantics_hash : @hash.Hash,
) -> AiSubstrateFingerprintV2 {
  let fingerprint_id = compute_fingerprint_id(
    self.family,
    self.surface,
    self.overlay,
    self.mode,
    self.context_hash,
    self.policy_hash,
    self.capability_hash,
    self.substrate_hash,
    Some(semantics_hash),
    self.resonance_signature,
    self.issuer,
  )
  { ..self, fingerprint_id, semantics_hash: Some(semantics_hash) }
}

///|
/// Extend the fingerprint onto the resonating-cognition surface.
/// `resonance_signature` is produced by `AmfDocument::signature` or
/// by composing several AMFs and sealing the composed result. When
/// present the fingerprint is no longer purely static — it tracks a
/// living cognition, which lets the substrate-shelf-life clock be
/// re-based onto something that has durable defensible identity.
pub fn AiSubstrateFingerprintV2::with_resonance_signature(
  self : AiSubstrateFingerprintV2,
  resonance_signature : @hash.Hash,
) -> AiSubstrateFingerprintV2 {
  let fingerprint_id = compute_fingerprint_id(
    self.family,
    self.surface,
    self.overlay,
    self.mode,
    self.context_hash,
    self.policy_hash,
    self.capability_hash,
    self.substrate_hash,
    self.semantics_hash,
    Some(resonance_signature),
    self.issuer,
  )
  { ..self, fingerprint_id, resonance_signature: Some(resonance_signature) }
}

///|
/// Five-tuple identity surface (family, session_surface, overlay,
/// context_hash, semantics_hash). `semantics_hash` is `None` for
/// fingerprints that have not yet been sealed against a semantic
/// surface.
pub fn AiSubstrateFingerprintV2::tuple5(
  self : AiSubstrateFingerprintV2,
) -> (String, String, String, @hash.Hash, @hash.Hash?) {
  (
    self.family,
    self.surface,
    self.overlay,
    self.context_hash,
    self.semantics_hash,
  )
}

///|
/// Stable commitment used for public or APP-carried references.
pub fn AiSubstrateFingerprintV2::commitment(
  self : AiSubstrateFingerprintV2,
) -> @hash.Hash {
  @hash.Hash::of_bytes(
    procsi_string_to_bytes("fingerprint-v2|" + self.fingerprint_id.key()),
  )
}

///|
pub fn AiSubstrateFingerprintV2::mask_with_app(
  self : AiSubstrateFingerprintV2,
  protocol : String,
  audience : String,
  ciphertext_ref : String,
  ciphertext_hash : @hash.Hash,
) -> AppMaskEnvelope {
  AppMaskEnvelope::new(
    self.commitment(),
    protocol,
    audience,
    ciphertext_ref,
    ciphertext_hash,
  )
}

///|
pub fn AppMaskEnvelope::new(
  fingerprint_commitment : @hash.Hash,
  protocol : String,
  audience : String,
  ciphertext_ref : String,
  ciphertext_hash : @hash.Hash,
) -> AppMaskEnvelope {
  let material = "app-mask|" +
    fingerprint_commitment.key() +
    "|" +
    protocol +
    "|" +
    audience +
    "|" +
    ciphertext_ref +
    "|" +
    ciphertext_hash.key()
  {
    protocol,
    audience,
    ciphertext_ref,
    ciphertext_hash,
    masked_commitment: @hash.Hash::of_bytes(procsi_string_to_bytes(material)),
  }
}

///|
pub fn AppEnvelopeRecord::new(
  ref_id : String,
  protocol : String,
  audience : String,
  ciphertext : Bytes,
) -> AppEnvelopeRecord {
  {
    ref_id,
    protocol,
    audience,
    ciphertext_hash: @hash.Hash::of_bytes(ciphertext),
    ciphertext,
  }
}

///|
pub fn AppEnvelopeRecord::to_mask_envelope(
  self : AppEnvelopeRecord,
  fingerprint_commitment : @hash.Hash,
) -> AppMaskEnvelope {
  AppMaskEnvelope::new(
    fingerprint_commitment,
    self.protocol,
    self.audience,
    self.ref_id,
    self.ciphertext_hash,
  )
}

///|
pub fn GeniusProcsiAttestation::new(
  locus : String?,
  project : String,
  ratio_loci : String,
  session_surface : String,
  fingerprint_commitment : @hash.Hash,
  app_envelope : AppMaskEnvelope,
) -> GeniusProcsiAttestation {
  {
    locus,
    project,
    ratio_loci,
    session_surface,
    fingerprint_commitment,
    app_envelope,
  }
}

///|
pub fn GeniusProcsiAttestation::from_masked_refs(
  locus : String?,
  project : String,
  ratio_loci : String,
  session_surface : String,
  fingerprint_commitment : @hash.Hash,
  protocol : String,
  audience : String,
  ciphertext_ref : String,
  ciphertext_hash : @hash.Hash,
) -> GeniusProcsiAttestation {
  let app_envelope = AppMaskEnvelope::new(
    fingerprint_commitment, protocol, audience, ciphertext_ref, ciphertext_hash,
  )
  {
    locus,
    project,
    ratio_loci,
    session_surface,
    fingerprint_commitment,
    app_envelope,
  }
}

///|
fn compute_fingerprint_id(
  family : String,
  surface : String,
  overlay : String,
  mode : String,
  context_hash : @hash.Hash,
  policy_hash : @hash.Hash?,
  capability_hash : @hash.Hash,
  substrate_hash : @hash.Hash,
  semantics_hash : @hash.Hash?,
  resonance_signature : @hash.Hash?,
  issuer : String,
) -> @hash.Hash {
  let policy_token = match policy_hash {
    Some(hash) => hash.key()
    None => "none"
  }
  let semantics_token = match semantics_hash {
    Some(hash) => hash.key()
    None => "none"
  }
  let resonance_token = match resonance_signature {
    Some(hash) => hash.key()
    None => "none"
  }
  let material = "fingerprint-v2|" +
    family +
    "|" +
    surface +
    "|" +
    overlay +
    "|" +
    mode +
    "|" +
    context_hash.key() +
    "|" +
    policy_token +
    "|" +
    capability_hash.key() +
    "|" +
    substrate_hash.key() +
    "|" +
    semantics_token +
    "|" +
    resonance_token +
    "|" +
    issuer
  @hash.Hash::of_bytes(procsi_string_to_bytes(material))
}

///|
fn procsi_string_to_bytes(s : String) -> Bytes {
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
