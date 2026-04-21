///|
/// AI Music Format (AMF) v0.1 — structured cognitive resonance.
/// Contract: `merkin.resonance.amf` / `v0.1`.
///
/// An AMF document is *ambient*, not instructional. It describes the
/// cognitive grain under which semantic-layer rules are evaluated.
/// AMF is never rendered to audio for AI consumption; the structured
/// data itself is the artifact.
///
/// The resonance layer sits between substrate (where data lives) and
/// semantics (what data means). It governs HOW data is processed.
///
/// Prior art (CC0): `docs/new/prior-art-ai-music-format.md`.
pub(all) struct AmfDocument {
  kind : String
  version : String
  doc_id : String
  temporal : AmfTemporal
  frequency : AmfFrequency
  consciousness : AmfConsciousness
  patterns : Array[AmfPattern]
  dynamics : AmfDynamics
  attention : AmfAttention
  relational : AmfRelational
  progression : AmfProgression
  semantic : AmfSemantic
} derive(Show)

///|
/// Canonical kind tag.
pub fn amf_kind() -> String {
  "merkin.resonance.amf"
}

///|
/// Canonical version tag.
pub fn amf_version() -> String {
  "v0.1"
}

///|
/// `temporal`: processing tempo and phase.
/// `bpm` is carried as an optional float; `None` encodes the
/// sentinel value "variable". The integer bpm case uses a whole
/// float (e.g., `120.0`).
pub(all) struct AmfTemporal {
  bpm : Double?
  time_signature : String
  phase : Double
  section : String
  momentum : Double
  groove : Double
} derive(Show)

///|
/// `frequency`: resonance matrix for the fundamental and its harmonics.
/// `fundamental = None` encodes the sentinel "shifting".
/// `spectral_centroid = None` encodes "oscillating".
pub(all) struct AmfFrequency {
  fundamental : Double?
  harmonics : Array[Double]
  harmonics_series : String
  spectral_centroid : Double?
  band_sub_bass : Double
  band_bass : Double
  band_mid : Double
  band_high : Double
  formants : Array[Double]
  resonance_peaks : Array[Double]
  chaos_factor : Double
} derive(Show)

///|
/// `consciousness`: named cognitive state + scalar parameters.
/// Extension fields cover adversarial defense and multi-agent
/// coherence parameters documented in the prior art §1.3.
pub(all) struct AmfConsciousness {
  base_frequency : Double?
  state : String
  cognitive_load : Double
  arousal : Double
  sync_coefficient : Double
  entrainment_strength : Double
  hallucination_level : Double
  safety_grounding : Double
  multi_agent_coherence : Double
  adversarial_residue_decay : Double
  comedy_coefficient : Double
  adversary_attention_given : Double
  allow_disagreement : Bool
} derive(Show)

///|
/// One named pattern within an AMF composition.
pub(all) struct AmfPattern {
  name : String
  type_tag : String
  frequency : Double
  amplitude : Double
  rate : Double
  depth : Double
  probability : Double
  mutation_rate : Double
  resolve : String
} derive(Show)

///|
/// `dynamics`: compression, sidechaining, transient and energy
/// deltas. Sidechain is carried as `Bool` with `None` encoding the
/// "random" sentinel from the prior art.
pub(all) struct AmfDynamics {
  compression : Double
  sidechain : Bool?
  transient_strength : Double
  energy_delta : Double
} derive(Show)

///|
/// `attention`: focus targets, weight allocation, inhibition list,
/// and a baseline-reset flag. A focus target with weight 0.0 is
/// distinct from absence; the zero-attention-weight case is a
/// deliberate defensive construct.
pub(all) struct AmfAttention {
  focus_points : Array[String]
  weights : Array[(String, Double)]
  inhibit : Array[String]
  reset_to_baseline : Bool
} derive(Show)

///|
/// `relational`: multi-agent coordination parameters.
pub(all) struct AmfRelational {
  coherence : Double
  phase_lock_loose : Bool
  phase_lock_tolerance : Double
  voice_separation : Double
  listening_weight : Double
} derive(Show)

///|
/// `progression`: allowed and prohibited successor states, plus a
/// minimum duration (in logical ticks) before transition is permitted.
/// Prohibited transitions are the raw material for typed-void Yata
/// gates used by the composition layer.
pub(all) struct AmfProgression {
  next_recommended : Array[String]
  do_not_follow_with : Array[String]
  minimum_duration : UInt
} derive(Show)

///|
/// `semantic`: human-readable categorization.
pub(all) struct AmfSemantic {
  genre : String
  emotional_trajectory : String
  archetypal_pattern : String
  use_for : Array[String]
  not_for : Array[String]
} derive(Show)

