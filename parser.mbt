///|
priv struct ParserState {
  options : ParseOptions
  preamble : Array[Property]
  sections : Array[Section]
  diagnostics : Array[Diagnostic]
  mut current_section : Section?
  mut root : Bool
  mut offset : Int
}

///|
fn ParserState::diagnose(
  self : ParserState,
  line : Int,
  column : Int,
  end_column : Int,
  severity : Severity,
  code : String,
  message : String,
  hint : String,
) -> Unit {
  self.diagnostics.push(
    make_diagnostic(
      self.options.path,
      line,
      column,
      end_column,
      self.offset,
      severity,
      code,
      message,
      hint,
    ),
  )
}

///|
fn ParserState::finish_section(self : ParserState) -> Unit {
  if self.current_section is Some(section) {
    self.sections.push(section)
    self.current_section = None
  }
}

///|
fn ParserState::has_key_in_current_scope(
  self : ParserState,
  key : String,
) -> Bool {
  match self.current_section {
    Some(section) => section.properties.any(property => property.key == key)
    None => self.preamble.any(property => property.key == key)
  }
}

///|
fn ParserState::push_property(self : ParserState, property : Property) -> Unit {
  if self.options.warn_duplicate_keys &&
    self.has_key_in_current_scope(property.key) {
    self.diagnose(
      property.source.line,
      property.source.column,
      property.span.end.column,
      Warning,
      "EC1006",
      "duplicate property in the same scope: " + property.key,
      "The later value wins; remove the earlier assignment if this is intentional.",
    )
  }
  match self.current_section {
    Some(section) => section.properties.push(property)
    None => {
      if property.key == "root" {
        let root_value = lower_ascii(property.value)
        if root_value == "true" {
          self.root = true
        } else if root_value == "false" {
          self.root = false
        } else {
          self.diagnose(
            property.source.line,
            property.source.column,
            property.span.end.column,
            Error,
            "EC1007",
            "root must be true or false",
            "Use `root = true` to stop searching parent directories.",
          )
        }
      } else if self.options.warn_unknown_preamble {
        self.diagnose(
          property.source.line,
          property.source.column,
          property.span.end.column,
          Warning,
          "EC1008",
          "property outside a section has no effect: " + property.key,
          "Move the property below a section header such as `[*]`.",
        )
      }
      self.preamble.push(property)
    }
  }
}

///|
fn ParserState::parse_section(
  self : ParserState,
  line : String,
  line_number : Int,
) -> Bool {
  guard line.has_prefix("[") else { return false }
  if !line.has_suffix("]") {
    self.diagnose(
      line_number,
      1,
      line.length() + 1,
      Error,
      "EC1001",
      "section header must end with ]",
      "Add a closing bracket to the section header.",
    )
    return true
  }
  let pattern = line[1:line.length() - 1].to_owned()
  if pattern == "" {
    self.diagnose(
      line_number,
      1,
      line.length() + 1,
      Error,
      "EC1002",
      "section pattern cannot be empty",
      "Provide a glob pattern, for example `[*.mbt]`.",
    )
    return true
  }
  self.finish_section()
  self.current_section = Some({
    pattern,
    properties: [],
    source: make_location(self.options.path, line_number, 1, self.offset),
    span: make_span(
      self.options.path,
      line_number,
      1,
      line.length() + 1,
      self.offset,
    ),
  })
  true
}

///|
fn ParserState::parse_assignment(
  self : ParserState,
  line : String,
  line_number : Int,
) -> Unit {
  match find_unescaped_separator(line, self.options.allow_colon_separator) {
    None =>
      self.diagnose(
        line_number,
        1,
        line.length() + 1,
        Error,
        "EC1003",
        "expected a key/value assignment",
        "Separate the property name and value with `=`.",
      )
    Some(separator) => {
      let raw_key = line[:separator].to_owned()
      let raw_value = line[separator + 1:].to_owned()
      let key_start = first_non_space(raw_key)
      let key_end = last_non_space_end(raw_key)
      let value_start = first_non_space(raw_value)
      let value_end = last_non_space_end(raw_value)
      let key = lower_ascii(
        unescape_assignment(raw_key[key_start:key_end].to_owned()),
      )
      let value = unescape_assignment(
        raw_value[value_start:value_end].to_owned(),
      )
      if key == "" {
        self.diagnose(
          line_number,
          1,
          separator + 1,
          Error,
          "EC1004",
          "property name cannot be empty",
          "Add a property name before the separator.",
        )
      } else if value == "" {
        self.diagnose(
          line_number,
          separator + 2,
          line.length() + 1,
          Warning,
          "EC1005",
          "property value is empty",
          "Use `unset` to remove an inherited value explicitly.",
        )
        self.push_property({
          key,
          value,
          raw_key: raw_key[key_start:key_end].to_owned(),
          raw_value: raw_value[value_start:value_end].to_owned(),
          source: make_location(
            self.options.path,
            line_number,
            key_start + 1,
            self.offset + key_start,
          ),
          span: make_span(
            self.options.path,
            line_number,
            key_start + 1,
            line.length() + 1,
            self.offset + key_start,
          ),
        })
      } else {
        self.push_property({
          key,
          value,
          raw_key: raw_key[key_start:key_end].to_owned(),
          raw_value: raw_value[value_start:value_end].to_owned(),
          source: make_location(
            self.options.path,
            line_number,
            key_start + 1,
            self.offset + key_start,
          ),
          span: make_span(
            self.options.path,
            line_number,
            key_start + 1,
            line.length() + 1,
            self.offset + key_start,
          ),
        })
      }
    }
  }
}

///|
fn ParserState::parse_line(
  self : ParserState,
  raw_line : String,
  line_number : Int,
) -> Unit {
  let without_bom = strip_utf8_bom(raw_line, line_number == 1)
  let line = trim_owned(without_bom.trim_end().to_owned())
  if line == "" || line.has_prefix("#") || line.has_prefix(";") {
    return
  }
  if !self.parse_section(line, line_number) {
    self.parse_assignment(line, line_number)
  }
}

///|
/// Parse an EditorConfig document with explicit options.
pub fn parse_with_options(
  source : String,
  options : ParseOptions,
) -> ParseResult {
  let state = {
    options,
    preamble: [],
    sections: [],
    diagnostics: [],
    current_section: None,
    root: false,
    offset: 0,
  }
  let mut line_number = 0
  for raw_line in source.split("\n") {
    line_number += 1
    state.parse_line(raw_line.to_owned(), line_number)
    state.offset = state.offset + raw_line.length() + 1
  }
  state.finish_section()
  {
    config: {
      path: options.path,
      root: state.root,
      preamble: state.preamble,
      sections: state.sections,
      source_text: source,
    },
    diagnostics: state.diagnostics,
  }
}

///|
/// Parse an in-memory EditorConfig document using compatibility defaults.
pub fn parse(source : String) -> ParseResult {
  parse_with_options(source, ParseOptions::default())
}

///|
/// Parse a document while retaining its source path in diagnostics.
pub fn parse_document(path : String, source : String) -> ParseResult {
  let options = ParseOptions::default()
  parse_with_options(source, { ..options, path, })
}
