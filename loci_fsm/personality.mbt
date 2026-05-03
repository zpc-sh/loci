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
pub fn union_personality() -> Personality {
  {
    name: "union",
    version: "v0",
    description: "Parallel union transducer: feeds input to both children, merges output tapes. The swarm primitive.",
    states: ["union(left,right)"],
    events: ["transduce"],
    cave_kinds: ["merged"],
    initial_state: "union(idle,idle)",
    terminal_states: [],
  }
}

///|
pub fn subtract_personality() -> Personality {
  {
    name: "subtract",
    version: "v0",
    description: "Filter transducer: primary outputs minus filter-matching outputs. The fencing primitive.",
    states: ["subtract(primary,filter)"],
    events: ["transduce"],
    cave_kinds: ["filtered"],
    initial_state: "subtract(idle,idle)",
    terminal_states: [],
  }
}

///|
pub fn diff_personality() -> Personality {
  {
    name: "diff",
    version: "v0",
    description: "Symmetric difference transducer: emits outputs unique to each side. The delta detection primitive.",
    states: ["diff(left,right)"],
    events: ["transduce"],
    cave_kinds: ["delta"],
    initial_state: "diff(idle,idle)",
    terminal_states: [],
  }
}

///|
pub fn compose_personality() -> Personality {
  {
    name: "compose",
    version: "v0",
    description: "Sequential composition transducer: inner output feeds outer input through a bridge function. Classic FST composition T₁ ∘ T₂.",
    states: ["compose(inner,outer)"],
    events: ["transduce"],
    cave_kinds: ["bridged"],
    initial_state: "compose(idle,idle)",
    terminal_states: [],
  }
}

///|
pub fn personality_registry() -> Array[Personality] {
  [
    boundary_walker_personality(),
    reporter_personality(),
    union_personality(),
    subtract_personality(),
    diff_personality(),
    compose_personality(),
  ]
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
