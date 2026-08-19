///|
pub fn glob_matches(pattern : String, path : String) -> Bool {
  match_glob(pattern, path, 0, 0)
}

///|
fn match_glob(
  pattern : String,
  path : String,
  pattern_index : Int,
  path_index : Int,
) -> Bool {
  if pattern_index == pattern.length() {
    return path_index == path.length()
  }
  match pattern.get_char(pattern_index) {
    Some('*') =>
      match_glob(pattern, path, pattern_index + 1, path_index) ||
      (
        path_index < path.length() &&
        match_glob(pattern, path, pattern_index, path_index + 1)
      )
    Some('?') =>
      path_index < path.length() &&
      match_glob(pattern, path, pattern_index + 1, path_index + 1)
    Some(char) =>
      path.get_char(path_index) is Some(next) &&
      char == next &&
      match_glob(pattern, path, pattern_index + 1, path_index + 1)
    None => false
  }
}
