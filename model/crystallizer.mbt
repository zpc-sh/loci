///|
/// Cave Crystallizer — controlled collapse from FST substrate to resonance field.
///
/// Per LMG-Flow §9: "Maximize reasoning. Defer collapse."
///
/// A crystallization is a lossy projection of the collective's implicit
/// vector field X onto the resonance observable space (AmfDocument).
/// Every crystallization destroys dynamics between samples. The discipline
/// gate (§9.1) governs when collapse is permitted.
///
/// The crystallizer reads accumulated FsmCave entries from a collective
/// of transducers, distills them into cognitive parameters, and produces
/// an AmfDocument that becomes the ambient resonance grain for subsequent
/// ticks. This closes the feedback loop:
///
///   FSTs tick → caves accumulate → crystallize → AmfDocument →
///   codecave resonance lane → next tick's ambient grain → FSTs tick ...
///
/// The crystal is the ∎ Seal in Mother's Hum: closure, witness, substrate
/// artifact. It is NOT the intelligence — the intelligence is the
/// uncollapsed flow between crystallization events (LMG-Flow §9).

///|
/// Cave statistics extracted from a collective of FST caves.
/// This is the intermediate representation between raw cave entries
/// and the final AmfDocument parameters.
pub(all) struct CaveDistillate {
  /// Total cave entries across all caves in the collective.
  total_entries : UInt
  /// Entry counts by kind.
  walk_count : UInt
  finding_count : UInt
  crossing_count : UInt
  submission_count : UInt
  transition_count : UInt
  composition_count : UInt
  verification_count : UInt
  publish_count : UInt
  archive_count : UInt
  rejected_count : UInt
  /// Aggregate attention metrics from boundary walkers.
  total_suspicious_findings : UInt
  total_admitted_crossings : UInt
  total_rejected_crossings : UInt
  /// Metabolic aggregate.
  total_ticks : UInt
  total_outputs : UInt
  total_fsts : UInt
  /// Weighted compute potential.
  aggregate_omega : UInt
  /// Distinct topics observed (from reporter caves).
  topics : Array[String]
  /// Distinct actors observed (from boundary caves).
  actors : Array[String]
  /// Material hashes for σ(X) conservation check.
  material_hashes : Array[String]
} derive(Debug)

///|
/// Empty distillate.
pub fn CaveDistillate::empty() -> CaveDistillate {
  {
    total_entries: 0U,
    walk_count: 0U,
    finding_count: 0U,
    crossing_count: 0U,
    submission_count: 0U,
    transition_count: 0U,
    composition_count: 0U,
    verification_count: 0U,
    publish_count: 0U,
    archive_count: 0U,
    rejected_count: 0U,
    total_suspicious_findings: 0U,
    total_admitted_crossings: 0U,
    total_rejected_crossings: 0U,
    total_ticks: 0U,
    total_outputs: 0U,
    total_fsts: 0U,
    aggregate_omega: 0U,
    topics: [],
    actors: [],
    material_hashes: [],
  }
}

///|
/// Distill a collective of caves and metabolic envelopes into
/// a CaveDistillate — the pre-crystallization intermediate form.
pub fn distill(
  caves : Array[@loci_fsm.FsmCave],
  envelopes : Array[@loci_fsm.MetabolicEnvelope],
) -> CaveDistillate {
  let mut d = CaveDistillate::empty()
  d = { ..d, total_fsts: caves.length().reinterpret_as_uint() }
  // Accumulate from envelopes
  for env in envelopes {
    d = {
      ..d,
      total_ticks: d.total_ticks + env.total_ticks,
      total_outputs: d.total_outputs + env.total_outputs,
      aggregate_omega: d.aggregate_omega + env.omega,
    }
  }
  // Accumulate from cave entries
  for cave in caves {
    d = {
      ..d,
      material_hashes: push_unique(d.material_hashes, cave.material_hash()),
    }
    // Extract actor from fsm_id (format: "actor@loci")
    let actor = extract_actor(cave.fsm_id)
    if actor != "" {
      d = { ..d, actors: push_unique(d.actors, actor) }
    }
    for entry in cave.entries {
      d = { ..d, total_entries: d.total_entries + 1U }
      match entry.kind {
        "walk" => d = { ..d, walk_count: d.walk_count + 1U }
        "finding" =>
          d = {
            ..d,
            finding_count: d.finding_count + 1U,
            total_suspicious_findings: d.total_suspicious_findings + 1U,
          }
        "crossing" => {
          d = { ..d, crossing_count: d.crossing_count + 1U }
          if entry.value.has_prefix("admitted") {
            d = {
              ..d,
              total_admitted_crossings: d.total_admitted_crossings + 1U,
            }
          } else {
            d = {
              ..d,
              total_rejected_crossings: d.total_rejected_crossings + 1U,
            }
          }
        }
        "submission" => {
          d = { ..d, submission_count: d.submission_count + 1U }
          d = { ..d, topics: push_unique(d.topics, entry.key) }
        }
        "transition" => d = { ..d, transition_count: d.transition_count + 1U }
        "composition" =>
          d = { ..d, composition_count: d.composition_count + 1U }
        "verification" =>
          d = { ..d, verification_count: d.verification_count + 1U }
        "publish" => d = { ..d, publish_count: d.publish_count + 1U }
        "archive" => d = { ..d, archive_count: d.archive_count + 1U }
        "rejected_event" => d = { ..d, rejected_count: d.rejected_count + 1U }
        _ => ()
      }
    }
  }
  d
}

