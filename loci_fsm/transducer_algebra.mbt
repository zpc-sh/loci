///|
/// Transducer set algebra: Union, Subtract, Diff.
///
/// These operations mirror the loci composition algebra but operate
/// on FST output tapes rather than on Merkle nodes.
///
/// Union(T₁, T₂):    Run both, merge output tapes.
/// Subtract(T₁, T₂): Run both, emit T₁'s outputs that T₂ didn't produce.
/// Diff(T₁, T₂):     Run both, emit outputs unique to each side.
///
/// Each composed form is itself a value that implements Transducer,
/// so compositions can be composed — the blob intelligence amasses
/// through recursive algebraic combination.
///
/// The state of the composition IS the states of its parts. When
/// stored in loci, the entire composed blob serializes as a single
/// node whose children are the constituent transducers.

///|
/// Union: T₁ ∪ T₂. Both transducers receive every input.
/// Output tape is the merge of both output tapes.
/// This is the "swarm" primitive — two transducers attending
/// the same input stream in parallel.
pub(all) struct TransducerUnion[A, B] {
  left : A
  right : B
  envelope : MetabolicEnvelope
} derive(Debug)

///|
pub fn[A, B] TransducerUnion::new(
  left : A,
  right : B,
  birth_tick : UInt,
) -> TransducerUnion[A, B] {
  { left, right, envelope: MetabolicEnvelope::new(birth_tick) }
}

///|
pub impl[A : Transducer, B : Transducer] Transducer for TransducerUnion[A, B] with transduce(
  self,
  input,
) {
  let (next_left, left_outputs) = self.left.transduce(input)
  let (next_right, right_outputs) = self.right.transduce(input)
  let merged : Array[TransducerOutput] = []
  for out in left_outputs {
    merged.push(out)
  }
  for out in right_outputs {
    merged.push(out)
  }
  let envelope = self.envelope
    .tick(self.envelope.last_tick + 1U)
    .record_outputs(merged.length().reinterpret_as_uint())
  ({ left: next_left, right: next_right, envelope }, merged)
}

///|
pub impl[A : Transducer, B : Transducer] Transducer for TransducerUnion[A, B] with state_tag(
  self,
) {
  "union(" + self.left.state_tag() + "," + self.right.state_tag() + ")"
}

///|
pub impl[A : Transducer, B : Transducer] Transducer for TransducerUnion[A, B] with accepting(
  self,
) {
  self.left.accepting() && self.right.accepting()
}

///|
pub impl[A : Transducer, B : Transducer] Transducer for TransducerUnion[A, B] with personality_name(
  _self,
) {
  "union"
}

///|
/// Subtract: T₁ \ T₂. Both receive input, but only outputs from T₁
/// that have no matching cave-entry key in T₂'s outputs are emitted.
/// This is the "fence" primitive — T₂ acts as a filter/blocker.
pub(all) struct TransducerSubtract[A, B] {
  primary : A
  filter : B
  envelope : MetabolicEnvelope
} derive(Debug)

///|
pub fn[A, B] TransducerSubtract::new(
  primary : A,
  filter : B,
  birth_tick : UInt,
) -> TransducerSubtract[A, B] {
  { primary, filter, envelope: MetabolicEnvelope::new(birth_tick) }
}

///|
pub impl[A : Transducer, B : Transducer] Transducer for TransducerSubtract[A, B] with transduce(
  self,
  input,
) {
  let (next_primary, primary_outputs) = self.primary.transduce(input)
  let (next_filter, filter_outputs) = self.filter.transduce(input)
  let filter_keys = collect_cave_keys(filter_outputs)
  let result : Array[TransducerOutput] = []
  for out in primary_outputs {
    let key = output_cave_key(out)
    if !set_contains(filter_keys, key) {
      result.push(out)
    }
  }
  let envelope = self.envelope
    .tick(self.envelope.last_tick + 1U)
    .record_outputs(result.length().reinterpret_as_uint())
  ({ primary: next_primary, filter: next_filter, envelope }, result)
}

///|
pub impl[A : Transducer, B : Transducer] Transducer for TransducerSubtract[A, B] with state_tag(
  self,
) {
  "subtract(" + self.primary.state_tag() + "," + self.filter.state_tag() + ")"
}

///|
pub impl[A : Transducer, B : Transducer] Transducer for TransducerSubtract[A, B] with accepting(
  self,
) {
  self.primary.accepting()
}

///|
pub impl[A : Transducer, B : Transducer] Transducer for TransducerSubtract[A, B] with personality_name(
  _self,
) {
  "subtract"
}

///|
/// Diff: T₁ Δ T₂. Both receive input. Emit outputs unique to each
/// side — the symmetric difference. Outputs present in both are
/// suppressed. This is the "delta detection" primitive.
pub(all) struct TransducerDiff[A, B] {
  left : A
  right : B
  envelope : MetabolicEnvelope
} derive(Debug)

