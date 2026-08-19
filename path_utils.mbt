///|
/// Normalize separators and remove redundant `.` path segments.
pub fn normalize_path(path : String) -> String {
  let replaced = StringBuilder::new()
  for ch in path {
    if ch == '\\' {
      replaced.write_char('/')
    } else {
      replaced.write_char(ch)
    }
  }
  let text = replaced.to_string()
  let absolute = text.has_prefix("/")
  let segments : Array[String] = []
  for part in text.split("/") {
    let segment = part.to_owned()
    if segment == "" || segment == "." {
      continue
    }
    if segment == ".." {
      if segments.length() > 0 && segments[segments.length() - 1] != ".." {
        ignore(segments.pop())
      } else if !absolute {
        segments.push(segment)
      }
    } else {
      segments.push(segment)
    }
  }
  let joined = segments.join("/")
  if absolute {
    "/" + joined
  } else {
    joined
  }
}

///|
pub fn parent_path(path : String) -> String? {
  let normalized = normalize_path(path)
  match last_separator(normalized) {
    None => None
    Some(0) => Some("/")
    Some(index) => Some(normalized[:index].to_owned())
  }
}

///|
pub fn relative_path(base : String, target : String) -> String? {
  let normalized_base = normalize_path(base)
  let normalized_target = normalize_path(target)
  if normalized_base == "" {
    return Some(normalized_target)
  }
  if normalized_target == normalized_base {
    return Some("")
  }
  let prefix = if normalized_base.has_suffix("/") {
    normalized_base
  } else {
    normalized_base + "/"
  }
  if normalized_target.has_prefix(prefix) {
    Some(normalized_target[prefix.length():].to_owned())
  } else {
    None
  }
}

///|
fn basename(path : String) -> String {
  let normalized = normalize_path(path)
  match last_separator(normalized) {
    Some(index) => normalized[index + 1:].to_owned()
    None => normalized
  }
}

///|
fn last_separator(path : String) -> Int? {
  for index = path.length(); index > 0; index = index - 1 {
    if path[index - 1] == '/' {
      return Some(index - 1)
    }
  }
  None
}

///|
fn path_depth(path : String) -> Int {
  let normalized = normalize_path(path)
  if normalized == "" {
    0
  } else {
    normalized.split("/").length()
  }
}