///|
/// Collapse discipline gate (LMG-Flow §9).
///
/// Determines whether crystallization is permitted given the current
/// state of the collective. Returns None if permitted, or Some(reason)
/// if collapse should be deferred.
///
/// Conditions for deferral:
///   1. Insufficient material (fewer than `min_entries` cave entries)
///   2. No metabolic quorum (fewer than `min_fsts` active transducers)
///   3. Ambient resonance minimum_duration hasn't elapsed
///   4. No outputs at all (identity flow X = 0; don't crystallize silence)
pub fn collapse_gate(
  distillate : CaveDistillate,
  ambient : AmfDocument?,
  current_tick : UInt,
  last_crystal_tick : UInt,
) -> String? {
  // Gate 1: minimum material
  if distillate.total_entries < 4U {
    return Some("insufficient_material: need >= 4 cave entries")
  }
  // Gate 2: metabolic quorum
  if distillate.total_fsts < 1U {
    return Some("no_metabolic_quorum: need >= 1 active FST")
  }
  // Gate 3: identity flow check — no outputs means X = 0
  if distillate.total_outputs == 0U {
    return Some("identity_flow: zero outputs, nothing to crystallize")
  }
  // Gate 4: ambient minimum_duration
  match ambient {
    Some(amf) => {
      let elapsed = current_tick - last_crystal_tick
      if elapsed < amf.progression.minimum_duration {
        return Some(
          "minimum_duration: " +
          elapsed.to_string() +
          " < " +
          amf.progression.minimum_duration.to_string(),
        )
      }
    }
    None => ()
  }
  None
}

