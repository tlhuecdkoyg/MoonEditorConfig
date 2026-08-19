///|
pub(all) struct FormatOptions {
  indent : String
  separator : String
  final_newline : Bool
  sort_properties : Bool
} derive(Debug, Eq)

///|
pub fn FormatOptions::default() -> FormatOptions {
  { indent: "", separator: " = ", final_newline: true, sort_properties: false }
}

///|
fn format_properties(
  properties : Array[Property],
  options : FormatOptions,
) -> Array[String] {
  let ordered = properties.copy()
  if options.sort_properties {
    ordered.sort_by((left, right) => left.key.compare(right.key))
  }
  let lines : Array[String] = []
  for property in ordered {
    lines.push(
      options.indent + property.key + options.separator + property.value,
    )
  }
  lines
}

///|
/// Render a canonical representation of a parsed EditorConfig document.
pub fn format_config(
  config : EditorConfig,
  options? : FormatOptions = FormatOptions::default(),
) -> String {
  let lines : Array[String] = []
  if config.root {
    lines.push("root" + options.separator + "true")
  }
  for property in config.preamble {
    if property.key != "root" {
      lines.push(property.key + options.separator + property.value)
    }
  }
  if lines.length() > 0 && config.sections.length() > 0 {
    lines.push("")
  }
  for section_index, section in config.sections {
    lines.push("[" + section.pattern + "]")
    for line in format_properties(section.properties, options) {
      lines.push(line)
    }
    if section_index + 1 < config.sections.length() {
      lines.push("")
    }
  }
  let result = lines.join("\n")
  if options.final_newline {
    result + "\n"
  } else {
    result
  }
}

///|
pub fn needs_formatting(
  source : String,
  options? : FormatOptions = FormatOptions::default(),
) -> Bool {
  let parsed = parse(source)
  format_config(parsed.config, options~) != source
}
