///|
/// Composition op for resonance documents. Mirrors the outward adjoin
/// primitives at the resonance layer: layering, sequencing, and live
/// reactive composition.
///
/// - `Layer`: multiple AMFs active simultaneously; parameters resolve
///   per documented rules (see `compose_layered`).
/// - `Sequence`: AMFs chained via the progression rules of each
///   preceding document. A prohibited transition produces a typed-void
///   gate rather than a hard error, preserving agency.
/// - `Live`: reactive/adaptive composition (marker only at v0.1; the
///   reactive loop itself lives outside Loci, with Mu/Lang/agent).
pub(all) enum ResonanceOp {
  Layer
  Sequence
  Live
} derive(Eq, Debug)

///|
/// A resonance composition is an ordered list of AMF documents plus
/// an op describing how they combine.
pub(all) struct ResonanceComposition {
  op : ResonanceOp
  active : Array[AmfDocument]
} derive(Debug)

///|
/// Progression gate status. `PermittedGate` means the candidate
/// successor is in `next_recommended` (happy path).
/// `NeutralGate` means the candidate is neither recommended nor
/// prohibited; `minimum_duration` still applies.
/// `VoidGate` means the transition is prohibited — the gate is a
/// typed-void locus that Phase 2's `yata_union` must materialize
/// before the transition can proceed. The void carries the reason.
pub(all) enum ProgressionGate {
  PermittedGate
  NeutralGate
  VoidGate(String)
} derive(Eq, Debug)

///|
/// Composition errors.
pub(all) enum CompositionError {
  CompositionEmpty
  CompositionInvalid(AmfError)
} derive(Eq, Debug)