///|
pub fn[A, B] TransducerDiff::new(
  left : A,
  right : B,
  birth_tick : UInt,
) -> TransducerDiff[A, B] {
  { left, right, envelope: MetabolicEnvelope::new(birth_tick) }
}

///|
pub impl[A : Transducer, B : Transducer] Transducer for TransducerDiff[A, B] with transduce(
  self,
  input,
) {
  let (next_left, left_outputs) = self.left.transduce(input)
  let (next_right, right_outputs) = self.right.transduce(input)
  let left_keys = collect_cave_keys(left_outputs)
  let right_keys = collect_cave_keys(right_outputs)
  let result : Array[TransducerOutput] = []
  // Left-only outputs
  for out in left_outputs {
    let key = output_cave_key(out)
    if !set_contains(right_keys, key) {
      result.push(out)
    }
  }
  // Right-only outputs
  for out in right_outputs {
    let key = output_cave_key(out)
    if !set_contains(left_keys, key) {
      result.push(out)
    }
  }
  let envelope = self.envelope
    .tick(self.envelope.last_tick + 1U)
    .record_outputs(result.length().reinterpret_as_uint())
  ({ left: next_left, right: next_right, envelope }, result)
}

///|
pub impl[A : Transducer, B : Transducer] Transducer for TransducerDiff[A, B] with state_tag(
  self,
) {
  "diff(" + self.left.state_tag() + "," + self.right.state_tag() + ")"
}

///|
pub impl[A : Transducer, B : Transducer] Transducer for TransducerDiff[A, B] with accepting(
  self,
) {
  self.left.accepting() && self.right.accepting()
}

///|
pub impl[A : Transducer, B : Transducer] Transducer for TransducerDiff[A, B] with personality_name(
  _self,
) {
  "diff"
}

///|
/// Compose: T₁ ∘ T₂. Output of T₁ feeds input of T₂ through a bridge.
/// This is sequential transduction — the classic FST composition.
pub(all) struct TransducerCompose[A, B] {
  inner : A
  outer : B
  bridge : (TransducerOutput) -> TransducerInput?
  envelope : MetabolicEnvelope
}

///|
pub fn[A, B] TransducerCompose::new(
  inner : A,
  outer : B,
  bridge : (TransducerOutput) -> TransducerInput?,
  birth_tick : UInt,
) -> TransducerCompose[A, B] {
  { inner, outer, bridge, envelope: MetabolicEnvelope::new(birth_tick) }
}

///|
pub impl[A : Transducer, B : Transducer] Transducer for TransducerCompose[A, B] with transduce(
  self,
  input,
) {
  let (next_inner, inner_outputs) = self.inner.transduce(input)
  let mut cur_outer = self.outer
  let final_outputs : Array[TransducerOutput] = []
  for out in inner_outputs {
    match (self.bridge)(out) {
      Some(bridged_input) => {
        let (next_outer, outer_outputs) = cur_outer.transduce(bridged_input)
        cur_outer = next_outer
        for o in outer_outputs {
          final_outputs.push(o)
        }
      }
      None =>
        // Pass-through: outputs that don't bridge go directly to final tape
        final_outputs.push(out)
    }
  }
  let envelope = self.envelope
    .tick(self.envelope.last_tick + 1U)
    .record_outputs(final_outputs.length().reinterpret_as_uint())
  (
    { inner: next_inner, outer: cur_outer, bridge: self.bridge, envelope },
    final_outputs,
  )
}

///|
pub impl[A : Transducer, B : Transducer] Transducer for TransducerCompose[A, B] with state_tag(
  self,
) {
  "compose(" + self.inner.state_tag() + "," + self.outer.state_tag() + ")"
}

///|
pub impl[A : Transducer, B : Transducer] Transducer for TransducerCompose[A, B] with accepting(
  self,
) {
  self.outer.accepting()
}

///|
pub impl[A : Transducer, B : Transducer] Transducer for TransducerCompose[A, B] with personality_name(
  _self,
) {
  "compose"
}

///|
/// Extract cave entry key from an output (for set-algebraic matching).
fn output_cave_key(out : TransducerOutput) -> String {
  match out {
    CaveDeposit(e) => e.kind + ":" + e.key
    Signal(name, _) => "signal:" + name
    Emission(_) => "emission"
    Spawn(id, _) => "spawn:" + id
    Reap(id) => "reap:" + id
  }
}

///|
/// Collect cave keys from an output array for set membership testing.
fn collect_cave_keys(outputs : Array[TransducerOutput]) -> Array[String] {
  let keys : Array[String] = []
  for out in outputs {
    keys.push(output_cave_key(out))
  }
  keys
}

///|
/// Simple linear set membership test. For the small output arrays
/// typical of a single tick, this is faster than building a hash set.
fn set_contains(set : Array[String], needle : String) -> Bool {
  for item in set {
    if item == needle {
      return true
    }
  }
  false
}
