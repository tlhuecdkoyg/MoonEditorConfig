///|
test "parser regression/source spans preserve indentation CRLF and UTF16 offsets" {
  let source = "# 🚀\r\n  [*.mbt]  \r\n\t  charset = utf-8-bom  \r\n"
  let parsed = @MoonEditorConfig.parse_document("/repo/.editorconfig", source)
  let section = parsed.config.sections[0]
  assert_eq(section.source.column, 3)
  assert_eq(
    source[section.span.start.offset:section.span.end.offset].to_owned(),
    "[*.mbt]",
  )
  let property = section.properties[0]
  assert_eq(property.source.column, 4)
  assert_eq(property.source.offset, source.find("charset").unwrap())
  assert_eq(
    source[property.span.start.offset:property.span.end.offset].to_owned(),
    "charset = utf-8-bom",
  )
}

///|
test "parser regression/BOM and indented diagnostics retain raw coordinates" {
  let source = "\u{FEFF}  root = maybe\r\n[*]\r\n    broken line\r\n"
  let parsed = @MoonEditorConfig.parse(source)
  assert_eq(parsed.config.preamble[0].source.column, 4)
  assert_eq(parsed.config.preamble[0].source.offset, 3)
  assert_eq(parsed.diagnostics[0].span.start.offset, 3)
  assert_eq(parsed.diagnostics[0].span.start.column, 4)
  let broken = parsed.diagnostics[1]
  assert_eq(broken.span.start.column, 5)
  assert_eq(broken.span.start.offset, source.find("broken").unwrap())
}

///|
test "fixes regression/indented charset review edit preserves neighboring source" {
  let source = "root=true\r\n[*]\r\n  charset = utf-8-bom  \r\n"
  let plan = @MoonEditorConfig.plan_fixes(source)
  let proposals = plan.edits.filter(edit => edit.title.contains("无 BOM"))
  assert_eq(proposals.length(), 1)
  assert_eq(
    @MoonEditorConfig.validate_edits(proposals, source.length()).length(),
    0,
  )
  assert_eq(
    @MoonEditorConfig.apply_edits(source, proposals),
    "root=true\r\n[*]\r\n  charset = utf-8  \r\n",
  )
}

///|
test "format regression/escaped keys and backslashes retain parsed meaning" {
  let source = "root=true\ncustom\\:meta = prefix\\\\=suffix\n[*]\ncustom\\=key = left\\\\=right\npath = C:\\\\repo\\\\src\n"
  let before = @MoonEditorConfig.parse(source).config
  let once = @MoonEditorConfig.format_config(before)
  let after = @MoonEditorConfig.parse(once).config
  assert_eq(after.preamble[1].key, before.preamble[1].key)
  assert_eq(after.preamble[1].value, before.preamble[1].value)
  for index in 0..<before.sections[0].properties.length() {
    let left = before.sections[0].properties[index]
    let right = after.sections[0].properties[index]
    assert_eq(right.key, left.key)
    assert_eq(right.value, left.value)
  }
  assert_eq(@MoonEditorConfig.format_config(after), once)
  let options = @MoonEditorConfig.FormatOptions::default()
  let colon = @MoonEditorConfig.format_config(before, options={
    ..options,
    separator: ":",
  })
  assert_eq(
    @MoonEditorConfig.parse(colon).config.sections[0].properties[0].key,
    "custom=key",
  )
}

///|
test "fixes regression/syntax errors prevent destructive automatic formatting" {
  for
    source in [
      "root=true\n[*]\nbroken line\nindent_size=2\n", "root=maybe\n[*]\nindent_size=2\n",
      "root=true\n[broken\nindent_size=2\n",
    ] {
    let plan = @MoonEditorConfig.plan_fixes(source)
    assert_eq(plan.safe_count, 0)
    assert_eq(plan.safe_source, source)
    assert_eq(plan.diff, "")
  }
}

///|
test "format regression/non-special escapes retain their literal backslashes" {
  let source = "root=true\n[*]\n\\#key = x\n\\;key = x\n\\[key = x\n\\ key = x\nvalue = \\ value\n"
  let before = @MoonEditorConfig.parse(source).config
  let properties = before.sections[0].properties
  assert_eq(properties.length(), 5)
  assert_eq(properties[0].key, "\\#key")
  assert_eq(properties[1].key, "\\;key")
  assert_eq(properties[2].key, "\\[key")
  assert_eq(properties[3].key, "\\ key")
  assert_eq(properties[4].value, "\\ value")
  let formatted = @MoonEditorConfig.format_config(before)
  let parsed = @MoonEditorConfig.parse(formatted)
  assert_eq(parsed.diagnostics.length(), 0)
  let after = parsed.config.sections[0].properties
  assert_eq(after.length(), properties.length())
  for index in 0..<properties.length() {
    assert_eq(after[index].key, properties[index].key)
    assert_eq(after[index].value, properties[index].value)
  }
  assert_eq(@MoonEditorConfig.format_config(parsed.config), formatted)
}
