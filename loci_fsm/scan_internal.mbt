///|
/// Internal scalar scanner. Same shape as the original boundary_fsm
/// scanner but lives inside loci-fsm so the package is self-contained.
priv struct ScalarScan {
  canonical : String
  raw_hex : String
  ghost_u200b : UInt
  ghost_u200c : UInt
  ghost_ufeff : UInt
  bidi_controls : UInt
  ascii_controls : UInt
  suspicious : Bool
  sanitized : Bool
}

///|
fn scan_scalar(value : String) -> ScalarScan {
  let canonical = StringBuilder::new(size_hint=value.length())
  let mut ghost_u200b = 0U
  let mut ghost_u200c = 0U
  let mut ghost_ufeff = 0U
  let mut bidi_controls = 0U
  let mut ascii_controls = 0U
  for ch in value {
    let code = ch.to_uint().reinterpret_as_int()
    if code == 0x200B {
      ghost_u200b = ghost_u200b + 1U
      continue
    }
    if code == 0x200C {
      ghost_u200c = ghost_u200c + 1U
      continue
    }
    if code == 0xFEFF {
      ghost_ufeff = ghost_ufeff + 1U
      continue
    }
    if is_bidi_control(code) {
      bidi_controls = bidi_controls + 1U
      continue
    }
    if is_ascii_control(code) {
      ascii_controls = ascii_controls + 1U
      continue
    }
    if ch == '\n' || ch == '\r' {
      canonical.write_char('_')
    } else if ch == ',' {
      canonical.write_char(';')
    } else {
      canonical.write_char(ch)
    }
  }
  let canonical_value = canonical.to_string()
  let sanitized = canonical_value != value
  let suspicious = ghost_u200b > 0U ||
    ghost_u200c > 0U ||
    ghost_ufeff > 0U ||
    bidi_controls > 0U ||
    ascii_controls > 0U
  {
    canonical: if canonical_value == "" {
      "none"
    } else {
      canonical_value
    },
    raw_hex: scalar_hex(value),
    ghost_u200b,
    ghost_u200c,
    ghost_ufeff,
    bidi_controls,
    ascii_controls,
    suspicious,
    sanitized,
  }
}

///|
fn is_ascii_control(code : Int) -> Bool {
  (code >= 0 && code < 32 && code != 9 && code != 10 && code != 13) ||
  code == 127
}

///|
fn is_bidi_control(code : Int) -> Bool {
  code == 0x202A ||
  code == 0x202B ||
  code == 0x202D ||
  code == 0x202E ||
  code == 0x202C ||
  code == 0x2066 ||
  code == 0x2067 ||
  code == 0x2068 ||
  code == 0x2069
}

///|
fn scalar_hex(value : String) -> String {
  let out = StringBuilder::new(size_hint=value.length() * 8)
  for ch in value {
    let code = ch.to_uint().reinterpret_as_int()
    out.write_char(int_to_hex((code >> 28) & 0xF))
    out.write_char(int_to_hex((code >> 24) & 0xF))
    out.write_char(int_to_hex((code >> 20) & 0xF))
    out.write_char(int_to_hex((code >> 16) & 0xF))
    out.write_char(int_to_hex((code >> 12) & 0xF))
    out.write_char(int_to_hex((code >> 8) & 0xF))
    out.write_char(int_to_hex((code >> 4) & 0xF))
    out.write_char(int_to_hex(code & 0xF))
  }
  let hex = out.to_string()
  if hex == "" {
    "none"
  } else {
    hex
  }
}

///|
fn int_to_hex(n : Int) -> Char {
  if n < 10 {
    (48 + n).unsafe_to_char()
  } else {
    (87 + n).unsafe_to_char()
  }
}

///|
fn fsm_sanitize_line(value : String) -> String {
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
fn fsm_string_to_bytes(s : String) -> Bytes {
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
