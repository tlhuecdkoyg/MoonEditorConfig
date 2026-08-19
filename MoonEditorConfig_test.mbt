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