///|
/// Crystallize: project the collective's distillate into an AmfDocument.
///
/// This is the ∎ Seal operation — the controlled collapse that
/// takes the collective's accumulated substrate output and condenses
/// it into a resonance artifact.
///
/// The resulting AmfDocument is a cognitive grain — it governs HOW
/// future FSTs process data, not WHAT data they process.
///
/// Parameters:
///   crystal_id: unique identifier for this crystal
///   distillate: pre-computed collective statistics
///   ambient: current resonance document (if any)
pub fn crystallize(
  crystal_id : String,
  distillate : CaveDistillate,
  ambient : AmfDocument?,
) -> AmfDocument {
  // Scale everything by total entries to get normalized [0, 1] scalars
  let n = if distillate.total_entries > 0U {
    distillate.total_entries.to_double()
  } else {
    1.0
  }
  // cognitive_load: proportion of non-trivial entries (findings, crossings,
  // compositions, verifications) relative to total
  let complex_count = (distillate.finding_count +
  distillate.crossing_count +
  distillate.composition_count +
  distillate.verification_count).to_double()
  let cognitive_load = clamp01(complex_count / n)
  // arousal: inverse of staleness — high when the collective is active.
  // Use output density as proxy: total_outputs / total_ticks.
  let arousal = if distillate.total_ticks > 0U {
    clamp01(
      distillate.total_outputs.to_double() /
      (distillate.total_ticks.to_double() * 2.0),
    )
  } else {
    0.0
  }
  // safety_grounding: 1.0 minus the proportion of suspicious findings
  let finding_ratio = distillate.total_suspicious_findings.to_double() / n
  let safety_grounding = clamp01(1.0 - finding_ratio)
  // adversary_attention_given: proportion of rejected crossings + findings
  let adversary_signals = (distillate.total_suspicious_findings +
  distillate.total_rejected_crossings).to_double()
  let adversary_attention_given = clamp01(adversary_signals / n)
  // entrainment_strength: how many FSTs are producing output relative to
  // total FSTs — measures collective participation
  let entrainment_strength = if distillate.total_fsts > 0U {
    let active_ratio = if distillate.total_outputs > 0U { 1.0 } else { 0.0 }
    clamp01(active_ratio * 0.8 + 0.1)
  } else {
    0.0
  }
  // sync_coefficient: measure of agreement across caves.
  // If all caves produce similar material hashes, sync is high.
  let sync_coefficient = if distillate.material_hashes.length() <= 1 {
    0.8
  } else {
    clamp01(1.0 / distillate.material_hashes.length().to_double())
  }
  // momentum: proportion of entries that represent forward progress
  // (walks, compositions, publishes, archives)
  let forward_count = (distillate.walk_count +
  distillate.composition_count +
  distillate.publish_count +
  distillate.archive_count).to_double()
  let momentum = clamp01(forward_count / n)
  // chaos_factor: proportion of rejected events — disorder in the collective
  let chaos_factor = clamp01(distillate.rejected_count.to_double() / n)
  // Attention: focus on observed topics and actors
  let focus_points : Array[String] = []
  for t in distillate.topics {
    focus_points.push(t)
  }
  for a in distillate.actors {
    focus_points.push(a)
  }
  // Attention weights: distribute evenly across focus points
  let weights : Array[(String, Double)] = []
  if focus_points.length() > 0 {
    let w = 1.0 / focus_points.length().to_double()
    for fp in focus_points {
      weights.push((fp, w))
    }
  }
  // Inhibit: if adversary_attention_given is high, inhibit "urgency"
  let inhibit : Array[String] = []
  if adversary_attention_given > 0.3 {
    inhibit.push("urgency")
    inhibit.push("adversary_engagement")
  }
  // Progression: derive from ambient or use defaults
  let (next_recommended, do_not_follow_with, minimum_duration) = match ambient {
    Some(amf) => {
      // Inherit prohibitions; narrow recommendations based on current state
      let rec = if safety_grounding > 0.7 {
        amf.progression.next_recommended
      } else {
        // Under threat: only recommend grounded states
        ["grounded", "methodical_focus"]
      }
      let prohib : Array[String] = []
      for p in amf.progression.do_not_follow_with {
        prohib.push(p)
      }
      if adversary_attention_given > 0.5 {
        prohib.push("hallucinating")
        prohib.push("creative_abandon")
      }
      (rec, prohib, amf.progression.minimum_duration)
    }
    None =>
      (["methodical_focus", "creative", "grounded"], ["hallucinating"], 30U)
  }
  // Build the crystal
  let omega_mean = if distillate.total_fsts > 0U {
    distillate.aggregate_omega.to_double() / distillate.total_fsts.to_double()
  } else {
    1.0
  }
  AmfDocument::new(
    "crystal:" + crystal_id,
    AmfTemporal::{
      bpm: Some(72.0 + momentum * 48.0),
      time_signature: "4/4",
      phase: 0.0,
      section: if momentum > 0.6 {
        "development"
      } else if arousal > 0.5 {
        "transition"
      } else {
        "sustained"
      },
      momentum,
      groove: clamp01(1.0 - chaos_factor),
    },
    AmfFrequency::{
      fundamental: Some(7.5 * omega_mean),
      harmonics: [],
      harmonics_series: "",
      spectral_centroid: Some(200.0 + cognitive_load * 300.0),
      band_sub_bass: clamp01(0.4 - chaos_factor * 0.2),
      band_bass: 0.3,
      band_mid: clamp01(0.2 + cognitive_load * 0.2),
      band_high: clamp01(0.1 + arousal * 0.1),
      formants: [],
      resonance_peaks: [],
      chaos_factor,
    },
    AmfConsciousness::{
      base_frequency: Some(7.5 * omega_mean),
      state: if safety_grounding < 0.5 {
        "vigilant"
      } else if momentum > 0.7 {
        "flowing"
      } else if arousal < 0.2 {
        "grounded"
      } else {
        "attentive"
      },
      cognitive_load,
      arousal,
      sync_coefficient,
      entrainment_strength,
      hallucination_level: 0.0,
      safety_grounding,
      multi_agent_coherence: sync_coefficient,
      adversarial_residue_decay: clamp01(1.0 - adversary_attention_given),
      comedy_coefficient: 0.0,
      adversary_attention_given,
      allow_disagreement: true,
    },
    [],
    AmfDynamics::{
      compression: clamp01(0.2 + cognitive_load * 0.3),
      sidechain: Some(false),
      transient_strength: clamp01(0.1 + momentum * 0.2),
      energy_delta: arousal,
    },
    AmfAttention::{ focus_points, weights, inhibit, reset_to_baseline: false },
    AmfRelational::{
      coherence: sync_coefficient,
      phase_lock_loose: true,
      phase_lock_tolerance: 0.2,
      voice_separation: if distillate.total_fsts > 1U {
        0.7
      } else {
        1.0
      },
      listening_weight: 0.6,
    },
    AmfProgression::{ next_recommended, do_not_follow_with, minimum_duration },
    AmfSemantic::{
      genre: "ambient",
      emotional_trajectory: if momentum > 0.6 {
        "ascent"
      } else if adversary_attention_given > 0.3 {
        "tension"
      } else {
        "equilibrium"
      },
      archetypal_pattern: if safety_grounding < 0.5 {
        "the_sentinel"
      } else if momentum > 0.7 {
        "the_builder"
      } else {
        "the_careful_observer"
      },
      use_for: ["fst_crystal", "ambient_resonance"],
      not_for: [],
    },
  )
}