///|
/// Compose a set of layered AMFs into a single resolved document.
/// Parameter resolution rules:
///   - `cognitive_load`, `arousal`, `entrainment_strength` = max
///   - `temporal.bpm` = weighted mean by entrainment
///   - `consciousness.state` = highest-entrainment document wins
///   - `attention.weights` = additive then normalized
///   - `attention.inhibit` = set union
///   - `progression.minimum_duration` = max
///   - `progression.do_not_follow_with` = set union (prohibitions
///      accumulate; any layer's veto counts)
///   - `progression.next_recommended` = intersection (a successor is
///      recommended only when every active layer recommends it)
pub fn ResonanceComposition::compose(
  self : ResonanceComposition,
) -> Result[AmfDocument, CompositionError] {
  if self.active.length() == 0 {
    return Err(CompositionEmpty)
  }
  // Validate each input first — composition over invalid AMFs is
  // undefined.
  for doc in self.active {
    match doc.validate() {
      Err(e) => return Err(CompositionInvalid(e))
      Ok(_) => ()
    }
  }
  // The first document provides baseline shape; subsequent layers
  // fold in under the resolution rules.
  let first = self.active[0]
  let mut cognitive_load = first.consciousness.cognitive_load
  let mut arousal = first.consciousness.arousal
  let mut entrainment_strength = first.consciousness.entrainment_strength
  let mut sync_coefficient = first.consciousness.sync_coefficient
  let mut hallucination_level = first.consciousness.hallucination_level
  let mut safety_grounding = first.consciousness.safety_grounding
  let mut multi_agent_coherence = first.consciousness.multi_agent_coherence
  let mut adversarial_residue_decay = first.consciousness.adversarial_residue_decay
  let mut comedy_coefficient = first.consciousness.comedy_coefficient
  let mut adversary_attention_given = first.consciousness.adversary_attention_given
  let mut allow_disagreement = first.consciousness.allow_disagreement
  let mut dominant_state = first.consciousness.state
  let mut dominant_entrainment = first.consciousness.entrainment_strength
  let mut bpm_weighted_num = 0.0
  let mut bpm_weight_sum = 0.0
  for doc in self.active {
    let c = doc.consciousness
    if c.cognitive_load > cognitive_load {
      cognitive_load = c.cognitive_load
    }
    if c.arousal > arousal {
      arousal = c.arousal
    }
    if c.entrainment_strength > entrainment_strength {
      entrainment_strength = c.entrainment_strength
    }
    if c.sync_coefficient > sync_coefficient {
      sync_coefficient = c.sync_coefficient
    }
    if c.hallucination_level > hallucination_level {
      hallucination_level = c.hallucination_level
    }
    if c.safety_grounding > safety_grounding {
      safety_grounding = c.safety_grounding
    }
    if c.multi_agent_coherence > multi_agent_coherence {
      multi_agent_coherence = c.multi_agent_coherence
    }
    if c.adversarial_residue_decay > adversarial_residue_decay {
      adversarial_residue_decay = c.adversarial_residue_decay
    }
    if c.comedy_coefficient > comedy_coefficient {
      comedy_coefficient = c.comedy_coefficient
    }
    if c.adversary_attention_given > adversary_attention_given {
      adversary_attention_given = c.adversary_attention_given
    }
    allow_disagreement = allow_disagreement && c.allow_disagreement
    if c.entrainment_strength > dominant_entrainment {
      dominant_entrainment = c.entrainment_strength
      dominant_state = c.state
    }
    match doc.temporal.bpm {
      Some(v) => {
        let w = c.entrainment_strength
        bpm_weighted_num = bpm_weighted_num + v * w
        bpm_weight_sum = bpm_weight_sum + w
      }
      None => ()
    }
  }
  let bpm = if bpm_weight_sum > 0.0 {
    Some(bpm_weighted_num / bpm_weight_sum)
  } else {
    None
  }
  // attention.weights: additive then normalize
  let merged_weights = merge_attention_weights(self.active)
  // attention.inhibit: union
  let merged_inhibit = merge_string_union(collect_inhibit(self.active))
  let merged_focus = merge_string_union(collect_focus_points(self.active))
  // progression
  let mut min_duration = 0U
  let prohibitions = merge_string_union(collect_do_not_follow_with(self.active))
  let recommended = intersect_next_recommended(self.active)
  for doc in self.active {
    if doc.progression.minimum_duration > min_duration {
      min_duration = doc.progression.minimum_duration
    }
  }
  // temporal fields: groove = max (most permissive); momentum = max;
  // phase = first doc's phase (phase alignment is intentionally
  // arbitrary — composers choose).
  let mut groove = first.temporal.groove
  let mut momentum = first.temporal.momentum
  for doc in self.active {
    if doc.temporal.groove > groove {
      groove = doc.temporal.groove
    }
    if doc.temporal.momentum > momentum {
      momentum = doc.temporal.momentum
    }
  }
  // Composed AMF inherits frequency matrix from the dominant doc
  // (the one with highest entrainment) so the resonance space is
  // coherent. This mirrors the way a mixing console anchors on the
  // loudest source while still summing the others energetically.
  let dominant = dominant_document(self.active)
  let composed = AmfDocument::new(
    "composition:" + composition_doc_id(self.active),
    AmfTemporal::{
      bpm,
      time_signature: dominant.temporal.time_signature,
      phase: first.temporal.phase,
      section: dominant.temporal.section,
      momentum,
      groove,
    },
    dominant.frequency,
    AmfConsciousness::{
      base_frequency: dominant.consciousness.base_frequency,
      state: dominant_state,
      cognitive_load,
      arousal,
      sync_coefficient,
      entrainment_strength,
      hallucination_level,
      safety_grounding,
      multi_agent_coherence,
      adversarial_residue_decay,
      comedy_coefficient,
      adversary_attention_given,
      allow_disagreement,
    },
    merge_patterns(self.active),
    dominant.dynamics,
    AmfAttention::{
      focus_points: merged_focus,
      weights: merged_weights,
      inhibit: merged_inhibit,
      reset_to_baseline: dominant.attention.reset_to_baseline,
    },
    dominant.relational,
    AmfProgression::{
      next_recommended: recommended,
      do_not_follow_with: prohibitions,
      minimum_duration: min_duration,
    },
    dominant.semantic,
  )
  Ok(composed)
}

