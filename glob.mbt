///|
pub(all) enum GlobToken {
  Literal(UInt16)
  Separator
  AnyCharacter
  AnySegment
  AnyPath
  CharacterClass(
    chars~ : Array[UInt16],
    ranges~ : Array[(UInt16, UInt16)],
    negated~ : Bool
  )
} derive(Debug, Eq)

///|
pub(all) struct GlobProgram {
  source : String
  alternatives : Array[Array[GlobToken]]
  diagnostics : Array[String]
} derive(Debug, Eq)

///|
fn find_closing_brace(pattern : String, start : Int) -> Int? {
  let mut escaped = false
  for index in start..<pattern.length() {
    let code = pattern[index]
    if escaped {
      escaped = false
    } else if code == '\\' {
      escaped = true
    } else if code == '}' {
      return Some(index)
    }
  }
  None
}

///|
fn split_brace_items(content : String) -> Array[String] {
  let items : Array[String] = []
  let mut start = 0
  let mut escaped = false
  for index in 0..<content.length() {
    let code = content[index]
    if escaped {
      escaped = false
    } else if code == '\\' {
      escaped = true
    } else if code == ',' {
      items.push(content[start:index].to_owned())
      start = index + 1
    }
  }
  items.push(content[start:].to_owned())
  items
}

///|
fn parse_decimal(value : String) -> Int? {
  if value == "" {
    return None
  }
  let mut sign = 1
  let mut index = 0
  if value[0] == '-' {
    sign = -1
    index = 1
  }
  if index == value.length() {
    return None
  }
  let mut result = 0
  while index < value.length() {
    let code = value[index]
    if code < '0' || code > '9' {
      return None
    }
    result = result * 10 + code.to_int() - ('0' : UInt16).to_int()
    index += 1
  }
  Some(result * sign)
}

///|
fn expand_numeric_range(content : String) -> Array[String]? {
  match content.find("..") {
    None => None
    Some(separator) => {
      guard parse_decimal(content[:separator].to_owned()) is Some(start) else {
        return None
      }
      guard parse_decimal(content[separator + 2:].to_owned()) is Some(finish) else {
        return None
      }
      if (start - finish).abs() > 1000 {
        return None
      }
      let values : Array[String] = []
      if start <= finish {
        for value in start..<=finish {
          values.push(value.to_string())
        }
      } else {
        for value in start>=..finish {
          values.push(value.to_string())
        }
      }
      Some(values)
    }
  }
}

///|
fn expand_braces_once(pattern : String) -> Array[String]? {
  let mut escaped = false
  for index in 0..<pattern.length() {
    let code = pattern[index]
    if escaped {
      escaped = false
      continue
    }
    if code == '\\' {
      escaped = true
      continue
    }
    if code == '{' {
      guard find_closing_brace(pattern, index + 1) is Some(end) else {
        return None
      }
      let content = pattern[index + 1:end].to_owned()
      let items = match expand_numeric_range(content) {
        Some(values) => values
        None => split_brace_items(content)
      }
      if items.length() <= 1 {
        return None
      }
      let expanded : Array[String] = []
      for item in items {
        expanded.push(
          pattern[:index].to_owned() + item + pattern[end + 1:].to_owned(),
        )
      }
      return Some(expanded)
    }
  }
  None
}

///|
fn expand_braces(pattern : String) -> Array[String] {
  let pending : Array[String] = [pattern]
  let result : Array[String] = []
  let mut expansions = 0
  while pending.length() > 0 {
    let current = pending.pop().unwrap()
    match expand_braces_once(current) {
      Some(items) if expansions < 256 => {
        expansions += items.length()
        for item in items {
          pending.push(item)
        }
      }
      _ => result.push(current)
    }
  }
  result
}

///|
fn parse_character_class(
  pattern : String,
  start : Int,
) -> (GlobToken, Int, String?) {
  let mut index = start + 1
  let mut negated = false
  if index < pattern.length() &&
    (pattern[index] == '!' || pattern[index] == '^') {
    negated = true
    index += 1
  }
  let chars : Array[UInt16] = []
  let ranges : Array[(UInt16, UInt16)] = []
  let mut found_end = false
  while index < pattern.length() {
    if pattern[index] == ']' && (chars.length() > 0 || ranges.length() > 0) {
      found_end = true
      index += 1
      break
    }
    let first = pattern[index]
    if index + 2 < pattern.length() &&
      pattern[index + 1] == '-' &&
      pattern[index + 2] != ']' {
      ranges.push((first, pattern[index + 2]))
      index += 3
    } else {
      chars.push(first)
      index += 1
    }
  }
  if found_end {
    (CharacterClass(chars~, ranges~, negated~), index, None)
  } else {
    (Literal('['), start + 1, Some("unclosed character class"))
  }
}

