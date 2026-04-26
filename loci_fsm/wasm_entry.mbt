///|
/// String-friendly entry helpers for callers that want to spawn many
/// reporters and bulk-collect their caves (e.g. a Haiku-class reader
/// scanning a repo). All functions are pure and self-enclosed: no
/// allocation of host handles, no global state. Each call instantiates
/// a fresh FSM, runs it, and returns a cave wire blob.
///
/// Submission CSV format (one per line):
///   "<source>|<kind>|<content>"
/// Pipes inside content must be escaped as "\|"; newlines as "\n".

///|
/// Run a Reporter end-to-end over a batch of submissions and return
/// its cave wire. This is the one-shot entry that minimises host calls.
pub fn reporter_run_wire(
  fsm_id : String,
  topic : String,
  submissions_csv : String,
) -> String {
  let mut reporter = ReporterFsm::new(fsm_id, topic)
  for sub in parse_submissions_csv(submissions_csv) {
    reporter = reporter.submit(sub)
  }
  reporter = reporter.drive_to_archive()
  reporter.cave.emit()
}

///|
/// Run a Reporter and return a compact summary instead of the full
/// cave (useful when the host only wants posture, not the artifacts).
pub fn reporter_summary_wire(
  fsm_id : String,
  topic : String,
  submissions_csv : String,
) -> String {
  let mut reporter = ReporterFsm::new(fsm_id, topic)
  for sub in parse_submissions_csv(submissions_csv) {
    reporter = reporter.submit(sub)
  }
  reporter = reporter.drive_to_archive()
  reporter.emit_summary()
}

///|
/// Run a BoundaryWalker over a CSV of `key=value` scalars and return
/// the stigmergy wire. Handy for hosts that already have field/value
/// pairs in flat form.
pub fn boundary_walk_wire(
  actor_overlay : String,
  ratio_loci : String,
  scalars_csv : String,
  note : String,
) -> String {
  let pairs = parse_scalar_csv(scalars_csv)
  let fsm = BoundaryWalkerFsm::new(actor_overlay, ratio_loci)
    .walk_scalars(pairs)
    .mark()
  fsm.emit_stigmergy(note~)
}

///|
/// Parse `"src|kind|content\nsrc|kind|content\n..."` into Submissions.
/// Accepts trailing newlines; ignores empty lines. `\|` -> `|`,
/// `\n` -> newline. Backslash before any other char is literal.
pub fn parse_submissions_csv(csv : String) -> Array[Submission] {
  let lines = split_unescaped_newlines(csv)
  let out : Array[Submission] = []
  for line in lines {
    if line == "" {
      continue
    }
    let fields = split_unescaped_pipes(line)
    if fields.length() < 3 {
      continue
    }
    out.push({
      source: fields[0],
      kind: fields[1],
      content: fields[2],
    })
  }
  out
}

///|
/// Parse `"k1=v1,k2=v2,..."` into pairs. Commas/equals inside values
/// are not supported (this is the same simple form the api wire uses).
pub fn parse_scalar_csv(csv : String) -> Array[(String, String)] {
  let out : Array[(String, String)] = []
  let buf = StringBuilder::new(size_hint=csv.length())
  let parts : Array[String] = []
  for ch in csv {
    if ch == ',' {
      parts.push(buf.to_string())
      buf.reset()
    } else {
      buf.write_char(ch)
    }
  }
  parts.push(buf.to_string())
  for part in parts {
    if part == "" {
      continue
    }
    let mut split_at = -1
    let mut idx = 0
    for ch in part {
      if ch == '=' && split_at < 0 {
        split_at = idx
      }
      idx = idx + 1
    }
    if split_at < 0 {
      out.push((part, ""))
    } else {
      let key = substring(part, 0, split_at)
      let value = substring(part, split_at + 1, part.length())
      out.push((key, value))
    }
  }
  out
}

///|
fn split_unescaped_newlines(s : String) -> Array[String] {
  let out : Array[String] = []
  let buf = StringBuilder::new(size_hint=s.length())
  let mut escape = false
  for ch in s {
    if escape {
      if ch == 'n' {
        buf.write_char('\n')
      } else if ch == '|' {
        buf.write_char('|')
      } else if ch == '\\' {
        buf.write_char('\\')
      } else {
        buf.write_char('\\')
        buf.write_char(ch)
      }
      escape = false
      continue
    }
    if ch == '\\' {
      escape = true
      continue
    }
    if ch == '\n' {
      out.push(buf.to_string())
      buf.reset()
    } else {
      buf.write_char(ch)
    }
  }
  out.push(buf.to_string())
  out
}

///|
fn split_unescaped_pipes(s : String) -> Array[String] {
  let out : Array[String] = []
  let buf = StringBuilder::new(size_hint=s.length())
  let mut escape = false
  for ch in s {
    if escape {
      if ch == '|' {
        buf.write_char('|')
      } else if ch == 'n' {
        buf.write_char('\n')
      } else if ch == '\\' {
        buf.write_char('\\')
      } else {
        buf.write_char('\\')
        buf.write_char(ch)
      }
      escape = false
      continue
    }
    if ch == '\\' {
      escape = true
      continue
    }
    if ch == '|' {
      out.push(buf.to_string())
      buf.reset()
    } else {
      buf.write_char(ch)
    }
  }
  out.push(buf.to_string())
  out
}

///|
fn substring(s : String, start : Int, end_excl : Int) -> String {
  let buf = StringBuilder::new(size_hint=end_excl - start)
  let mut idx = 0
  for ch in s {
    if idx >= start && idx < end_excl {
      buf.write_char(ch)
    }
    idx = idx + 1
  }
  buf.to_string()
}
