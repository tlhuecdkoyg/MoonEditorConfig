///|
fn trim_owned(value : String) -> String {
  value.trim().to_owned()
}

///|
fn lower_ascii(value : String) -> String {
  value.to_lower()
}

///|
fn is_space_code(code : UInt16) -> Bool {
  code == ' ' || code == '\t' || code == '\r'
}

///|
fn first_non_space(value : String) -> Int {
  for index in 0..<value.length() {
    if !is_space_code(value[index]) {
      return index
    }
  }
  value.length()
}

///|
fn last_non_space_end(value : String) -> Int {
  for index = value.length(); index > 0; index = index - 1 {
    if !is_space_code(value[index - 1]) {
      return index
    }
  }
  0
}

///|
fn strip_utf8_bom(value : String, first_line : Bool) -> String {
  if first_line && value.get_char(0) is Some('\u{FEFF}') {
    value[1:].to_owned()
  } else {
    value
  }
}

///|
fn find_unescaped_separator(value : String, allow_colon : Bool) -> Int? {
  let mut escaped = false
  for index in 0..<value.length() {
    let code = value[index]
    if escaped {
      escaped = false
    } else if code == '\\' {
      escaped = true
    } else if code == '=' || (allow_colon && code == ':') {
      return Some(index)
    }
  }
  None
}

///|
fn unescape_assignment(value : String) -> String {
  let buffer = StringBuilder::new()
  let mut escaped = false
  for ch in value {
    if escaped {
      if ch == '=' || ch == ':' || ch == '\\' {
        buffer.write_char(ch)
      } else {
        buffer.write_char('\\')
        buffer.write_char(ch)
      }
      escaped = false
    } else if ch == '\\' {
      escaped = true
    } else {
      buffer.write_char(ch)
    }
  }
  if escaped {
    buffer.write_char('\\')
  }
  buffer.to_string()
}

///|
fn json_escape(value : String) -> String {
  let buffer = StringBuilder::new()
  for ch in value {
    match ch {
      '"' => buffer.write_string("\\\"")
      '\\' => buffer.write_string("\\\\")
      '\n' => buffer.write_string("\\n")
      '\r' => buffer.write_string("\\r")
      '\t' => buffer.write_string("\\t")
      _ => buffer.write_char(ch)
    }
  }
  buffer.to_string()
}

///|
fn bool_text(value : Bool) -> String {
  if value {
    "true"
  } else {
    "false"
  }
}
