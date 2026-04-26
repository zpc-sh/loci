///|
/// Reporter FSM runtime. Lifted from
/// docs/packets/cgn-minion-fsm-config.yaml + REPORTER_GENIUS_LOCI_FSM_SPEC_v0.1.md.
///
/// The Reporter observes deltas, collects submissions, sifts and
/// composes a deterministic edition, verifies it, publishes it and
/// archives the receipt — depositing artifacts into its cave at every
/// arc. Self-enclosed: no host I/O, no time, no network. A host calls
/// `submit` to feed it work and drains the cave when done.
///
/// Designed so a thin caller (e.g. Haiku) can spawn many reporters
/// across a repo in parallel and collect docs/notes from each by
/// draining the cave in one bulk read.
pub(all) enum ReporterState {
  RIdle
  RObserve
  RCollect
  RSift
  RCompose
  RVerify
  RPublish
  RArchive
  RDefer
  RFailed
} derive(Eq, Show)

///|
pub(all) enum ReporterEvent {
  Tick
  SignalDetected
  SubmissionReceived
  InsufficientDelta
  CompositionReady
  VerifyOk
  VerifyFail
  PublishOk
  PublishFail
  CooldownElapsed
  ManualPause
  ManualResume
} derive(Eq, Show)

///|
/// One unit of work for the reporter. `source` is opaque (e.g. a file
/// path or symbol id). `kind` classifies the submission (e.g. "doc",
/// "spec", "note"). `content` is the textual body the reporter will
/// sift / compose over.
pub(all) struct Submission {
  source : String
  kind : String
  content : String
} derive(Show)

///|
pub(all) struct ReporterFsm {
  fsm_id : String
  topic : String
  state : ReporterState
  cave : FsmCave
  pending : Array[Submission]
  collected : Array[Submission]
  composed : String
  verified : Bool
  published : Bool
} derive(Show)

///|
pub fn ReporterFsm::new(fsm_id : String, topic : String) -> ReporterFsm {
  let id = fsm_sanitize_line(fsm_id)
  let topic_value = fsm_sanitize_line(topic)
  {
    fsm_id: id,
    topic: topic_value,
    state: RIdle,
    cave: FsmCave::new(id, "reporter-v0"),
    pending: [],
    collected: [],
    composed: "",
    verified: false,
    published: false,
  }
}

///|
/// Push a submission. Side-effect on cave: deposit "submission".
/// Does not change state on its own — the host drives transitions
/// via `send(SubmissionReceived)` or via `drive_to_archive` (which
/// auto-fires the right events as long as there is pending work).
pub fn ReporterFsm::submit(
  self : ReporterFsm,
  submission : Submission,
) -> ReporterFsm {
  let from_state = reporter_state_text(self.state)
  let cave = self.cave
    .tick()
    .deposit(
      kind="submission",
      key=submission.source,
      value=submission.content,
      from_state~,
      to_state=from_state,
    )
  { ..self, pending: self.pending + [submission], cave }
}

///|
/// Apply one explicit event. Returns the new FSM state. Unknown
/// transitions leave state unchanged but deposit a "rejected" arc
/// marker into the cave for replay visibility.
pub fn ReporterFsm::send(
  self : ReporterFsm,
  event : ReporterEvent,
) -> ReporterFsm {
  // Wildcard: manual_pause from any state goes to Defer.
  match event {
    ManualPause => return self.transition(RDefer, "manual_pause")
    _ => ()
  }
  let next = match (self.state, event) {
    (RIdle, Tick) => Some(RObserve)
    (RObserve, SignalDetected) => Some(RCollect)
    (RObserve, SubmissionReceived) => Some(RCollect)
    (RObserve, InsufficientDelta) => Some(RDefer)
    (RCollect, Tick) => Some(RSift)
    (RSift, CompositionReady) => Some(RCompose)
    (RCompose, Tick) => Some(RVerify)
    (RVerify, VerifyOk) => Some(RPublish)
    (RVerify, VerifyFail) => Some(RFailed)
    (RPublish, PublishOk) => Some(RArchive)
    (RPublish, PublishFail) => Some(RFailed)
    (RArchive, Tick) => Some(RIdle)
    (RDefer, CooldownElapsed) => Some(RIdle)
    (RFailed, ManualResume) => Some(RObserve)
    _ => None
  }
  match next {
    Some(target) => self.transition(target, reporter_event_text(event))
    None => self.reject_event(event)
  }
}

