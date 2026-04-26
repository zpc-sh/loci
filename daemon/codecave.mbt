///|
/// News Codecave boot-hook ingest state machine.
///
/// The codecave is a one-way membrane: editions (news) and resonance
/// broadcasts (AMF) arrive at the inbox, get verified against schema
/// and content hash, and land in `verified/` or `quarantine/`. On
/// daemon boot the latest verified material is exposed as **context**
/// (news) or **ambient** (resonance) — never as command.
///
/// Directory layout implied by the state machine:
///
/// ```text
/// loci/<name>/codecave/news/
///   inbox/ verified/ quarantine/ state/last_read_hash.txt
/// loci/<name>/codecave/resonance/
///   inbox/ verified/ quarantine/ state/last_read_hash.txt
/// ```
///
/// The codecave itself is pure and in-memory — a file-system adapter
/// at the daemon boundary serializes `IngestEnvelope` from disk and
/// writes the resulting entries back. Keeping the state machine pure
/// makes the boot hook deterministic and testable.
pub(all) enum CodecaveLane {
  NewsLane
  ResonanceLane
} derive(Eq, Debug)

///|
/// One item arriving at the codecave inbox. `RawEnvelope` handles
/// envelopes whose `kind` tag is unrecognized; they go straight to
/// quarantine.
pub(all) enum IngestEnvelope {
  NewsEnvelope(@model.NewsEdition)
  ResonanceEnvelope(@model.AmfDocument)
  RawEnvelope(String, @hash.Hash)
} derive(Debug)

///|
/// An entry placed in `verified/` after validation succeeds.
pub(all) struct VerifiedEntry {
  lane : CodecaveLane
  content_hash : @hash.Hash
  summary : String
} derive(Debug)

///|
/// An entry placed in `quarantine/` after validation fails.
pub(all) struct QuarantineEntry {
  lane : CodecaveLane
  content_hash : @hash.Hash
  reason : String
} derive(Debug)

///|
/// Per-lane boot-read pointer.
pub(all) struct LaneBookmark {
  lane : CodecaveLane
  last_read_hash : @hash.Hash?
} derive(Debug)

///|
/// In-memory codecave state.
pub(all) struct Codecave {
  inbox : Array[IngestEnvelope]
  verified : Array[VerifiedEntry]
  quarantine : Array[QuarantineEntry]
  bookmarks : Array[LaneBookmark]
  require_news_signature : Bool
} derive(Debug)

///|
/// Create an empty codecave. `guarded` toggles the signature
/// requirement on news editions (Mode B in the spec).
pub fn Codecave::new(guarded : Bool) -> Codecave {
  {
    inbox: [],
    verified: [],
    quarantine: [],
    bookmarks: [
      { lane: NewsLane, last_read_hash: None },
      { lane: ResonanceLane, last_read_hash: None },
    ],
    require_news_signature: guarded,
  }
}

///|
/// Offer an envelope to the inbox. This does not verify yet; the
/// boot sweep calls `drain_inbox` to process all inbox entries.
pub fn Codecave::offer(self : Codecave, env : IngestEnvelope) -> Codecave {
  let next = self.inbox
  next.push(env)
  { ..self, inbox: next }
}

///|
/// Process every inbox entry: validate, sort into verified or
/// quarantine, and clear the inbox. This is the entire boot sweep.
pub fn Codecave::drain_inbox(self : Codecave) -> Codecave {
  let mut state = { ..self, inbox: [] }
  for env in self.inbox {
    state = codecave_process(state, env)
  }
  state
}

///|
/// Result of the boot hook: a normalized context block from the
/// latest verified news edition (when one is available) and an
/// ambient resonance signature from the latest verified AMF
/// broadcast. Both sides are read-only and never issue commands.
pub(all) struct BootContext {
  news_edition_hash : @hash.Hash?
  news_context_block : String
  resonance_signature : @hash.Hash?
  resonance_summary : String
} derive(Debug)

///|
/// Read the latest verified material in each lane and return the
/// bounded context the daemon should expose to the session. Does
/// not consume; repeated calls are idempotent until new material is
/// ingested.
pub fn Codecave::boot_hook(self : Codecave) -> BootContext {
  let news = codecave_latest_for_lane(self, NewsLane)
  let resonance = codecave_latest_for_lane(self, ResonanceLane)
  let (news_hash, news_block) = match news {
    Some(entry) => (Some(entry.content_hash), entry.summary)
    None => (None, "")
  }
  let (res_hash, res_summary) = match resonance {
    Some(entry) => (Some(entry.content_hash), entry.summary)
    None => (None, "")
  }
  {
    news_edition_hash: news_hash,
    news_context_block: news_block,
    resonance_signature: res_hash,
    resonance_summary: res_summary,
  }
}