///|
fn compile_alternative(pattern : String) -> (Array[GlobToken], Array[String]) {
  let tokens : Array[GlobToken] = []
  let diagnostics : Array[String] = []
  let mut index = 0
  while index < pattern.length() {
    match pattern[index] {
      '/' => {
        tokens.push(Separator)
        index += 1
      }
      '*' =>
        if index + 1 < pattern.length() && pattern[index + 1] == '*' {
          tokens.push(AnyPath)
          index += 2
          while index < pattern.length() && pattern[index] == '*' {
            index += 1
          }
        } else {
          tokens.push(AnySegment)
          index += 1
        }
      '?' => {
        tokens.push(AnyCharacter)
        index += 1
      }
      '[' => {
        let (token, next, issue) = parse_character_class(pattern, index)
        tokens.push(token)
        if issue is Some(message) {
          diagnostics.push(message)
        }
        index = next
      }
      '\\' =>
        if index + 1 < pattern.length() {
          tokens.push(Literal(pattern[index + 1]))
          index += 2
        } else {
          tokens.push(Literal('\\'))
          index += 1
        }
      code => {
        tokens.push(Literal(code))
        index += 1
      }
    }
  }
  (tokens, diagnostics)
}

///|
pub fn compile_glob(pattern : String) -> GlobProgram {
  let alternatives : Array[Array[GlobToken]] = []
  let diagnostics : Array[String] = []
  for expanded in expand_braces(pattern) {
    let (tokens, issues) = compile_alternative(expanded)
    alternatives.push(tokens)
    for issue in issues {
      diagnostics.push(issue)
    }
  }
  { source: pattern, alternatives, diagnostics }
}

///|
fn class_contains(
  code : UInt16,
  chars : Array[UInt16],
  ranges : Array[(UInt16, UInt16)],
) -> Bool {
  if chars.any(item => item == code) {
    return true
  }
  ranges.any(range => {
    let (start, finish) = range
    if start <= finish {
      code >= start && code <= finish
    } else {
      code >= finish && code <= start
    }
  })
}

///|
fn match_tokens(
  tokens : Array[GlobToken],
  path : String,
  token_index : Int,
  path_index : Int,
  failed : Map[String, Bool],
) -> Bool {
  let key = token_index.to_string() + ":" + path_index.to_string()
  if failed.contains(key) {
    return false
  }
  if token_index == tokens.length() {
    return path_index == path.length()
  }
  let matched = match tokens[token_index] {
    Literal(expected) =>
      path_index < path.length() &&
      path[path_index] == expected &&
      match_tokens(tokens, path, token_index + 1, path_index + 1, failed)
    Separator =>
      path_index < path.length() &&
      path[path_index] == '/' &&
      match_tokens(tokens, path, token_index + 1, path_index + 1, failed)
    AnyCharacter =>
      path_index < path.length() &&
      path[path_index] != '/' &&
      match_tokens(tokens, path, token_index + 1, path_index + 1, failed)
    AnySegment => {
      let mut cursor = path_index
      let mut success = match_tokens(
        tokens,
        path,
        token_index + 1,
        cursor,
        failed,
      )
      while !success && cursor < path.length() && path[cursor] != '/' {
        cursor += 1
        success = match_tokens(tokens, path, token_index + 1, cursor, failed)
      }
      success
    }
    AnyPath => {
      let mut cursor = path_index
      let mut success = match_tokens(
        tokens,
        path,
        token_index + 1,
        cursor,
        failed,
      )
      while !success && cursor < path.length() {
        cursor += 1
        success = match_tokens(tokens, path, token_index + 1, cursor, failed)
      }
      success
    }
    CharacterClass(chars~, ranges~, negated~) =>
      if path_index >= path.length() || path[path_index] == '/' {
        false
      } else {
        let contains = class_contains(path[path_index], chars, ranges)
        (if negated { !contains } else { contains }) &&
        match_tokens(tokens, path, token_index + 1, path_index + 1, failed)
      }
  }
  if !matched {
    failed[key] = true
  }
  matched
}

///|
pub fn GlobProgram::matches(self : GlobProgram, path : String) -> Bool {
  let normalized = normalize_path(path)
  for alternative in self.alternatives {
    if match_tokens(alternative, normalized, 0, 0, {}) {
      return true
    }
  }
  false
}

///|
pub fn glob_matches(pattern : String, path : String) -> Bool {
  let normalized = normalize_path(path)
  let subject = if pattern.contains("/") || pattern.contains("\\") {
    normalized
  } else {
    basename(normalized)
  }
  compile_glob(pattern).matches(subject)
}

///|
pub fn explain_glob(pattern : String, path : String) -> String {
  let program = compile_glob(pattern)
  if program.diagnostics.length() > 0 {
    "模式无效：" + program.diagnostics.join("；")
  } else if glob_matches(pattern, path) {
    "路径与模式匹配"
  } else if !pattern.contains("/") {
    "模式只与文件名 `" + basename(path) + "` 比较，结果不匹配"
  } else {
    "相对路径 `" + normalize_path(path) + "` 与模式不匹配"
  }
}
