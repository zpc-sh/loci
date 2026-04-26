///|
/// What class of hostile byte sequence was found.
///
/// Maps directly to the threat layer taxonomy in the adversary profile collection:
///   Bidi / Zwsp -> Layer 2 (unicode context poisoning)
///   Ansi        -> Layer 3 (terminal injection / execution)
///   MissingTrailingNewline -> Layer 4 (EOF boundary erasure)
pub(all) enum ScanKind {
  /// BiDi override/isolate/mark codepoints.
  /// UTF-8: U+202A–202E (LRE/RLE/PDF/LRO/RLO), U+2066–2069 (isolates),
  ///        U+200E/200F (LRM/RLM), U+061C (ALM).
  /// Steers AI context window, produces visual deception in code editors.
  Bidi
  /// Zero-width characters used as steganographic channel or to hide content.
  /// UTF-8: U+200B (ZWSP), U+200C (ZWNJ), U+FEFF when not at position 0 (mid-BOM).
  Zwsp
  /// ESC byte (0x1B) indicating a potential ANSI/OSC terminal escape sequence.
  /// Confirmed execution primitive: OSC 52 clipboard, OSC 8 hyperlink,
  /// OSC 133/1337 shell integration spoof, CSI cursor reposition.
  /// Fires on terminal render with no user action required.
  Ansi
  /// File does not end with a newline (0x0A).
  /// Causes adjacent file content to merge in AI context windows when files
  /// are read sequentially, erasing package/module scope boundaries silently.
  MissingTrailingNewline
} derive(Eq, Debug)

///|

///|
/// A single hostile byte sequence found by scan_bytes.
pub(all) struct ScanFinding {
  /// What class of hostile pattern this is.
  kind : ScanKind
  /// Byte offset of the first byte of the pattern within the input.
  offset : Int
  /// Up to 16 bytes of surrounding context (8 before, pattern, 8 after).
  context : Bytes
} derive(Debug)

///|
/// Scan raw bytes for all known hostile byte patterns.
/// Safe to call on any input including binary blobs — will simply find nothing
/// in random binary data (ANSI false positives aside).
pub fn scan_bytes(data : Bytes) -> Array[ScanFinding] {
  let findings : Array[ScanFinding] = []
  let len = data.length()
  let mut i = 0
  while i < len {
    let b = data[i].to_uint()
    if b == 0x1BU {
      // ESC — ANSI/OSC execution primitive
      findings.push(make_finding(ScanKind::Ansi, i, data))
      i = i + 1
      continue
    }
    if b == 0xD8U && i + 1 < len {
      // U+061C ARABIC LETTER MARK: D8 9C
      let b1 = data[i + 1].to_uint()
      if b1 == 0x9CU {
        findings.push(make_finding(ScanKind::Bidi, i, data))
        i = i + 2
        continue
      }
    }
    if b == 0xEFU && i + 2 < len {
      let b1 = data[i + 1].to_uint()
      let b2 = data[i + 2].to_uint()
      if b1 == 0xBBU && b2 == 0xBFU {
        // BOM: hostile if not at offset 0
        if i > 0 {
          findings.push(make_finding(ScanKind::Zwsp, i, data))
        }
        i = i + 3
        continue
      }
    }
    if b == 0xE2U && i + 2 < len {
      let b1 = data[i + 1].to_uint()
      let b2 = data[i + 2].to_uint()
      if b1 == 0x80U {
        // U+200B ZWSP: E2 80 8B
        // U+200C ZWNJ: E2 80 8C
        // U+200E LRM:  E2 80 8E  (Bidi)
        // U+200F RLM:  E2 80 8F  (Bidi)
        // U+202A LRE:  E2 80 AA  (Bidi)
        // U+202B RLE:  E2 80 AB  (Bidi)
        // U+202C PDF:  E2 80 AC  (Bidi)
        // U+202D LRO:  E2 80 AD  (Bidi)
        // U+202E RLO:  E2 80 AE  (Bidi) — Trojan Source classic
        if b2 == 0x8BU || b2 == 0x8CU {
          findings.push(make_finding(ScanKind::Zwsp, i, data))
          i = i + 3
          continue
        }
        if b2 == 0x8EU || b2 == 0x8FU {
          findings.push(make_finding(ScanKind::Bidi, i, data))
          i = i + 3
          continue
        }
        if b2 >= 0xAAU && b2 <= 0xAEU {
          findings.push(make_finding(ScanKind::Bidi, i, data))
          i = i + 3
          continue
        }
      }
      if b1 == 0x81U {
        // U+2066 LRI: E2 81 A6  (Bidi)
        // U+2067 RLI: E2 81 A7  (Bidi)
        // U+2068 FSI: E2 81 A8  (Bidi)
        // U+2069 PDI: E2 81 A9  (Bidi)
        if b2 >= 0xA6U && b2 <= 0xA9U {
          findings.push(make_finding(ScanKind::Bidi, i, data))
          i = i + 3
          continue
        }
      }
    }
    i = i + 1
  }
  // Missing trailing newline check (file-level, reported at last byte offset)
  if len > 0 && data[len - 1].to_uint() != 0x0AU {
    findings.push({
      kind: MissingTrailingNewline,
      offset: len - 1,
      context: context_window(data, len - 1),
    })
  }
  findings
}

///|
/// True if scan_bytes returns no findings.
pub fn is_clean(data : Bytes) -> Bool {
  scan_bytes(data).length() == 0
}

///|
/// Filter to only execution-class findings (Bidi, Zwsp, Ansi).
/// Excludes MissingTrailingNewline which is structural rather than active.
pub fn hostile_only(findings : Array[ScanFinding]) -> Array[ScanFinding] {
  let out : Array[ScanFinding] = []
  for f in findings {
    match f.kind {
      MissingTrailingNewline => ()
      _ => out.push(f)
    }
  }
  out
}

///|
/// True if any finding is Bidi, Zwsp, or Ansi (active hostile content).
pub fn has_hostile(findings : Array[ScanFinding]) -> Bool {
  for f in findings {
    match f.kind {
      MissingTrailingNewline => ()
      _ => return true
    }
  }
  false
}

///|
/// Count findings by kind.
pub fn count_by_kind(findings : Array[ScanFinding], kind : ScanKind) -> Int {
  let mut n = 0
  for f in findings {
    if f.kind == kind {
      n = n + 1
    }
  }
  n
}

// --- Internal helpers ---

///|
fn make_finding(kind : ScanKind, offset : Int, data : Bytes) -> ScanFinding {
  { kind, offset, context: context_window(data, offset) }
}

///|
/// Extract up to 16 bytes of context around an offset (8 before, 8 after).
fn context_window(data : Bytes, offset : Int) -> Bytes {
  let len = data.length()
  let start = if offset > 8 { offset - 8 } else { 0 }
  let end = if offset + 8 < len { offset + 8 } else { len }
  let size = end - start
  let buf = FixedArray::make(size, b'\x00')
  for i = 0; i < size; i = i + 1 {
    buf[i] = data[start + i]
  }
  Bytes::from_array(buf)
}