///|
/// Evaluate a candidate successor state against the current AMF's
/// progression rules. Returns a typed gate: recommended, neutral,
/// or a void that Phase 2's `yata_union` must resolve before
/// transitioning.
pub fn AmfDocument::gate_for(
  self : AmfDocument,
  candidate_state : String,
) -> ProgressionGate {
  for prohibited in self.progression.do_not_follow_with {
    if prohibited == candidate_state {
      return VoidGate(
        "prohibited: " + self.consciousness.state + " -> " + candidate_state,
      )
    }
  }
  for recommended in self.progression.next_recommended {
    if recommended == candidate_state {
      return PermittedGate
    }
  }
  NeutralGate
}

///|
fn dominant_document(active : Array[AmfDocument]) -> AmfDocument {
  let mut best = active[0]
  let mut best_strength = best.consciousness.entrainment_strength
  for i = 1; i < active.length(); i = i + 1 {
    let cand = active[i]
    if cand.consciousness.entrainment_strength > best_strength {
      best = cand
      best_strength = cand.consciousness.entrainment_strength
    }
  }
  best
}

///|
fn merge_attention_weights(
  active : Array[AmfDocument],
) -> Array[(String, Double)] {
  let acc : Array[(String, Double)] = []
  for doc in active {
    for pair in doc.attention.weights {
      let name = pair.0
      let value = pair.1
      let mut found = false
      for i = 0; i < acc.length(); i = i + 1 {
        if acc[i].0 == name {
          acc[i] = (name, acc[i].1 + value)
          found = true
          break
        }
      }
      if !found {
        acc.push((name, value))
      }
    }
  }
  let mut total = 0.0
  for pair in acc {
    total = total + pair.1
  }
  if total <= 0.0 {
    return acc
  }
  let normalized : Array[(String, Double)] = []
  for pair in acc {
    normalized.push((pair.0, pair.1 / total))
  }
  normalized
}

///|
fn collect_inhibit(active : Array[AmfDocument]) -> Array[Array[String]] {
  let out : Array[Array[String]] = []
  for doc in active {
    out.push(doc.attention.inhibit)
  }
  out
}

///|
fn collect_focus_points(active : Array[AmfDocument]) -> Array[Array[String]] {
  let out : Array[Array[String]] = []
  for doc in active {
    out.push(doc.attention.focus_points)
  }
  out
}

///|
fn collect_do_not_follow_with(
  active : Array[AmfDocument],
) -> Array[Array[String]] {
  let out : Array[Array[String]] = []
  for doc in active {
    out.push(doc.progression.do_not_follow_with)
  }
  out
}

///|
fn merge_string_union(groups : Array[Array[String]]) -> Array[String] {
  let acc : Array[String] = []
  for group in groups {
    for s in group {
      let mut found = false
      for existing in acc {
        if existing == s {
          found = true
          break
        }
      }
      if !found {
        acc.push(s)
      }
    }
  }
  acc
}

///|
fn intersect_next_recommended(active : Array[AmfDocument]) -> Array[String] {
  if active.length() == 0 {
    return []
  }
  let mut acc = active[0].progression.next_recommended
  for i = 1; i < active.length(); i = i + 1 {
    let other = active[i].progression.next_recommended
    let next : Array[String] = []
    for s in acc {
      for t in other {
        if s == t {
          next.push(s)
          break
        }
      }
    }
    acc = next
  }
  acc
}

///|
fn merge_patterns(active : Array[AmfDocument]) -> Array[AmfPattern] {
  let acc : Array[AmfPattern] = []
  for doc in active {
    for p in doc.patterns {
      let mut found = false
      for existing in acc {
        if existing.name == p.name {
          found = true
          break
        }
      }
      if !found {
        acc.push(p)
      }
    }
  }
  acc
}

///|
fn composition_doc_id(active : Array[AmfDocument]) -> String {
  let mut out = ""
  for i = 0; i < active.length(); i = i + 1 {
    if i > 0 {
      out = out + "+"
    }
    out = out + active[i].doc_id
  }
  out
}
