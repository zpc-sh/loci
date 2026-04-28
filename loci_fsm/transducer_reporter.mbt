///|
/// Transducer implementation for ReporterFsm.
///
/// The reporter is a rich stateful transducer: submissions flow in,
/// a deterministic edition flows out through sift/compose/verify/
/// publish/archive. This adapter maps the Transducer trait onto
/// the existing ReporterFsm methods.
///
/// Recognized inputs:
///   SubmitWork(submission)      → submit
///   Event(name)                → parsed to ReporterEvent, then send
///   Event("drive_to_archive")  → drive_to_archive (compound operation)
///   Tick                       → send(Tick)

///|
pub impl Transducer for ReporterFsm with transduce(self, input) {
  let old_seq = self.cave.next_seq
  let (next, extra) = reporter_dispatch(self, input)
  let outputs = extract_cave_outputs(next.cave, old_seq)
  for out in extra {
    outputs.push(out)
  }
  (next, outputs)
}

///|
pub impl Transducer for ReporterFsm with state_tag(self) {
  reporter_state_text(self.state)
}

///|
pub impl Transducer for ReporterFsm with accepting(self) {
  match self.state {
    RArchive | RFailed => true
    _ => false
  }
}

///|
pub impl Transducer for ReporterFsm with personality_name(_self) {
  "reporter"
}

///|
/// Dispatch a TransducerInput to the appropriate ReporterFsm method.
/// Returns the updated reporter plus any non-cave outputs.
fn reporter_dispatch(
  fsm : ReporterFsm,
  input : TransducerInput,
) -> (ReporterFsm, Array[TransducerOutput]) {
  match input {
    SubmitWork(sub) => (fsm.submit(sub), [])
    Event(tag) => reporter_dispatch_event(fsm, tag)
    Tick => (fsm.send(ReporterEvent::Tick), [])
    _ => (fsm, [])
  }
}

///|
fn reporter_dispatch_event(
  fsm : ReporterFsm,
  tag : String,
) -> (ReporterFsm, Array[TransducerOutput]) {
  if tag == "drive_to_archive" {
    let next = fsm.drive_to_archive()
    let wire = next.emit_summary()
    return (next, [Emission(wire)])
  }
  if tag == "emit_summary" {
    let wire = fsm.emit_summary()
    return (fsm, [Emission(wire)])
  }
  match reporter_event_parse(tag) {
    Some(ev) => (fsm.send(ev), [])
    None => (fsm, [])
  }
}
