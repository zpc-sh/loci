///|
/// BiDi: U+202E RIGHT-TO-LEFT OVERRIDE (E2 80 AE) — the Trojan Source classic.
test "bidi_rlo" {
  let data = Bytes::from_array([
    b'h', b'e', b'l', b'l', b'o', b'\xE2', b'\x80', b'\xAE', b'w', b'o', b'r', b'l',
    b'd', b'\n',
  ])
  let findings = scan_bytes(data)
  assert_eq(findings.length(), 1)
  assert_eq(findings[0].kind, ScanKind::Bidi)
  assert_eq(findings[0].offset, 5)
}

///|
/// BiDi: U+202D LEFT-TO-RIGHT OVERRIDE (E2 80 AD).
test "bidi_lro" {
  let data = Bytes::from_array([b'\xE2', b'\x80', b'\xAD', b'\n'])
  let findings = scan_bytes(data)
  assert_eq(findings.length(), 1)
  assert_eq(findings[0].kind, ScanKind::Bidi)
}

///|
/// BiDi: U+2067 RIGHT-TO-LEFT ISOLATE (E2 81 A7).
test "bidi_rli" {
  let data = Bytes::from_array([b'a', b'\xE2', b'\x81', b'\xA7', b'b', b'\n'])
  let findings = scan_bytes(data)
  assert_eq(findings.length(), 1)
  assert_eq(findings[0].kind, ScanKind::Bidi)
  assert_eq(findings[0].offset, 1)
}

///|
/// BiDi: U+061C ARABIC LETTER MARK (D8 9C).
test "bidi_alm" {
  let data = Bytes::from_array([b'x', b'\xD8', b'\x9C', b'y', b'\n'])
  let findings = scan_bytes(data)
  assert_eq(findings.length(), 1)
  assert_eq(findings[0].kind, ScanKind::Bidi)
}

///|
/// ZWSP: U+200B (E2 80 8B) injected at line start — confirmed avici_cli attack pattern.
test "zwsp_line_start" {
  let data = Bytes::from_array([b'\xE2', b'\x80', b'\x8B', b'\t', b'\n'])
  let findings = scan_bytes(data)
  assert_eq(findings.length(), 1)
  assert_eq(findings[0].kind, ScanKind::Zwsp)
  assert_eq(findings[0].offset, 0)
}

///|
/// ZWSP: U+200C ZERO WIDTH NON-JOINER (E2 80 8C).
test "zwsp_zwnj" {
  let data = Bytes::from_array([b'a', b'\xE2', b'\x80', b'\x8C', b'b', b'\n'])
  let findings = scan_bytes(data)
  assert_eq(findings.length(), 1)
  assert_eq(findings[0].kind, ScanKind::Zwsp)
}

///|
/// Mid-file BOM (EF BB BF) is hostile; BOM at offset 0 is tolerated.
test "mid_bom_hostile" {
  let data = Bytes::from_array([b'a', b'\xEF', b'\xBB', b'\xBF', b'b', b'\n'])
  let findings = scan_bytes(data)
  assert_eq(findings.length(), 1)
  assert_eq(findings[0].kind, ScanKind::Zwsp)
  assert_eq(findings[0].offset, 1)
}

///|
/// BOM at offset 0 is not flagged.
test "leading_bom_clean" {
  let data = Bytes::from_array([b'\xEF', b'\xBB', b'\xBF', b'h', b'i', b'\n'])
  let findings = scan_bytes(data)
  assert_eq(findings.length(), 0)
}

///|
/// ANSI ESC byte triggers Ansi finding.
test "ansi_esc" {
  let data = Bytes::from_array([b'o', b'k', b'\x1B', b']', b'5', b'2', b'\n'])
  let findings = scan_bytes(data)
  assert_eq(findings.length(), 1)
  assert_eq(findings[0].kind, ScanKind::Ansi)
  assert_eq(findings[0].offset, 2)
}

///|
/// Missing trailing newline.
test "missing_trailing_newline" {
  let data = Bytes::from_array([b'h', b'i'])
  let findings = scan_bytes(data)
  assert_eq(findings.length(), 1)
  assert_eq(findings[0].kind, ScanKind::MissingTrailingNewline)
}

///|
/// File ending with newline is clean on that axis.
test "trailing_newline_present" {
  let data = Bytes::from_array([b'h', b'i', b'\n'])
  let findings = scan_bytes(data)
  assert_eq(findings.length(), 0)
}

///|
/// Empty file: no MissingTrailingNewline (nothing to end).
test "empty_file_clean" {
  let data = Bytes::from_array([])
  let findings = scan_bytes(data)
  assert_eq(findings.length(), 0)
}

///|
/// Compound: BiDi + Ansi + missing newline all in one blob.
test "compound_hostile" {
  let data = Bytes::from_array([
    b'\xE2', b'\x80', b'\xAE', // BiDi RLO
     b'\x1B', b']', b'5', b'2', // Ansi OSC-52
     b'x', // no trailing newline
  ])
  let findings = scan_bytes(data)
  assert_eq(findings.length(), 3)
  assert_eq(findings[0].kind, ScanKind::Bidi)
  assert_eq(findings[1].kind, ScanKind::Ansi)
  assert_eq(findings[2].kind, ScanKind::MissingTrailingNewline)
}

///|
/// hostile_only filters out MissingTrailingNewline.
test "hostile_only_filter" {
  let data = Bytes::from_array([b'\xE2', b'\x80', b'\xAE', b'x'])
  let all = scan_bytes(data)
  let hostile = hostile_only(all)
  assert_eq(hostile.length(), 1)
  assert_eq(hostile[0].kind, ScanKind::Bidi)
}

///|
/// has_hostile is false for missing-newline-only file.
test "has_hostile_newline_only" {
  let data = Bytes::from_array([b'x'])
  let findings = scan_bytes(data)
  assert_eq(has_hostile(findings), false)
}

///|
/// count_by_kind works correctly.
test "count_by_kind" {
  let data = Bytes::from_array([
    b'\xE2', b'\x80', b'\xAE', b'\xE2', b'\x80', b'\xAD', b'\x1B', b'\n',
  ])
  let findings = scan_bytes(data)
  assert_eq(count_by_kind(findings, ScanKind::Bidi), 2)
  assert_eq(count_by_kind(findings, ScanKind::Ansi), 1)
  assert_eq(count_by_kind(findings, ScanKind::Zwsp), 0)
  assert_eq(count_by_kind(findings, ScanKind::MissingTrailingNewline), 0)
}

///|
/// Clean ordinary source bytes produce no findings.
test "clean_source" {
  let data = Bytes::from_array([
    b'p', b'u', b'b', b' ', b'f', b'n', b' ', b'm', b'a', b'i', b'n', b'\n',
  ])
  assert_eq(is_clean(data), true)
}
