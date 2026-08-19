///|
test "parse sections and source locations" {
  let result = @MoonEditorConfig.parse(
    "root = true\n\n[*.mbt]\nindent_style = space\nindent_size = 2\n",
  )
  assert_true(result.config.root)
  assert_eq(result.config.sections.length(), 1)
  assert_eq(result.config.sections[0].pattern, "*.mbt")
  assert_eq(result.config.sections[0].properties[0].key, "indent_style")
  assert_eq(result.config.sections[0].properties[0].source.line, 4)
  assert_eq(result.diagnostics.length(), 0)
}

///|
test "parse invalid lines as diagnostics" {
  let result = @MoonEditorConfig.parse("[*.mbt]\ninvalid line\n")
  assert_eq(result.diagnostics.length(), 1)
  assert_eq(result.diagnostics[0].line, 2)
}

///|
test "match basic EditorConfig globs" {
  assert_true(@MoonEditorConfig.glob_matches("*.mbt", "parser.mbt"))
  assert_true(@MoonEditorConfig.glob_matches("src/??.mbt", "src/io.mbt"))
  assert_false(@MoonEditorConfig.glob_matches("*.mbt", "README.md"))
  assert_false(@MoonEditorConfig.glob_matches("src/*.mbt", "test/io.mbt"))
}

///|
test "resolve later matching sections over earlier values" {
  let result = @MoonEditorConfig.parse(
    "[*.mbt]\nindent_size = 2\nindent_style = space\n[src/*.mbt]\nindent_size = 4\n",
  )
  let resolved = @MoonEditorConfig.resolve(result.config, "src/main.mbt")
  assert_eq(resolved.length(), 2)
  assert_eq(resolved[0].key, "indent_size")
  assert_eq(resolved[0].value, "4")
  assert_eq(resolved[0].source.line, 5)
  assert_eq(resolved[0].pattern, "src/*.mbt")
}
