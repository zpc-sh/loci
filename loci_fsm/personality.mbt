///|
/// Personality registry. Each personality is a static description of an
/// FSM persona — its identity, the states it occupies, the events it
/// understands, and the cave kinds it deposits. The registry is the
/// catalog Haiku-class callers consult before spawning instances.
///
/// New personalities are added here as `Personality::new(...)` entries.
pub(all) struct Personality {
  name : String
  version : String
  description : String
  states : Array[String]
  events : Array[String]
  cave_kinds : Array[String]
  initial_state : String
  terminal_states : Array[String]
} derive(Debug)

///|
pub fn boundary_walker_personality() -> Personality {
  {
    name: "boundary-walker",
    version: "v0",
    description: "Membrane-side FSM: walks scalars for ghost/bidi/control bytes, evaluates Crosser credentials, emits stigmergy posture into its cave.",
    states: ["idle", "walking", "crossing", "marked", "emitted", "failed"],
    events: ["walk_scalar", "cross", "mark", "emit_stigmergy"],
    cave_kinds: ["walk", "finding", "crossing", "transition"],
    initial_state: "idle",
    terminal_states: ["emitted", "failed"],
  }
}

///|
pub fn reporter_personality() -> Personality {
  {
    name: "reporter",
    version: "v0",
    description: "Observation FSM: sifts submissions into a deterministic edition, verifies, publishes, archives. Self-enclosed — no host I/O.",
    states: [
      "idle", "observe", "collect", "sift", "compose", "verify", "publish", "archive",
      "defer", "failed",
    ],
    events: [
      "tick", "signal_detected", "submission_received", "insufficient_delta", "composition_ready",
      "verify_ok", "verify_fail", "publish_ok", "publish_fail", "cooldown_elapsed",
      "manual_pause", "manual_resume",
    ],
    cave_kinds: [
      "submission", "collected", "sifted", "composition", "verification", "publish",
      "archive", "transition", "rejected_event",
    ],
    initial_state: "idle",
    terminal_states: ["archive", "failed"],
  }
}

///|
pub fn personality_registry() -> Array[Personality] {
  [boundary_walker_personality(), reporter_personality()]
}

///|
pub fn personality_by_name(name : String) -> Personality? {
  for p in personality_registry() {
    if p.name == name {
      return Some(p)
    }
  }
  None
}
