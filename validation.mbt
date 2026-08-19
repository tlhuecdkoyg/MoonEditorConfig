///|
pub fn validate(config : EditorConfig) -> Array[Diagnostic] {
  let diagnostics : Array[Diagnostic] = []
  for property in config.preamble {
    validate_property(property, diagnostics)
  }
  for section in config.sections {
    for property in section.properties {
      validate_property(property, diagnostics)
    }
  }
  diagnostics
}

///|
fn validate_property(
  property : Property,
  diagnostics : Array[Diagnostic],
) -> Unit {
  let value = property.value.to_lower()
  let valid = match property.key {
    "indent_style" => value == "tab" || value == "space"
    "end_of_line" => value == "lf" || value == "cr" || value == "crlf"
    "charset" =>
      value == "latin1" ||
      value == "utf-8" ||
      value == "utf-8-bom" ||
      value == "utf-16be" ||
      value == "utf-16le"
    "trim_trailing_whitespace" | "insert_final_newline" | "root" =>
      value == "true" || value == "false" || value == "unset"
    _ => true
  }
  if !valid {
    diagnostics.push({
      line: property.source.line,
      message: "invalid value for EditorConfig property: " + property.key,
    })
  }
}
