///|
/// Finite State Transducer input alphabet.
///
/// Each variant represents one class of input symbol that a
/// transducer can consume in a single tick. The alphabet is
/// closed — extension is by adding variants here — so composition
/// bridge functions can exhaustively match on output→input mappings.
pub(all) enum TransducerInput {
  /// Scalar field walk: (key, value).
  Scalar(String, String)
  /// Reporter submission: (source, kind, content).
  SubmitWork(Submission)
  /// Named event signal.
  Event(String)
  /// Metabolic clock pulse — the observer's heartbeat.
  Tick
  /// Opaque payload for extension.
  RawBytes(Bytes)
} derive(Debug)

///|
/// Finite State Transducer output alphabet.
///
/// Each variant represents one class of symbol emitted to the
/// output tape during a single transduction step. Outputs are
/// collected by the caller (or by a composed outer transducer).
pub(all) enum TransducerOutput {
  /// Primary output: a cave artifact produced by the transduction.
  CaveDeposit(CaveEntry)
  /// Named signal with payload — used for chore triggers.
  Signal(String, String)
  /// Wire-format output blob (e.g. stigmergy emission).
  Emission(String)
  /// Request to spawn a child FST with the given id and initial input.
  Spawn(String, TransducerInput)
  /// Request to reap (tombstone) a named FST.
  Reap(String)
} derive(Debug)

///|
/// Result of a single transduction step.
///
/// Bundles the new state tag, the output tape, and whether the
/// transducer has reached an accepting (terminal) state. This is
/// the return type for callers who interact with transducers
/// through opaque references rather than through the trait directly.
pub(all) struct TransduceResult {
  state_tag : String
  outputs : Array[TransducerOutput]
  accepting : Bool
} derive(Debug)

///|
/// Core Finite State Transducer contract.
///
/// Every FST in loci implements this trait. A transducer is a
/// Mealy machine: it maps (State × Input) → (State' × Output*).
///
/// The metabolic model: transducers only advance when ticked.
/// Between ticks they are frozen, serializable values living
/// inside the Merkle tree.
///
/// `transduce` is the atomic metabolic unit of work.
pub(open) trait Transducer {
  /// Feed one input symbol. Returns updated transducer + output emissions.
  transduce(Self, TransducerInput) -> (Self, Array[TransducerOutput])

  /// Current state tag for serialization / cave arcs.
  state_tag(Self) -> String

  /// Is this transducer in an accepting (terminal) state?
  accepting(Self) -> Bool

  /// Transducer personality name.
  personality_name(Self) -> String
}

///|
/// Extract cave entries deposited since `from_seq` as TransducerOutputs.
/// This is the bridge between the internal FsmCave accumulator and the
/// formal transducer output tape.
pub fn extract_cave_outputs(
  cave : FsmCave,
  from_seq : UInt,
) -> Array[TransducerOutput] {
  let outputs : Array[TransducerOutput] = []
  for e in cave.entries {
    if e.seq >= from_seq {
      outputs.push(CaveDeposit(e))
    }
  }
  outputs
}

///|
/// Convenience: run a sequence of inputs through a transducer,
/// collecting all outputs. This is the multi-symbol feed for
/// batch metabolization.
pub fn[T : Transducer] transduce_batch(
  fst : T,
  inputs : Array[TransducerInput],
) -> (T, Array[TransducerOutput]) {
  let mut cur = fst
  let all_outputs : Array[TransducerOutput] = []
  for input in inputs {
    let (next, step_outputs) = cur.transduce(input)
    cur = next
    for out in step_outputs {
      all_outputs.push(out)
    }
  }
  (cur, all_outputs)
}

///|
/// Convenience: transduce and return a TransduceResult (for callers
/// that don't need the updated transducer value).
pub fn[T : Transducer] transduce_to_result(
  fst : T,
  input : TransducerInput,
) -> (T, TransduceResult) {
  let (next, outputs) = fst.transduce(input)
  let result : TransduceResult = {
    state_tag: next.state_tag(),
    outputs,
    accepting: next.accepting(),
  }
  (next, result)
}