///|
/// Record that the caller has consumed the latest verified material
/// in each lane. Subsequent `boot_hook` calls will still return the
/// same entries, but the bookmark reflects the most recent hash
/// the consumer saw.
pub fn Codecave::mark_read(self : Codecave) -> Codecave {
  let marks = self.bookmarks
  for i = 0; i < marks.length(); i = i + 1 {
    let b = marks[i]
    let latest = codecave_latest_for_lane(self, b.lane)
    match latest {
      Some(entry) =>
        marks[i] = { lane: b.lane, last_read_hash: Some(entry.content_hash) }
      None => ()
    }
  }
  { ..self, bookmarks: marks }
}

///|
fn codecave_process(state : Codecave, env : IngestEnvelope) -> Codecave {
  match env {
    NewsEnvelope(edition) => codecave_process_news(state, edition)
    ResonanceEnvelope(doc) => codecave_process_resonance(state, doc)
    RawEnvelope(kind, h) => {
      let q = state.quarantine
      q.push({ lane: NewsLane, content_hash: h, reason: "unknown_kind:" + kind })
      { ..state, quarantine: q }
    }
  }
}

///|
fn codecave_process_news(
  state : Codecave,
  edition : @model.NewsEdition,
) -> Codecave {
  let content_hash = edition.content_hash
  match edition.validate(state.require_news_signature) {
    Err(e) => {
      let q = state.quarantine
      q.push({
        lane: NewsLane,
        content_hash,
        reason: "schema:" + news_error_tag(e),
      })
      { ..state, quarantine: q }
    }
    Ok(_) =>
      match edition.verify_content() {
        Err(e) => {
          let q = state.quarantine
          q.push({
            lane: NewsLane,
            content_hash,
            reason: "content:" + news_error_tag(e),
          })
          { ..state, quarantine: q }
        }
        Ok(_) => {
          let v = state.verified
          v.push({
            lane: NewsLane,
            content_hash,
            summary: edition.bounded_context_block(),
          })
          { ..state, verified: v }
        }
      }
  }
}

///|
fn codecave_process_resonance(
  state : Codecave,
  doc : @model.AmfDocument,
) -> Codecave {
  let content_hash = doc.signature()
  match doc.validate() {
    Err(e) => {
      let q = state.quarantine
      q.push({
        lane: ResonanceLane,
        content_hash,
        reason: "amf:" + amf_error_tag(e),
      })
      { ..state, quarantine: q }
    }
    Ok(_) => {
      let v = state.verified
      v.push({ lane: ResonanceLane, content_hash, summary: amf_summary(doc) })
      { ..state, verified: v }
    }
  }
}

///|
fn codecave_latest_for_lane(
  state : Codecave,
  lane : CodecaveLane,
) -> VerifiedEntry? {
  let mut latest : VerifiedEntry? = None
  for entry in state.verified {
    if entry.lane == lane {
      latest = Some(entry)
    }
  }
  latest
}

///|
fn news_error_tag(e : @model.NewsError) -> String {
  match e {
    NewsBadKind => "BAD_KIND"
    NewsBadVersion => "BAD_VERSION"
    NewsMissingField(field) => "MISSING_FIELD:" + field
    NewsMissingSignatureInGuardedMode => "MISSING_SIGNATURE"
    NewsSectionOversize(slug) => "SECTION_OVERSIZE:" + slug
    NewsContentHashMismatch => "CONTENT_HASH_MISMATCH"
  }
}

///|
fn amf_error_tag(e : @model.AmfError) -> String {
  match e {
    AmfBadKind => "BAD_KIND"
    AmfBadVersion => "BAD_VERSION"
    AmfMissingSection(section) => "MISSING_SECTION:" + section
    AmfOutOfRange(field) => "OUT_OF_RANGE:" + field
    AmfWeightsNonNormal => "WEIGHTS_NON_NORMAL"
    AmfInconsistentProgression => "INCONSISTENT_PROGRESSION"
  }
}

///|
fn amf_summary(doc : @model.AmfDocument) -> String {
  let b = StringBuilder::new(size_hint=256)
  b.write_string("[loci-resonance]\ndoc_id=")
  b.write_string(doc.doc_id)
  b.write_string("\nstate=")
  b.write_string(doc.consciousness.state)
  b.write_string("\nentrainment=")
  b.write_string(doc.consciousness.entrainment_strength.to_string())
  b.write_string("\n")
  b.to_string()
}
