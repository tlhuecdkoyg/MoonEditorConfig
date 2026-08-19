///|
fn parse_result_json(parsed : ParseResult) -> String {
  let diagnostics = parsed.diagnostics.copy()
  for diagnostic in validate(parsed.config) {
    diagnostics.push(diagnostic)
  }
  let items : Array[String] = []
  for diagnostic in diagnostics {
    items.push(diagnostic_json(diagnostic))
  }
  "{\"root\":" +
  bool_text(parsed.config.root) +
  ",\"sections\":" +
  parsed.config.sections.length().to_string() +
  ",\"diagnostics\":[" +
  items.join(",") +
  "]}"
}

///|
/// Analyze an in-browser document and return a self-contained JSON snapshot.
pub fn studio_snapshot(source : String, target : String) -> String {
  let parsed = parse_document("/.editorconfig", source)
  let quality = audit(parsed.config, initial=parsed.diagnostics)
  let fixes = plan_fixes(source)
  let resolution = resolve_layers(
    [{ path: "/.editorconfig", directory: "/", config: parsed.config }],
    "/" + normalize_path(target),
  )
  for diagnostic in parsed.diagnostics {
    resolution.diagnostics.push(diagnostic)
  }
  let matched = resolution.sections.fold(init=0, (count, trace) => {
    count + (if trace.matched { 1 } else { 0 })
  })
  "{\"score\":" +
  quality.score.to_string() +
  ",\"grade\":\"" +
  json_escape(quality.grade) +
  "\",\"matchedSections\":" +
  matched.to_string() +
  ",\"formatted\":\"" +
  json_escape(fixes.safe_source) +
  "\",\"formatChanged\":" +
  bool_text(fixes.safe_count > 0) +
  ",\"parse\":" +
  parse_result_json(parsed) +
  ",\"resolution\":" +
  resolution.to_json() +
  "}"
}
