///|
/// FsmCave is the small writable cave attached to a single FSM.
///
/// Conceptually each FSM is a continuous unit of work that ticks across
/// the host store. As it moves through states it deposits artifacts into
/// its cave. Consumers (e.g. a Haiku-class reader) drain the cave in one
/// bulk read instead of polling FSM internals — this is the
/// "movement-based execution" surface.
///
/// Properties:
///   * Append-only (no in-place edits, replay-stable).
///   * Each entry carries a monotonic seq + tick + transition arc, so
///     incremental polling with `since(seq)` is safe.
///   * `drain` returns + clears: optimal for one-shot bulk reads.
///   * `material_hash` fingerprints the whole cave for verification.
pub(all) struct CaveEntry {
  seq : UInt
  tick : UInt
  from_state : String
  to_state : String
  kind : String
  key : String
  value : String
  hash : String
} derive(Eq, Show)

///|
pub(all) struct FsmCave {
  fsm_id : String
  personality : String
  entries : Array[CaveEntry]
  next_seq : UInt
  current_tick : UInt
} derive(Show)

///|
pub fn FsmCave::new(fsm_id : String, personality : String) -> FsmCave {
  {
    fsm_id: cave_sanitize(fsm_id),
    personality: cave_sanitize(personality),
    entries: [],
    next_seq: 0U,
    current_tick: 0U,
  }
}

///|
/// Bump the FSM's tick counter without depositing.
pub fn FsmCave::tick(self : FsmCave) -> FsmCave {
  { ..self, current_tick: self.current_tick + 1U }
}

///|
/// Deposit one entry. The from/to states record the transition arc
/// the FSM was on when it wrote the entry. Pass the same value for
/// both when the deposit happens inside a stable state.
pub fn FsmCave::deposit(
  self : FsmCave,
  kind~ : String,
  key~ : String,
  value~ : String,
  from_state~ : String = "",
  to_state~ : String = "",
) -> FsmCave {
  let value_hash = cave_value_hash(value)
  let entry : CaveEntry = {
    seq: self.next_seq,
    tick: self.current_tick,
    from_state: cave_sanitize(from_state),
    to_state: cave_sanitize(to_state),
    kind: cave_sanitize(kind),
    key: cave_sanitize(key),
    value,
    hash: value_hash,
  }
  { ..self, entries: self.entries + [entry], next_seq: self.next_seq + 1U }
}

///|
/// Non-destructive read of every entry currently in the cave.
pub fn FsmCave::snapshot(self : FsmCave) -> Array[CaveEntry] {
  let copy : Array[CaveEntry] = []
  for e in self.entries {
    copy.push(e)
  }
  copy
}

///|
/// Bulk drain: return every entry and reset the cave to empty. The
/// returned cave keeps the next_seq counter so subsequent deposits
/// remain monotonic across drains. Optimised for one-shot collection
/// by an external reader.
pub fn FsmCave::drain(self : FsmCave) -> (FsmCave, Array[CaveEntry]) {
  let drained = self.snapshot()
  ({ ..self, entries: [] }, drained)
}

///|
/// Filter snapshot by entry kind (e.g. "doc", "finding", "stigmergy").
pub fn FsmCave::collect(self : FsmCave, kind : String) -> Array[CaveEntry] {
  let needle = cave_sanitize(kind)
  let out : Array[CaveEntry] = []
  for e in self.entries {
    if e.kind == needle {
      out.push(e)
    }
  }
  out
}

///|
/// Return entries whose seq is strictly greater than `after_seq`.
/// Lets a reader cursor through the cave without re-reading old work.
pub fn FsmCave::since(self : FsmCave, after_seq : UInt) -> Array[CaveEntry] {
  let out : Array[CaveEntry] = []
  for e in self.entries {
    if e.seq > after_seq {
      out.push(e)
    }
  }
  out
}

///|
pub fn FsmCave::depth(self : FsmCave) -> UInt {
  self.entries.length().to_uint()
}

///|
/// Deterministic fingerprint over every entry in the cave. Stable
/// under ordering since deposits are append-only and seq-numbered.
pub fn FsmCave::material_hash(self : FsmCave) -> String {
  let buf = StringBuilder::new(size_hint=64 + self.entries.length() * 96)
  buf.write_string(self.fsm_id)
  buf.write_char('|')
  buf.write_string(self.personality)
  for e in self.entries {
    buf.write_char('|')
    buf.write_string(e.seq.to_string())
    buf.write_char(':')
    buf.write_string(e.kind)
    buf.write_char(':')
    buf.write_string(e.hash)
  }
  @hash.Hash::of_bytes(cave_string_to_bytes(buf.to_string())).key()
}

///|
/// Serialise the whole cave as a wire blob. Newline-delimited
/// key=value form, compatible with the existing stigmergy wire style.
pub fn FsmCave::emit(self : FsmCave) -> String {
  let out = StringBuilder::new(size_hint=256 + self.entries.length() * 128)
  out.write_string("kind: loci.fsm.cave")
  out.write_string("\nfsm_id=")
  out.write_string(self.fsm_id)
  out.write_string("\npersonality=")
  out.write_string(self.personality)
  out.write_string("\ncurrent_tick=")
  out.write_string(self.current_tick.to_string())
  out.write_string("\ndepth=")
  out.write_string(self.depth().to_string())
  out.write_string("\nnext_seq=")
  out.write_string(self.next_seq.to_string())
  for e in self.entries {
    out.write_string("\n- entry seq=")
    out.write_string(e.seq.to_string())
    out.write_string(" tick=")
    out.write_string(e.tick.to_string())
    out.write_string(" arc=")
    out.write_string(e.from_state)
    out.write_string("->")
    out.write_string(e.to_state)
    out.write_string(" kind=")
    out.write_string(e.kind)
    out.write_string(" key=")
    out.write_string(e.key)
    out.write_string(" hash=")
    out.write_string(e.hash)
  }
  let prefix = out.to_string()
  let mat = @hash.Hash::of_bytes(cave_string_to_bytes(prefix)).key()
  let final = StringBuilder::new(size_hint=prefix.length() + 96)
  final.write_string(prefix)
  final.write_string("\nmaterial_hash=")
  final.write_string(mat)
  final.write_char('\n')
  final.to_string()
}

///|
fn cave_value_hash(value : String) -> String {
  @hash.Hash::of_bytes(cave_string_to_bytes(value)).key()
}

///|
fn cave_sanitize(value : String) -> String {
  let out = StringBuilder::new(size_hint=value.length())
  for ch in value {
    if ch == '\n' || ch == '\r' {
      out.write_char('_')
    } else {
      out.write_char(ch)
    }
  }
  let s = out.to_string()
  if s == "" {
    "none"
  } else {
    s
  }
}

///|
fn cave_string_to_bytes(s : String) -> Bytes {
  let total = s.length() * 4
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