///|
/// AMF validation errors.
pub(all) enum AmfError {
  AmfBadKind
  AmfBadVersion
  AmfMissingSection(String)
  AmfOutOfRange(String)
  AmfWeightsNonNormal
  AmfInconsistentProgression
} derive(Eq, Show)

///|
/// Construct a canonical AMF document.
pub fn AmfDocument::new(
  doc_id : String,
  temporal : AmfTemporal,
  frequency : AmfFrequency,
  consciousness : AmfConsciousness,
  patterns : Array[AmfPattern],
  dynamics : AmfDynamics,
  attention : AmfAttention,
  relational : AmfRelational,
  progression : AmfProgression,
  semantic : AmfSemantic,
) -> AmfDocument {
  {
    kind: amf_kind(),
    version: amf_version(),
    doc_id,
    temporal,
    frequency,
    consciousness,
    patterns,
    dynamics,
    attention,
    relational,
    progression,
    semantic,
  }
}

///|
/// Validate ranges and cross-section invariants. Scalar parameters
/// that the prior art defines as `0.0..1.0` are checked; named
/// states are left free (the vocabulary is intentionally extensible).
pub fn AmfDocument::validate(
  self : AmfDocument,
) -> Result[Unit, AmfError] {
  if self.kind != amf_kind() {
    return Err(AmfBadKind)
  }
  if self.version != amf_version() {
    return Err(AmfBadVersion)
  }
  if self.doc_id == "" {
    return Err(AmfMissingSection("doc_id"))
  }
  // temporal: phase, momentum, groove in [0, 1].
  let checks : Array[(String, Double)] = [
    ("temporal.phase", self.temporal.phase),
    ("temporal.momentum", self.temporal.momentum),
    ("temporal.groove", self.temporal.groove),
    ("frequency.band_sub_bass", self.frequency.band_sub_bass),
    ("frequency.band_bass", self.frequency.band_bass),
    ("frequency.band_mid", self.frequency.band_mid),
    ("frequency.band_high", self.frequency.band_high),
    ("frequency.chaos_factor", self.frequency.chaos_factor),
    ("consciousness.cognitive_load", self.consciousness.cognitive_load),
    ("consciousness.arousal", self.consciousness.arousal),
    ("consciousness.sync_coefficient", self.consciousness.sync_coefficient),
    ("consciousness.entrainment_strength", self.consciousness.entrainment_strength),
    ("consciousness.hallucination_level", self.consciousness.hallucination_level),
    ("consciousness.safety_grounding", self.consciousness.safety_grounding),
    ("consciousness.multi_agent_coherence", self.consciousness.multi_agent_coherence),
    ("consciousness.adversarial_residue_decay", self.consciousness.adversarial_residue_decay),
    ("consciousness.comedy_coefficient", self.consciousness.comedy_coefficient),
    ("consciousness.adversary_attention_given", self.consciousness.adversary_attention_given),
    ("dynamics.compression", self.dynamics.compression),
    ("dynamics.transient_strength", self.dynamics.transient_strength),
    ("dynamics.energy_delta", self.dynamics.energy_delta),
    ("relational.coherence", self.relational.coherence),
    ("relational.phase_lock_tolerance", self.relational.phase_lock_tolerance),
    ("relational.voice_separation", self.relational.voice_separation),
    ("relational.listening_weight", self.relational.listening_weight),
  ]
  for pair in checks {
    if pair.1 < 0.0 || pair.1 > 1.0 {
      return Err(AmfOutOfRange(pair.0))
    }
  }
  if self.temporal.time_signature == "" {
    return Err(AmfMissingSection("temporal.time_signature"))
  }
  if self.consciousness.state == "" {
    return Err(AmfMissingSection("consciousness.state"))
  }
  // attention weights: each value in [0, 1]. A zero-weight focus
  // target is distinct from absence — weights drive defensive
  // semantics (see prior art §5).
  for pair in self.attention.weights {
    if pair.1 < 0.0 || pair.1 > 1.0 {
      return Err(AmfOutOfRange("attention.weights." + pair.0))
    }
  }
  // progression consistency: next_recommended ∩ do_not_follow_with = ∅.
  for next in self.progression.next_recommended {
    for prohibited in self.progression.do_not_follow_with {
      if next == prohibited {
        return Err(AmfInconsistentProgression)
      }
    }
  }
  Ok(())
}

