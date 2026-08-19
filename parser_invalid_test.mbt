///|
test "parser invalid/missing closing bracket" {
  let result = @MoonEditorConfig.parse("[*.mbt\nindent_size = 2\n")
  assert_eq(result.diagnostics.length(), 2)
  assert_eq(result.diagnostics[0].code, "EC1001")
  assert_eq(result.diagnostics[0].line, 1)
}

///|
test "parser invalid/empty section" {
  let result = @MoonEditorConfig.parse("[]\nindent_size = 2\n")
  assert_eq(result.diagnostics[0].code, "EC1002")
  assert_eq(result.config.sections.length(), 0)
}

///|
test "parser invalid/no separator" {
  let result = @MoonEditorConfig.parse("[*]\nindent_size 2\n")
  assert_eq(result.diagnostics.length(), 1)
  assert_eq(result.diagnostics[0].code, "EC1003")
  assert_true(result.diagnostics[0].hint != "")
}

///|
test "parser invalid/empty key" {
  let result = @MoonEditorConfig.parse("[*]\n = value\n")
  assert_eq(result.diagnostics[0].code, "EC1004")
  assert_eq(result.config.sections[0].properties.length(), 0)
}

///|
test "parser invalid/empty value retained with warning" {
  let result = @MoonEditorConfig.parse("[*]\nindent_size =   \n")
  assert_eq(result.diagnostics[0].code, "EC1005")
  assert_true(
    result.diagnostics[0].severity is @MoonEditorConfig.Severity::Warning,
  )
  assert_eq(result.config.sections[0].properties[0].value, "")
}

///|
test "parser invalid/duplicate key warns and retains both" {
  let result = @MoonEditorConfig.parse(
    "[*]\nindent_size = 2\nindent_size = 4\n",
  )
  assert_eq(result.diagnostics.length(), 1)
  assert_eq(result.diagnostics[0].code, "EC1006")
  assert_eq(result.config.sections[0].properties.length(), 2)
}

///|
test "parser invalid/root invalid value" {
  for value in ["yes", "1", "maybe", "unset", ""] {
    let result = @MoonEditorConfig.parse("root = " + value + "\n")
    assert_false(result.config.root)
    assert_true(result.diagnostics.length() >= 1)
  }
}

///|
test "parser invalid/property before section warns" {
  let result = @MoonEditorConfig.parse(
    "indent_size = 2\n[*]\ncharset = utf-8\n",
  )
  assert_eq(result.diagnostics[0].code, "EC1008")
  assert_eq(result.config.preamble.length(), 1)
}

///|
test "parser invalid/recovers after malformed lines" {
  let result = @MoonEditorConfig.parse(
    "broken\n[*.mbt\n[*.md]\ncharset = utf-8\n",
  )
  assert_eq(result.diagnostics.length(), 2)
  assert_eq(result.config.sections.length(), 1)
  assert_eq(result.config.sections[0].pattern, "*.md")
}

///|
test "parser invalid/diagnostic spans point to supplied file" {
  let result = @MoonEditorConfig.parse_document(
    "/work/.editorconfig", "broken\n",
  )
  let diagnostic = result.diagnostics[0]
  assert_eq(diagnostic.span.start.file, "/work/.editorconfig")
  assert_eq(diagnostic.span.start.line, 1)
  assert_eq(diagnostic.span.start.column, 1)
  assert_true(diagnostic.span.end.column > diagnostic.span.start.column)
}
