///|
/// Loci News Edition v0.
/// Contract: `loci.news.edition.v0`.
///
/// An edition is a unit of advisory orientation delivered from a
/// local reporter (CNI, CGN, or a custom publisher) into a receiving
/// locus. Editions are **context, never command**: boot hooks
/// expose normalized slices to conversation scaffolding; no tool
/// dispatch, no eval, no file writes based on payload content.
///
/// See `docs/packets/LOCI_NEWS_CODECAVE_SPEC_v0.1.md` and
/// `docs/packets/NEWS_CODECAVE_BOOT_HOOK_v0.1.md`.
pub(all) struct NewsEdition {
  kind : String
  version : String
  edition_id : String
  published_at : String
  publisher_id : String
  network : NewsNetwork
  content_hash : @hash.Hash
  signature : @hash.Hash?
  sections : Array[NewsSection]
  continuity : NewsContinuity
  confidence : NewsConfidence
} derive(Show)

///|
/// The reporter network a given edition came from.
pub(all) enum NewsNetwork {
  NetworkCni
  NetworkCgn
  NetworkCustom(String)
} derive(Eq, Show)

///|
/// A typed section inside an edition. `slug` is a short identifier
/// (`summary`, `trust_desk`, `crystal`, `cantor`, etc.). `body` is
/// plain text treated as context only.
pub(all) struct NewsSection {
  slug : String
  body : String
} derive(Show)

///|
/// Continuity counters describe how much of the edition is new vs.
/// ongoing vs. resolved material.
pub(all) struct NewsContinuity {
  new_count : UInt
  continuing_count : UInt
  resolved_count : UInt
  quiet_count : UInt
} derive(Show)

///|
/// Confidence shape describes how much of the edition is directly
/// observed vs. inferred vs. unconfirmed.
pub(all) struct NewsConfidence {
  observed_count : UInt
  inferred_count : UInt
  unconfirmed_count : UInt
} derive(Show)

///|
/// News edition validation errors.
pub(all) enum NewsError {
  NewsBadKind
  NewsBadVersion
  NewsMissingField(String)
  NewsMissingSignatureInGuardedMode
  NewsSectionOversize(String)
  NewsContentHashMismatch
} derive(Eq, Show)

///|
/// Canonical kind tag.
pub fn news_kind() -> String {
  "loci.news.edition"
}

///|
/// Canonical version tag.
pub fn news_version() -> String {
  "v0"
}

///|
/// Cap for a single section body, in characters. Sections larger
/// than this are quarantined to avoid attention flooding.
pub fn news_section_size_cap() -> UInt {
  4096U
}

///|
/// Construct a news edition. Caller provides the content_hash
/// (usually computed over the serialized source payload before it
/// reaches this envelope).
pub fn NewsEdition::new(
  edition_id : String,
  published_at : String,
  publisher_id : String,
  network : NewsNetwork,
  content_hash : @hash.Hash,
  signature : @hash.Hash?,
  sections : Array[NewsSection],
  continuity : NewsContinuity,
  confidence : NewsConfidence,
) -> NewsEdition {
  {
    kind: news_kind(),
    version: news_version(),
    edition_id,
    published_at,
    publisher_id,
    network,
    content_hash,
    signature,
    sections,
    continuity,
    confidence,
  }
}

///|
/// Canonical tag for a network.
pub fn news_network_tag(n : NewsNetwork) -> String {
  match n {
    NetworkCni => "CNI"
    NetworkCgn => "CGN"
    NetworkCustom(name) => "custom:" + name
  }
}

///|
/// Validate an edition envelope shape and section size caps.
/// `require_signature` enforces the guarded-mode rule from the spec.
pub fn NewsEdition::validate(
  self : NewsEdition,
  require_signature : Bool,
) -> Result[Unit, NewsError] {
  if self.kind != news_kind() {
    return Err(NewsBadKind)
  }
  if self.version != news_version() {
    return Err(NewsBadVersion)
  }
  if self.edition_id == "" {
    return Err(NewsMissingField("edition_id"))
  }
  if self.published_at == "" {
    return Err(NewsMissingField("published_at"))
  }
  if self.publisher_id == "" {
    return Err(NewsMissingField("publisher_id"))
  }
  if hash_is_empty(self.content_hash) {
    return Err(NewsMissingField("content_hash"))
  }
  if require_signature {
    match self.signature {
      None => return Err(NewsMissingSignatureInGuardedMode)
      Some(sig) =>
        if hash_is_empty(sig) {
          return Err(NewsMissingSignatureInGuardedMode)
        }
    }
  }
  let cap = news_section_size_cap()
  for section in self.sections {
    if section.slug == "" {
      return Err(NewsMissingField("section.slug"))
    }
    if string_char_count(section.body) > cap {
      return Err(NewsSectionOversize(section.slug))
    }
  }
  Ok(())
}