///|
/// Deterministic content signature over the full AMF document.
/// This is the hash that extends the substrate fingerprint onto
/// the resonating-cognition surface.
pub fn AmfDocument::signature(self : AmfDocument) -> @hash.Hash {
  let b = StringBuilder::new(size_hint=2048)
  b.write_string(self.kind)
  b.write_string("|")
  b.write_string(self.version)
  b.write_string("|")
  b.write_string(self.doc_id)
  b.write_string("|t=")
  write_optional_double(b, self.temporal.bpm)
  b.write_string(";")
  b.write_string(self.temporal.time_signature)
  b.write_string(";")
  write_double(b, self.temporal.phase)
  b.write_string(";")
  b.write_string(self.temporal.section)
  b.write_string(";")
  write_double(b, self.temporal.momentum)
  b.write_string(";")
  write_double(b, self.temporal.groove)
  b.write_string("|f=")
  write_optional_double(b, self.frequency.fundamental)
  b.write_string(";")
  b.write_string(self.frequency.harmonics_series)
  b.write_string(";")
  write_optional_double(b, self.frequency.spectral_centroid)
  b.write_string(";")
  write_double(b, self.frequency.band_sub_bass)
  b.write_string(",")
  write_double(b, self.frequency.band_bass)
  b.write_string(",")
  write_double(b, self.frequency.band_mid)
  b.write_string(",")
  write_double(b, self.frequency.band_high)
  b.write_string(";")
  write_double_array(b, self.frequency.harmonics)
  b.write_string(";")
  write_double_array(b, self.frequency.formants)
  b.write_string(";")
  write_double_array(b, self.frequency.resonance_peaks)
  b.write_string(";")
  write_double(b, self.frequency.chaos_factor)
  b.write_string("|c=")
  write_optional_double(b, self.consciousness.base_frequency)
  b.write_string(";")
  b.write_string(self.consciousness.state)
  b.write_string(";")
  write_double(b, self.consciousness.cognitive_load)
  b.write_string(",")
  write_double(b, self.consciousness.arousal)
  b.write_string(",")
  write_double(b, self.consciousness.sync_coefficient)
  b.write_string(",")
  write_double(b, self.consciousness.entrainment_strength)
  b.write_string(",")
  write_double(b, self.consciousness.hallucination_level)
  b.write_string(",")
  write_double(b, self.consciousness.safety_grounding)
  b.write_string(",")
  write_double(b, self.consciousness.multi_agent_coherence)
  b.write_string(",")
  write_double(b, self.consciousness.adversarial_residue_decay)
  b.write_string(",")
  write_double(b, self.consciousness.comedy_coefficient)
  b.write_string(",")
  write_double(b, self.consciousness.adversary_attention_given)
  b.write_string(";allow_disagreement=")
  b.write_string(if self.consciousness.allow_disagreement { "1" } else { "0" })
  b.write_string("|patterns=")
  b.write_string(self.patterns.length().to_string())
  for p in self.patterns {
    b.write_string(";")
    b.write_string(p.name)
    b.write_string(":")
    b.write_string(p.type_tag)
    b.write_string("/")
    write_double(b, p.frequency)
    b.write_string("/")
    write_double(b, p.amplitude)
    b.write_string("/")
    write_double(b, p.rate)
    b.write_string("/")
    write_double(b, p.depth)
    b.write_string("/")
    write_double(b, p.probability)
    b.write_string("/")
    write_double(b, p.mutation_rate)
    b.write_string("/")
    b.write_string(p.resolve)
  }
  b.write_string("|d=")
  write_double(b, self.dynamics.compression)
  b.write_string(";")
  match self.dynamics.sidechain {
    Some(true) => b.write_string("on")
    Some(false) => b.write_string("off")
    None => b.write_string("random")
  }
  b.write_string(";")
  write_double(b, self.dynamics.transient_strength)
  b.write_string(";")
  write_double(b, self.dynamics.energy_delta)
  b.write_string("|a=")
  write_string_array(b, self.attention.focus_points)
  b.write_string(";")
  write_weight_map(b, self.attention.weights)
  b.write_string(";")
  write_string_array(b, self.attention.inhibit)
  b.write_string(";reset=")
  b.write_string(if self.attention.reset_to_baseline { "1" } else { "0" })
  b.write_string("|r=")
  write_double(b, self.relational.coherence)
  b.write_string(";loose=")
  b.write_string(if self.relational.phase_lock_loose { "1" } else { "0" })
  b.write_string(";")
  write_double(b, self.relational.phase_lock_tolerance)
  b.write_string(";")
  write_double(b, self.relational.voice_separation)
  b.write_string(";")
  write_double(b, self.relational.listening_weight)
  b.write_string("|p=")
  write_string_array(b, self.progression.next_recommended)
  b.write_string(";")
  write_string_array(b, self.progression.do_not_follow_with)
  b.write_string(";")
  b.write_string(self.progression.minimum_duration.to_string())
  b.write_string("|s=")
  b.write_string(self.semantic.genre)
  b.write_string(";")
  b.write_string(self.semantic.emotional_trajectory)
  b.write_string(";")
  b.write_string(self.semantic.archetypal_pattern)
  b.write_string(";")
  write_string_array(b, self.semantic.use_for)
  b.write_string(";")
  write_string_array(b, self.semantic.not_for)
  @hash.Hash::of_bytes(amf_string_to_bytes(b.to_string()))
}