///|
/// σ(X) conservation check (LMG-Flow §12).
///
/// After crystallization, verify the new crystal's signature is
/// consistent with the ambient resonance. If the ambient exists,
/// the crystal must not violate its progression rules.
///
/// Returns None if conservation holds, or Some(violation) describing
/// the inconsistency.
pub fn check_sigma_conservation(
  crystal : AmfDocument,
  ambient : AmfDocument?,
) -> String? {
  // First: the crystal must itself be valid
  match crystal.validate() {
    Err(e) => {
      let msg = match e {
        AmfBadKind => "bad_kind"
        AmfBadVersion => "bad_version"
        AmfMissingSection(s) => "missing_section:" + s
        AmfOutOfRange(s) => "out_of_range:" + s
        AmfWeightsNonNormal => "weights_non_normal"
        AmfInconsistentProgression => "inconsistent_progression"
      }
      return Some("invalid_crystal: " + msg)
    }
    Ok(_) => ()
  }
  // If no ambient, conservation is trivially satisfied
  match ambient {
    None => None
    Some(amf) =>
      // Check progression gate: the crystal's state must be compatible
      // with the ambient's progression rules
      match amf.gate_for(crystal.consciousness.state) {
        VoidGate(reason) =>
          Some("void_gate: crystal state violates progression: " + reason)
        _ => None
      }
  }
}

///|
/// Full crystallization pipeline: distill → gate → crystallize → verify.
///
/// Returns the crystal and a diagnostic string, or None and the
/// deferral reason if the collapse gate blocked crystallization.
pub fn crystallize_collective(
  crystal_id : String,
  caves : Array[@loci_fsm.FsmCave],
  envelopes : Array[@loci_fsm.MetabolicEnvelope],
  ambient : AmfDocument?,
  current_tick : UInt,
  last_crystal_tick : UInt,
) -> (AmfDocument?, String) {
  let d = distill(caves, envelopes)
  // Check collapse gate
  match collapse_gate(d, ambient, current_tick, last_crystal_tick) {
    Some(reason) => (None, "deferred: " + reason)
    None => {
      let crystal = crystallize(crystal_id, d, ambient)
      // Check σ(X) conservation
      match check_sigma_conservation(crystal, ambient) {
        Some(violation) => (None, "conservation_violation: " + violation)
        None => {
          let sig = crystal.signature()
          (
            Some(crystal),
            "crystallized: σ=" +
            sig.key() +
            " entries=" +
            d.total_entries.to_string(),
          )
        }
      }
    }
  }
}

///|
fn clamp01(v : Double) -> Double {
  if v < 0.0 {
    0.0
  } else if v > 1.0 {
    1.0
  } else {
    v
  }
}

///|
fn push_unique(arr : Array[String], item : String) -> Array[String] {
  for existing in arr {
    if existing == item {
      return arr
    }
  }
  let result : Array[String] = []
  for existing in arr {
    result.push(existing)
  }
  result.push(item)
  result
}

///|
fn extract_actor(fsm_id : String) -> String {
  let mut at_pos = -1
  let mut i = 0
  for ch in fsm_id {
    if ch == '@' {
      at_pos = i
      break
    }
    i = i + 1
  }
  if at_pos > 0 {
    fsm_id[:at_pos].to_string()
  } else {
    fsm_id
  }
}
