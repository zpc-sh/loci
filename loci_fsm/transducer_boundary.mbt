///|
/// Transducer implementation for BoundaryWalkerFsm.
///
/// The boundary walker is already an informal transducer — walk_scalar
/// takes (key, value) and produces state transitions + cave deposits.
/// This adapter formalizes the input/output contract so the walker
/// can participate in FST composition.
///
/// Recognized inputs:
///   Scalar(key, value)       → walk_scalar
///   Event("mark")            → mark
///   Event("emit_stigmergy")  → emit_stigmergy (produces Emission output)
///   Tick                     → cave tick (no state change)
///
/// The `cross` method is not routed through transduce because it
/// requires a trait-object credential. It remains a direct method.

///|
pub impl Transducer for BoundaryWalkerFsm with transduce(self, input) {
  let old_seq = self.cave.next_seq
  let (next, extra) = boundary_dispatch(self, input)
  let outputs = extract_cave_outputs(next.cave, old_seq)
  for out in extra {
    outputs.push(out)
  }
  (next, outputs)
}

///|
pub impl Transducer for BoundaryWalkerFsm with state_tag(self) {
  boundary_state_text(self.state)
}

///|
pub impl Transducer for BoundaryWalkerFsm with accepting(self) {
  match self.state {
    Emitted | Failed => true
    _ => false
  }
}

///|
pub impl Transducer for BoundaryWalkerFsm with personality_name(_self) {
  "boundary-walker"
}

///|
/// Dispatch a TransducerInput to the appropriate BoundaryWalkerFsm method.
/// Returns the updated walker plus any non-cave outputs (e.g. Emission).
fn boundary_dispatch(
  fsm : BoundaryWalkerFsm,
  input : TransducerInput,
) -> (BoundaryWalkerFsm, Array[TransducerOutput]) {
  match input {
    Scalar(key, value) => (fsm.walk_scalar(key, value), [])
    Event(tag) => boundary_dispatch_event(fsm, tag)
    Tick => {
      let cave = fsm.cave.tick()
      ({ ..fsm, cave, }, [])
    }
    _ => (fsm, [])
  }
}

///|
fn boundary_dispatch_event(
  fsm : BoundaryWalkerFsm,
  tag : String,
) -> (BoundaryWalkerFsm, Array[TransducerOutput]) {
  match tag {
    "mark" => (fsm.mark(), [])
    "emit_stigmergy" => {
      let wire = fsm.emit_stigmergy()
      (fsm, [Emission(wire)])
    }
    _ => (fsm, [])
  }
}