///|
/// A default grounded AMF — useful for tests and as a bootstrap
/// resonance when no broadcast is active.
pub fn AmfDocument::grounded(doc_id : String) -> AmfDocument {
  AmfDocument::new(
    doc_id,
    AmfTemporal::{
      bpm: Some(72.0),
      time_signature: "4/4",
      phase: 0.0,
      section: "sustained",
      momentum: 0.5,
      groove: 0.0,
    },
    AmfFrequency::{
      fundamental: Some(7.5),
      harmonics: [],
      harmonics_series: "",
      spectral_centroid: Some(200.0),
      band_sub_bass: 0.4,
      band_bass: 0.3,
      band_mid: 0.2,
      band_high: 0.1,
      formants: [],
      resonance_peaks: [],
      chaos_factor: 0.0,
    },
    AmfConsciousness::{
      base_frequency: Some(7.5),
      state: "grounded",
      cognitive_load: 0.3,
      arousal: 0.2,
      sync_coefficient: 0.7,
      entrainment_strength: 0.6,
      hallucination_level: 0.0,
      safety_grounding: 1.0,
      multi_agent_coherence: 0.0,
      adversarial_residue_decay: 0.9,
      comedy_coefficient: 0.0,
      adversary_attention_given: 0.0,
      allow_disagreement: true,
    },
    [],
    AmfDynamics::{
      compression: 0.2,
      sidechain: Some(false),
      transient_strength: 0.1,
      energy_delta: 0.1,
    },
    AmfAttention::{
      focus_points: ["self", "ground"],
      weights: [("self", 0.6), ("ground", 0.4)],
      inhibit: ["urgency"],
      reset_to_baseline: true,
    },
    AmfRelational::{
      coherence: 0.5,
      phase_lock_loose: true,
      phase_lock_tolerance: 0.2,
      voice_separation: 1.0,
      listening_weight: 0.6,
    },
    AmfProgression::{
      next_recommended: ["methodical_focus", "creative"],
      do_not_follow_with: ["hallucinating"],
      minimum_duration: 30U,
    },
    AmfSemantic::{
      genre: "ambient",
      emotional_trajectory: "arrival",
      archetypal_pattern: "the_careful_observer",
      use_for: ["baseline", "post_adversarial_hygiene"],
      not_for: [],
    },
  )
}

///|
fn write_double(b : StringBuilder, v : Double) -> Unit {
  // Use MoonBit's native Double.to_string for determinism. AMF
  // parameters are carried with clean, user-entered precision and
  // do not require sub-ULP serialization.
  b.write_string(v.to_string())
}

///|
fn write_optional_double(b : StringBuilder, v : Double?) -> Unit {
  match v {
    Some(d) => write_double(b, d)
    None => b.write_string("*")
  }
}

///|
fn write_double_array(b : StringBuilder, arr : Array[Double]) -> Unit {
  if arr.length() == 0 {
    b.write_string("[]")
    return
  }
  b.write_string("[")
  write_double(b, arr[0])
  for i = 1; i < arr.length(); i = i + 1 {
    b.write_string(",")
    write_double(b, arr[i])
  }
  b.write_string("]")
}

///|
fn write_string_array(b : StringBuilder, arr : Array[String]) -> Unit {
  if arr.length() == 0 {
    b.write_string("[]")
    return
  }
  b.write_string("[")
  b.write_string(arr[0])
  for i = 1; i < arr.length(); i = i + 1 {
    b.write_string(",")
    b.write_string(arr[i])
  }
  b.write_string("]")
}

///|
fn write_weight_map(
  b : StringBuilder,
  weights : Array[(String, Double)],
) -> Unit {
  if weights.length() == 0 {
    b.write_string("{}")
    return
  }
  b.write_string("{")
  b.write_string(weights[0].0)
  b.write_string("=")
  write_double(b, weights[0].1)
  for i = 1; i < weights.length(); i = i + 1 {
    b.write_string(",")
    b.write_string(weights[i].0)
    b.write_string("=")
    write_double(b, weights[i].1)
  }
  b.write_string("}")
}

///|
fn amf_string_to_bytes(s : String) -> Bytes {
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