///|
/// Compute the canonical content-hash material over the edition's
/// section payload. Callers seal this against the envelope's
/// `content_hash` to detect tampering.
pub fn NewsEdition::compute_content_hash(self : NewsEdition) -> @hash.Hash {
  let b = StringBuilder::new(size_hint=2048)
  b.write_string(self.kind)
  b.write_string("|")
  b.write_string(self.version)
  b.write_string("|")
  b.write_string(self.edition_id)
  b.write_string("|")
  b.write_string(self.published_at)
  b.write_string("|")
  b.write_string(self.publisher_id)
  b.write_string("|")
  b.write_string(news_network_tag(self.network))
  b.write_string("|sections=")
  b.write_string(self.sections.length().to_string())
  for section in self.sections {
    b.write_string(";")
    b.write_string(section.slug)
    b.write_string("=")
    b.write_string(section.body)
  }
  b.write_string("|cont=")
  b.write_string(self.continuity.new_count.to_string())
  b.write_string(",")
  b.write_string(self.continuity.continuing_count.to_string())
  b.write_string(",")
  b.write_string(self.continuity.resolved_count.to_string())
  b.write_string(",")
  b.write_string(self.continuity.quiet_count.to_string())
  b.write_string("|conf=")
  b.write_string(self.confidence.observed_count.to_string())
  b.write_string(",")
  b.write_string(self.confidence.inferred_count.to_string())
  b.write_string(",")
  b.write_string(self.confidence.unconfirmed_count.to_string())
  @hash.Hash::of_bytes(news_string_to_bytes(b.to_string()))
}

///|
/// Check that the envelope's declared `content_hash` matches the
/// recomputed hash over the payload. Returns `Err` if tampered.
pub fn NewsEdition::verify_content(
  self : NewsEdition,
) -> Result[Unit, NewsError] {
  let recomputed = self.compute_content_hash()
  if recomputed == self.content_hash {
    Ok(())
  } else {
    Err(NewsContentHashMismatch)
  }
}

///|
/// Render the normalized context block per the boot hook spec.
/// This is what the daemon exposes to conversation scaffolding —
/// never the raw payload.
pub fn NewsEdition::bounded_context_block(self : NewsEdition) -> String {
  let b = StringBuilder::new(size_hint=1024)
  b.write_string("[loci-news]\n")
  b.write_string("edition_id=")
  b.write_string(self.edition_id)
  b.write_string("\npublished_at=")
  b.write_string(self.published_at)
  b.write_string("\nnetwork=")
  b.write_string(news_network_tag(self.network))
  for section in self.sections {
    if section.slug == "summary" || section.slug == "trust_desk" {
      b.write_string("\n")
      b.write_string(section.slug)
      b.write_string("=")
      b.write_string(truncate_to(section.body, 512U))
    }
  }
  b.write_string("\ncontinuity=new:")
  b.write_string(self.continuity.new_count.to_string())
  b.write_string(",continuing:")
  b.write_string(self.continuity.continuing_count.to_string())
  b.write_string(",resolved:")
  b.write_string(self.continuity.resolved_count.to_string())
  b.write_string(",quiet:")
  b.write_string(self.continuity.quiet_count.to_string())
  b.write_string("\nconfidence=observed:")
  b.write_string(self.confidence.observed_count.to_string())
  b.write_string(",inferred:")
  b.write_string(self.confidence.inferred_count.to_string())
  b.write_string(",unconfirmed:")
  b.write_string(self.confidence.unconfirmed_count.to_string())
  b.write_string("\n")
  b.to_string()
}

///|
fn string_char_count(s : String) -> UInt {
  let mut n = 0U
  for _ch in s {
    n = n + 1U
  }
  n
}

///|
fn truncate_to(s : String, cap : UInt) -> String {
  let out = StringBuilder::new(size_hint=s.length())
  let mut n = 0U
  for ch in s {
    if n >= cap {
      break
    }
    out.write_char(ch)
    n = n + 1U
  }
  out.to_string()
}

///|
fn news_string_to_bytes(s : String) -> Bytes {
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