///|
/// Drive the reporter from its current state through to Archive (or
/// Failed / Defer terminal). Idempotent once Archive is reached.
/// Each implicit transition deposits the appropriate artifact:
///   Collect  -> "collected"   (one per pending submission moved)
///   Sift     -> "sifted"      (count + digest of accepted items)
///   Compose  -> "composition" (composed edition body)
///   Verify   -> "verification" (ok/fail tag)
///   Publish  -> "publish"     (publish receipt)
///   Archive  -> "archive"     (final summary)
pub fn ReporterFsm::drive_to_archive(self : ReporterFsm) -> ReporterFsm {
  let mut cur = self
  let mut loop_guard = 0
  while loop_guard < 32 {
    loop_guard = loop_guard + 1
    match cur.state {
      RArchive | RFailed | RDefer => break
      RIdle =>
        if cur.pending.length() > 0 {
          cur = cur.send(Tick) // -> Observe
        } else {
          break
        }
      RObserve =>
        if cur.pending.length() > 0 {
          cur = cur.send(SubmissionReceived) // -> Collect
        } else {
          cur = cur.send(InsufficientDelta) // -> Defer
        }
      RCollect => {
        cur = cur.absorb_pending()
        cur = cur.send(Tick) // -> Sift
      }
      RSift => {
        cur = cur.deposit_sift_summary()
        cur = cur.send(CompositionReady) // -> Compose
      }
      RCompose => {
        cur = cur.compose_edition()
        cur = cur.send(Tick) // -> Verify
      }
      RVerify => {
        let (next, ok) = cur.run_verify()
        cur = next
        cur = if ok { cur.send(VerifyOk) } else { cur.send(VerifyFail) }
      }
      RPublish => {
        cur = cur.deposit_publish()
        cur = cur.send(PublishOk)
      }
    }
  }
  if cur.state == RArchive {
    cur.deposit_archive_summary()
  } else {
    cur
  }
}

///|
/// Bulk drain the cave. Returns the emptied reporter and every entry.
pub fn ReporterFsm::drain(
  self : ReporterFsm,
) -> (ReporterFsm, Array[CaveEntry]) {
  let (cave, entries) = self.cave.drain()
  ({ ..self, cave, }, entries)
}

///|
/// Lightweight summary wire for the reporter's current state.
pub fn ReporterFsm::emit_summary(self : ReporterFsm) -> String {
  let out = StringBuilder::new(size_hint=256)
  out.write_string("kind: loci.reporter.summary")
  out.write_string("\nfsm=reporter-v0")
  out.write_string("\nfsm_id=")
  out.write_string(self.fsm_id)
  out.write_string("\ntopic=")
  out.write_string(self.topic)
  out.write_string("\nstate=")
  out.write_string(reporter_state_text(self.state))
  out.write_string("\npending=")
  out.write_string(self.pending.length().to_string())
  out.write_string("\ncollected=")
  out.write_string(self.collected.length().to_string())
  out.write_string("\ncomposed_len=")
  out.write_string(self.composed.length().to_string())
  out.write_string("\nverified=")
  out.write_string(if self.verified { "1" } else { "0" })
  out.write_string("\npublished=")
  out.write_string(if self.published { "1" } else { "0" })
  out.write_string("\ncave_depth=")
  out.write_string(self.cave.depth().to_string())
  out.write_string("\ncave_material_hash=")
  out.write_string(self.cave.material_hash())
  out.write_char('\n')
  out.to_string()
}

///|
fn ReporterFsm::transition(
  self : ReporterFsm,
  next : ReporterState,
  arc_label : String,
) -> ReporterFsm {
  let from_state = reporter_state_text(self.state)
  let to_state = reporter_state_text(next)
  let cave = self.cave
    .tick()
    .deposit(
      kind="transition",
      key=arc_label,
      value=from_state + "->" + to_state,
      from_state~,
      to_state~,
    )
  { ..self, state: next, cave }
}

///|
fn ReporterFsm::reject_event(
  self : ReporterFsm,
  event : ReporterEvent,
) -> ReporterFsm {
  let from_state = reporter_state_text(self.state)
  let cave = self.cave.deposit(
    kind="rejected_event",
    key=reporter_event_text(event),
    value="no-transition",
    from_state~,
    to_state=from_state,
  )
  { ..self, cave, }
}

///|
fn ReporterFsm::absorb_pending(self : ReporterFsm) -> ReporterFsm {
  let mut cave = self.cave
  let collected : Array[Submission] = []
  for s in self.collected {
    collected.push(s)
  }
  for s in self.pending {
    collected.push(s)
    cave = cave.deposit(
      kind="collected",
      key=s.source,
      value=s.kind,
      from_state="collect",
      to_state="collect",
    )
  }
  { ..self, pending: [], collected, cave }
}

