///|
fn severity_name(severity : Severity) -> String {
  match severity {
    Error => "error"
    Warning => "warning"
    Information => "information"
  }
}

///|
fn location_json(location : SourceLocation) -> String {
  "{\"file\":\"" +
  json_escape(location.file) +
  "\",\"line\":" +
  location.line.to_string() +
  ",\"column\":" +
  location.column.to_string() +
  ",\"offset\":" +
  location.offset.to_string() +
  "}"
}

///|
fn diagnostic_json(diagnostic : Diagnostic) -> String {
  "{\"severity\":\"" +
  severity_name(diagnostic.severity) +
  "\",\"code\":\"" +
  json_escape(diagnostic.code) +
  "\",\"message\":\"" +
  json_escape(diagnostic.message) +
  "\",\"hint\":\"" +
  json_escape(diagnostic.hint) +
  "\",\"start\":" +
  location_json(diagnostic.span.start) +
  ",\"end\":" +
  location_json(diagnostic.span.end) +
  "}"
}

///|
fn step_json(step : PropertyStep) -> String {
  "{\"key\":\"" +
  json_escape(step.key) +
  "\",\"value\":\"" +
  json_escape(step.value) +
  "\",\"configPath\":\"" +
  json_escape(step.config_path) +
  "\",\"pattern\":\"" +
  json_escape(step.pattern) +
  "\",\"line\":" +
  step.line.to_string() +
  ",\"action\":\"" +
  json_escape(step.action) +
  "\"}"
}

///|
fn property_json(property : ResolvedProperty) -> String {
  let history : Array[String] = []
  for step in property.history {
    history.push(step_json(step))
  }
  "{\"key\":\"" +
  json_escape(property.key) +
  "\",\"value\":\"" +
  json_escape(property.value) +
  "\",\"configPath\":\"" +
  json_escape(property.config_path) +
  "\",\"pattern\":\"" +
  json_escape(property.pattern) +
  "\",\"source\":" +
  location_json(property.source) +
  ",\"history\":[" +
  history.join(",") +
  "]}"
}

///|
fn trace_json(trace : SectionTrace) -> String {
  "{\"configPath\":\"" +
  json_escape(trace.config_path) +
  "\",\"pattern\":\"" +
  json_escape(trace.pattern) +
  "\",\"matched\":" +
  bool_text(trace.matched) +
  ",\"relativePath\":\"" +
  json_escape(trace.relative_path) +
  "\",\"line\":" +
  trace.line.to_string() +
  ",\"reason\":\"" +
  json_escape(trace.reason) +
  "\"}"
}

///|
pub fn Resolution::to_json(self : Resolution, indent? : Bool = false) -> String {
  let properties : Array[String] = []
  let sections : Array[String] = []
  let diagnostics : Array[String] = []
  for property in self.properties {
    properties.push(property_json(property))
  }
  for section in self.sections {
    sections.push(trace_json(section))
  }
  for diagnostic in self.diagnostics {
    diagnostics.push(diagnostic_json(diagnostic))
  }
  let compact = "{\"target\":\"" +
    json_escape(self.target) +
    "\",\"properties\":[" +
    properties.join(",") +
    "],\"sections\":[" +
    sections.join(",") +
    "],\"diagnostics\":[" +
    diagnostics.join(",") +
    "]}"
  if indent {
    pretty_json(compact)
  } else {
    compact
  }
}

///|
fn pretty_json(compact : String) -> String {
  let output = StringBuilder::new()
  let mut depth = 0
  let mut quoted = false
  let mut escaped = false
  for ch in compact {
    if quoted {
      output.write_char(ch)
      if escaped {
        escaped = false
      } else if ch == '\\' {
        escaped = true
      } else if ch == '"' {
        quoted = false
      }
    } else {
      match ch {
        '"' => {
          quoted = true
          output.write_char(ch)
        }
        '{' | '[' => {
          output.write_char(ch)
          output.write_char('\n')
          depth += 1
          for _ in 0..<depth {
            output.write_string("  ")
          }
        }
        '}' | ']' => {
          output.write_char('\n')
          depth -= 1
          for _ in 0..<depth {
            output.write_string("  ")
          }
          output.write_char(ch)
        }
        ',' => {
          output.write_char(ch)
          output.write_char('\n')
          for _ in 0..<depth {
            output.write_string("  ")
          }
        }
        ':' => output.write_string(": ")
        _ => output.write_char(ch)
      }
    }
  }
  output.to_string()
}
