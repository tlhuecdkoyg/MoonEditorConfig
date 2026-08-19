///|
pub struct SourceLocation {
  line : Int
}

///|
pub struct Property {
  key : String
  value : String
  source : SourceLocation
}

///|
pub struct Section {
  pattern : String
  properties : Array[Property]
  source : SourceLocation
}

///|
pub struct EditorConfig {
  root : Bool
  preamble : Array[Property]
  sections : Array[Section]
}

///|
pub struct Diagnostic {
  line : Int
  message : String
}

///|
pub struct ParseResult {
  config : EditorConfig
  diagnostics : Array[Diagnostic]
}

///|
fn trim(value : String) -> String {
  value.trim().to_owned()
}

///|
fn parse_pair(line : String, line_number : Int) -> Property? {
  let separator = line.find("=")
  match separator {
    Some(index) => {
      let key = trim(line[:index].to_owned()).to_lower()
      let value = trim(line[index + 1:].to_owned())
      if key == "" {
        None
      } else {
        Some({ key, value, source: { line: line_number } })
      }
    }
    None => None
  }
}

///|
pub fn parse(source : String) -> ParseResult {
  let mut root = false
  let preamble = Array::new()
  let sections = Array::new()
  let diagnostics = Array::new()
  let mut current_section : Section? = None
  let mut line_number = 0
  for raw_line in source.split("\n") {
    line_number += 1
    let line = trim(raw_line.to_owned().trim_end().to_owned())
    if line == "" || line.has_prefix("#") || line.has_prefix(";") {
      continue
    }
    if line.has_prefix("[") && line.has_suffix("]") {
      if current_section is Some(section) {
        sections.push(section)
      }
      let pattern = line[1:line.length() - 1].to_owned()
      let section = {
        pattern,
        properties: Array::new(),
        source: { line: line_number },
      }
      current_section = Some(section)
      continue
    }
    if line.has_prefix("[") {
      diagnostics.push({
        line: line_number,
        message: "section header must end with ]",
      })
      continue
    }
    match parse_pair(line, line_number) {
      Some(property) =>
        if current_section is Some(section) {
          section.properties.push(property)
        } else if property.key == "root" {
          root = property.value.to_lower() == "true"
          preamble.push(property)
        } else {
          preamble.push(property)
        }
      None =>
        diagnostics.push({
          line: line_number,
          message: "expected a key = value pair or section header",
        })
    }
  }
  if current_section is Some(section) {
    sections.push(section)
  }
  { config: { root, preamble, sections }, diagnostics }
}
