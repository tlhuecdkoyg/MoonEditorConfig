///|
test "format/canonical spacing" {
  let parsed = @MoonEditorConfig.parse(
    "root=true\n[*.mbt]\nindent_size:2\ncharset   =utf-8\n",
  )
  let formatted = @MoonEditorConfig.format_config(parsed.config)
  assert_eq(
    formatted, "root = true\n\n[*.mbt]\nindent_size = 2\ncharset = utf-8\n",
  )
}

///|
test "format/preserves section and property order by default" {
  let parsed = @MoonEditorConfig.parse("[*.md]\nz = 1\na = 2\n[*.mbt]\nb = 3\n")
  let formatted = @MoonEditorConfig.format_config(parsed.config)
  assert_true(
    formatted.find("[*.md]").unwrap() < formatted.find("[*.mbt]").unwrap(),
  )
  assert_true(
    formatted.find("z = 1").unwrap() < formatted.find("a = 2").unwrap(),
  )
}

///|
test "format/can sort properties" {
  let parsed = @MoonEditorConfig.parse("[*]\nz = 1\na = 2\nm = 3\n")
  let defaults = @MoonEditorConfig.FormatOptions::default()
  let formatted = @MoonEditorConfig.format_config(parsed.config, options={
    ..defaults,
    sort_properties: true,
  })
  assert_true(
    formatted.find("a = 2").unwrap() < formatted.find("m = 3").unwrap(),
  )
  assert_true(
    formatted.find("m = 3").unwrap() < formatted.find("z = 1").unwrap(),
  )
}

///|
test "format/custom separator and indentation" {
  let parsed = @MoonEditorConfig.parse("[*]\nindent_size = 2\n")
  let defaults = @MoonEditorConfig.FormatOptions::default()
  let formatted = @MoonEditorConfig.format_config(parsed.config, options={
    ..defaults,
    indent: "  ",
    separator: ":",
    final_newline: false,
  })
  assert_eq(formatted, "[*]\n  indent_size:2")
}

///|
test "format/is idempotent" {
  let source = "root=true\n\n[*.mbt]\nindent_size:2\n"
  let once = @MoonEditorConfig.format_config(
    @MoonEditorConfig.parse(source).config,
  )
  let twice = @MoonEditorConfig.format_config(
    @MoonEditorConfig.parse(once).config,
  )
  assert_eq(once, twice)
  assert_false(@MoonEditorConfig.needs_formatting(once))
  assert_true(@MoonEditorConfig.needs_formatting(source))
}

///|
test "json/resolution output has stable fields" {
  let config = @MoonEditorConfig.parse_document(
      "/repo/.editorconfig", "[*]\nindent_size = 2\n",
    ).config
  let resolution = @MoonEditorConfig.resolve_layers(
    [{ path: "/repo/.editorconfig", directory: "/repo", config }],
    "/repo/main.mbt",
  )
  let json = resolution.to_json()
  assert_true(json.contains("\"target\":\"/repo/main.mbt\""))
  assert_true(json.contains("\"key\":\"indent_size\""))
  assert_true(json.contains("\"history\""))
  assert_true(json.contains("\"sections\""))
}

///|
test "json/escapes custom values" {
  let config = @MoonEditorConfig.parse_document(
      "/repo/.editorconfig", "[*]\ncustom = say \"hello\" \\\\ now\n",
    ).config
  let resolution = @MoonEditorConfig.resolve_layers(
    [{ path: "/repo/.editorconfig", directory: "/repo", config }],
    "/repo/file",
  )
  let json = resolution.to_json()
  assert_true(json.contains("\\\"hello\\\""))
  assert_true(json.contains("\\\\"))
}

///|
test "json/pretty mode adds line breaks" {
  let resolution = @MoonEditorConfig.resolve_layers([], "/file")
  let json = resolution.to_json(indent=true)
  assert_true(json.contains("\n"))
  assert_true(json.contains("  \"target\""))
}

///|
test "report/Chinese diagnostics include code hint and location" {
  let parsed = @MoonEditorConfig.parse_document(
    "/repo/.editorconfig", "broken\n",
  )
  let rendered = parsed.diagnostics[0].render_zh()
  assert_true(rendered.contains("/repo/.editorconfig:1:1"))
  assert_true(rendered.contains("EC1003"))
  assert_true(rendered.contains("建议"))
}

///|
test "report/explanation includes property history and traces" {
  let config = @MoonEditorConfig.parse_document(
      "/repo/.editorconfig", "[*]\nindent_size = 2\n",
    ).config
  let resolution = @MoonEditorConfig.resolve_layers(
    [{ path: "/repo/.editorconfig", directory: "/repo", config }],
    "/repo/main.mbt",
  )
  let report = resolution.explain_zh()
  assert_true(report.contains("最终配置"))
  assert_true(report.contains("indent_size = 2"))
  assert_true(report.contains("配置段匹配过程"))
}

///|
test "studio/snapshot is complete JSON" {
  let snapshot = @MoonEditorConfig.studio_snapshot(
    "root = true\n[*]\nindent_size = 2\n", "src/main.mbt",
  )
  assert_true(snapshot.contains("\"score\":100"))
  assert_true(snapshot.contains("\"matchedSections\":1"))
  assert_true(snapshot.contains("\"formatted\""))
  assert_true(snapshot.contains("\"resolution\""))
}

///|
test "studio/invalid config reduces score" {
  let snapshot = @MoonEditorConfig.studio_snapshot(
    "root = maybe\n[*.mbt\nindent_size = 0\n", "main.mbt",
  )
  assert_false(snapshot.contains("\"score\":100"))
  assert_true(snapshot.contains("EC1007"))
}
