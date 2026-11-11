///|
/// A source location in an EditorConfig document.
#derive(Debug, Eq)
pub(all) struct SourceLocation {
  file : String
  line : Int32
  column : Int32
  offset : Int32
}

///|
/// A half-open source range used by diagnostics and editor integrations.
#derive(Debug, Eq)
pub(all) struct SourceSpan {
  start : SourceLocation
  end : SourceLocation
}

///|
/// Severity of a diagnostic produced while parsing or validating a file.
#derive(Debug, Eq)
pub(all) enum Severity {
  Error
  Warning
  Information
}

///|
/// A structured, machine-readable problem report.
#derive(Debug, Eq)
pub(all) struct Diagnostic {
  line : Int32
  severity : Severity
  code : String
  message : String
  hint : String
  span : SourceSpan
}

///|
/// A key/value assignment together with its original spelling and location.
#derive(Debug, Eq)
pub(all) struct Property {
  key : String
  value : String
  raw_key : String
  raw_value : String
  source : SourceLocation
  span : SourceSpan
}

///|
/// A section header and the properties governed by its glob pattern.
#derive(Debug, Eq)
pub(all) struct Section {
  pattern : String
  properties : Array[Property]
  source : SourceLocation
  span : SourceSpan
}

///|
/// Parsed representation of one `.editorconfig` file.
#derive(Debug, Eq)
pub(all) struct EditorConfig {
  path : String
  root : Bool
  preamble : Array[Property]
  sections : Array[Section]
  source_text : String
}

///|
/// Result of parsing one document. Syntax errors are collected rather than
/// raised so callers can continue providing editor feedback.
#derive(Debug, Eq)
pub(all) struct ParseResult {
  config : EditorConfig
  diagnostics : Array[Diagnostic]
}

///|
/// One configuration file in a root-to-leaf resolution chain.
#derive(Debug, Eq)
pub(all) struct ConfigLayer {
  path : String
  directory : String
  config : EditorConfig
}

///|
/// Explanation for one section considered by the resolver.
#derive(Debug, Eq)
pub(all) struct SectionTrace {
  config_path : String
  pattern : String
  matched : Bool
  relative_path : String
  line : Int32
  reason : String
}

///|
/// One assignment in the history of a resolved property.
#derive(Debug, Eq)
pub(all) struct PropertyStep {
  key : String
  value : String
  config_path : String
  pattern : String
  line : Int32
  action : String
}

///|
/// Final value and complete override history for a property.
#derive(Debug, Eq)
pub(all) struct ResolvedProperty {
  key : String
  value : String
  source : SourceLocation
  pattern : String
  config_path : String
  history : Array[PropertyStep]
}

///|
/// Complete resolution output for a target file.
#derive(Debug, Eq)
pub(all) struct Resolution {
  target : String
  properties : Array[ResolvedProperty]
  sections : Array[SectionTrace]
  diagnostics : Array[Diagnostic]
}

///|
/// Options controlling parser compatibility and diagnostics.
#derive(Debug, Eq)
pub(all) struct ParseOptions {
  path : String
  allow_colon_separator : Bool
  warn_duplicate_keys : Bool
  warn_unknown_preamble : Bool
}

///|
/// Return practical defaults suitable for editor and CLI use.
pub fn ParseOptions::default() -> ParseOptions {
  {
    path: "<memory>",
    allow_colon_separator: true,
    warn_duplicate_keys: true,
    warn_unknown_preamble: true,
  }
}

///|
fn make_location(
  file : String,
  line : Int32,
  column : Int32,
  offset : Int32,
) -> SourceLocation {
  { file, line, column, offset, }
}

///|
fn make_span(
  file : String,
  line : Int32,
  start_column : Int32,
  end_column : Int32,
  offset : Int32,
) -> SourceSpan {
  {
    start: make_location(file, line, start_column, offset),
    end: make_location(
      file,
      line,
      end_column,
      offset + end_column - start_column,
    ),
  }
}

///|
fn make_diagnostic(
  file : String,
  line : Int32,
  column : Int32,
  end_column : Int32,
  offset : Int32,
  severity : Severity,
  code : String,
  message : String,
  hint : String,
) -> Diagnostic {
  {
    line,
    severity,
    code,
    message,
    hint,
    span: make_span(file, line, column, end_column, offset),
  }
}