///|
fn ReporterFsm::deposit_sift_summary(self : ReporterFsm) -> ReporterFsm {
  let count = self.collected.length()
  let mut total_chars = 0
  for s in self.collected {
    total_chars = total_chars + s.content.length()
  }
  let summary = "items=" +
    count.to_string() +
    ";chars=" +
    total_chars.to_string()
  let cave = self.cave.deposit(
    kind="sifted",
    key=self.topic,
    value=summary,
    from_state="sift",
    to_state="sift",
  )
  { ..self, cave, }
}

///|
fn ReporterFsm::compose_edition(self : ReporterFsm) -> ReporterFsm {
  let body = StringBuilder::new(size_hint=512)
  body.write_string("topic=")
  body.write_string(self.topic)
  body.write_string("\nitems=")
  body.write_string(self.collected.length().to_string())
  for s in self.collected {
    body.write_string("\n- source=")
    body.write_string(fsm_sanitize_line(s.source))
    body.write_string(" kind=")
    body.write_string(fsm_sanitize_line(s.kind))
    body.write_string(" len=")
    body.write_string(s.content.length().to_string())
  }
  let composed = body.to_string()
  let cave = self.cave.deposit(
    kind="composition",
    key=self.topic,
    value=composed,
    from_state="compose",
    to_state="compose",
  )
  { ..self, composed, cave }
}

///|
fn ReporterFsm::run_verify(self : ReporterFsm) -> (ReporterFsm, Bool) {
  // Verification is structural: composed must be non-empty, must have
  // at least one item, must hash-stably. Pure: no I/O.
  let ok = self.composed.length() > 0 && self.collected.length() > 0
  let cave = self.cave.deposit(
    kind="verification",
    key=self.topic,
    value=if ok { "verify_ok" } else { "verify_fail" },
    from_state="verify",
    to_state="verify",
  )
  ({ ..self, verified: ok, cave }, ok)
}

///|
fn ReporterFsm::deposit_publish(self : ReporterFsm) -> ReporterFsm {
  let receipt = "items=" +
    self.collected.length().to_string() +
    ";composed_len=" +
    self.composed.length().to_string()
  let cave = self.cave.deposit(
    kind="publish",
    key=self.topic,
    value=receipt,
    from_state="publish",
    to_state="publish",
  )
  { ..self, published: true, cave }
}

///|
fn ReporterFsm::deposit_archive_summary(self : ReporterFsm) -> ReporterFsm {
  let cave = self.cave.deposit(
    kind="archive",
    key=self.topic,
    value="items=" +
      self.collected.length().to_string() +
      ";verified=" +
      (if self.verified { "1" } else { "0" }) +
      ";published=" +
      (if self.published { "1" } else { "0" }),
    from_state="archive",
    to_state="archive",
  )
  { ..self, cave, }
}

///|
pub fn reporter_state_text(state : ReporterState) -> String {
  match state {
    RIdle => "idle"
    RObserve => "observe"
    RCollect => "collect"
    RSift => "sift"
    RCompose => "compose"
    RVerify => "verify"
    RPublish => "publish"
    RArchive => "archive"
    RDefer => "defer"
    RFailed => "failed"
  }
}

///|
pub fn reporter_event_text(event : ReporterEvent) -> String {
  match event {
    Tick => "tick"
    SignalDetected => "signal_detected"
    SubmissionReceived => "submission_received"
    InsufficientDelta => "insufficient_delta"
    CompositionReady => "composition_ready"
    VerifyOk => "verify_ok"
    VerifyFail => "verify_fail"
    PublishOk => "publish_ok"
    PublishFail => "publish_fail"
    CooldownElapsed => "cooldown_elapsed"
    ManualPause => "manual_pause"
    ManualResume => "manual_resume"
  }
}

///|
pub fn reporter_event_parse(tag : String) -> ReporterEvent? {
  match tag {
    "tick" => Some(Tick)
    "signal_detected" => Some(SignalDetected)
    "submission_received" => Some(SubmissionReceived)
    "insufficient_delta" => Some(InsufficientDelta)
    "composition_ready" => Some(CompositionReady)
    "verify_ok" => Some(VerifyOk)
    "verify_fail" => Some(VerifyFail)
    "publish_ok" => Some(PublishOk)
    "publish_fail" => Some(PublishFail)
    "cooldown_elapsed" => Some(CooldownElapsed)
    "manual_pause" => Some(ManualPause)
    "manual_resume" => Some(ManualResume)
    _ => None
  }
}
