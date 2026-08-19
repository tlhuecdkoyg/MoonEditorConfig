///|
/// A source location in an EditorConfig document.
pub(all) struct SourceLocation {
  file : String
  line : Int
  column : Int
  offset : Int
} derive(Debug, Eq)

///|
/// A half-open source range used by diagnostics and editor integrations.
pub(all) struct SourceSpan {
  start : SourceLocation
  end : SourceLocation
} derive(Debug, Eq)

///|
/// Severity of a diagnostic produced while parsing or validating a file.
pub(all) enum Severity {
  Error
  Warning
  Information
} derive(Debug, Eq)

///|
/// A structured, machine-readable problem report.
pub(all) struct Diagnostic {
  line : Int
  severity : Severity
  code : String
  message : String
  hint : String
  span : SourceSpan
} derive(Debug, Eq)

///|
/// A key/value assignment together with its original spelling and location.
pub(all) struct Property {
  key : String
  value : String
  raw_key : String
  raw_value : String
  source : SourceLocation
  span : SourceSpan
} derive(Debug, Eq)

///|
/// A section header and the properties governed by its glob pattern.
pub(all) struct Section {
  pattern : String
  properties : Array[Property]
  source : SourceLocation
  span : SourceSpan
} derive(Debug, Eq)

///|
/// Parsed representation of one `.editorconfig` file.
pub(all) struct EditorConfig {
  path : String
  root : Bool
  preamble : Array[Property]
  sections : Array[Section]
  source_text : String
} derive(Debug, Eq)

///|
/// Result of parsing one document. Syntax errors are collected rather than
/// raised so callers can continue providing editor feedback.
pub(all) struct ParseResult {
  config : EditorConfig
  diagnostics : Array[Diagnostic]
} derive(Debug, Eq)

///|
/// One configuration file in a root-to-leaf resolution chain.
pub(all) struct ConfigLayer {
  path : String
  directory : String
  config : EditorConfig
} derive(Debug, Eq)

///|
/// Explanation for one section considered by the resolver.
pub(all) struct SectionTrace {
  config_path : String
  pattern : String
  matched : Bool
  relative_path : String
  line : Int
  reason : String
} derive(Debug, Eq)

///|
/// One assignment in the history of a resolved property.
pub(all) struct PropertyStep {
  key : String
  value : String
  config_path : String
  pattern : String
  line : Int
  action : String
} derive(Debug, Eq)

///|
/// Final value and complete override history for a property.
pub(all) struct ResolvedProperty {
  key : String
  value : String
  source : SourceLocation
  pattern : String
  config_path : String
  history : Array[PropertyStep]
} derive(Debug, Eq)

///|
/// Complete resolution output for a target file.
pub(all) struct Resolution {
  target : String
  properties : Array[ResolvedProperty]
  sections : Array[SectionTrace]
  diagnostics : Array[Diagnostic]
} derive(Debug, Eq)

///|
/// Options controlling parser compatibility and diagnostics.
pub(all) struct ParseOptions {
  path : String
  allow_colon_separator : Bool
  warn_duplicate_keys : Bool
  warn_unknown_preamble : Bool
} derive(Debug, Eq)

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
  line : Int,
  column : Int,
  offset : Int,
) -> SourceLocation {
  { file, line, column, offset }
}

///|
fn make_span(
  file : String,
  line : Int,
  start_column : Int,
  end_column : Int,
  offset : Int,
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
  line : Int,
  column : Int,
  end_column : Int,
  offset : Int,
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
