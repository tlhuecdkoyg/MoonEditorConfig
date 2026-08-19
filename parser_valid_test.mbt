///|
test "parser/empty document" {
  let result = @MoonEditorConfig.parse("")
  assert_false(result.config.root)
  assert_eq(result.config.sections.length(), 0)
  assert_eq(result.diagnostics.length(), 0)
}

///|
test "parser/comments and blank lines" {
  let result = @MoonEditorConfig.parse(
    "# comment\n; comment\n\n[*.mbt]\nindent_size = 2\n",
  )
  assert_eq(result.config.sections.length(), 1)
  assert_eq(result.config.sections[0].properties.length(), 1)
  assert_eq(result.diagnostics.length(), 0)
}

///|
test "parser/root true is case insensitive" {
  for value in ["true", "TRUE", "True", "tRuE"] {
    let result = @MoonEditorConfig.parse("root = " + value + "\n")
    assert_true(result.config.root)
  }
}

///|
test "parser/root false is case insensitive" {
  for value in ["false", "FALSE", "False", "fAlSe"] {
    let result = @MoonEditorConfig.parse("root = " + value + "\n")
    assert_false(result.config.root)
    assert_eq(result.diagnostics.length(), 0)
  }
}

///|
test "parser/equals and colon separators" {
  let result = @MoonEditorConfig.parse(
    "[*.mbt]\nindent_size=2\ncharset:utf-8\n",
  )
  let properties = result.config.sections[0].properties
  assert_eq(properties.length(), 2)
  assert_eq(properties[0].key, "indent_size")
  assert_eq(properties[0].value, "2")
  assert_eq(properties[1].key, "charset")
  assert_eq(properties[1].value, "utf-8")
}

///|
test "parser/escaped separator in key and value" {
  let result = @MoonEditorConfig.parse("[*.txt]\ncustom\\=key = left\\=right\n")
  let property = result.config.sections[0].properties[0]
  assert_eq(property.key, "custom=key")
  assert_eq(property.value, "left=right")
}

///|
test "parser/preserves custom property" {
  let result = @MoonEditorConfig.parse("[*]\nij_continuation_indent_size = 4\n")
  let property = result.config.sections[0].properties[0]
  assert_eq(property.key, "ij_continuation_indent_size")
  assert_eq(property.value, "4")
  assert_eq(@MoonEditorConfig.validate(result.config).length(), 0)
}

///|
test "parser/normalizes property key case" {
  let result = @MoonEditorConfig.parse("[*]\nInDeNt_StYlE = space\n")
  let property = result.config.sections[0].properties[0]
  assert_eq(property.key, "indent_style")
  assert_eq(property.raw_key, "InDeNt_StYlE")
}

///|
test "parser/trims surrounding assignment whitespace" {
  let result = @MoonEditorConfig.parse("[*.mbt]\n  indent_size  =  2  \n")
  let property = result.config.sections[0].properties[0]
  assert_eq(property.key, "indent_size")
  assert_eq(property.value, "2")
  assert_eq(property.source.column, 1)
}

///|
test "parser/source path and positions" {
  let result = @MoonEditorConfig.parse_document(
    "/repo/.editorconfig", "root = true\n[*.mbt]\nindent_size = 2\n",
  )
  let property = result.config.sections[0].properties[0]
  assert_eq(result.config.path, "/repo/.editorconfig")
  assert_eq(property.source.file, "/repo/.editorconfig")
  assert_eq(property.source.line, 3)
  assert_eq(property.source.column, 1)
  assert_true(property.source.offset > 0)
}

///|
test "parser/multiple sections preserve order" {
  let result = @MoonEditorConfig.parse(
    "[*.mbt]\na = 1\n[*.md]\nb = 2\n[*]\nc = 3\n",
  )
  assert_eq(result.config.sections.length(), 3)
  assert_eq(result.config.sections[0].pattern, "*.mbt")
  assert_eq(result.config.sections[1].pattern, "*.md")
  assert_eq(result.config.sections[2].pattern, "*")
}

///|
test "parser/section can contain no properties" {
  let result = @MoonEditorConfig.parse("[*.mbt]\n[*.md]\ncharset = utf-8\n")
  assert_eq(result.config.sections.length(), 2)
  assert_eq(result.config.sections[0].properties.length(), 0)
  assert_eq(result.config.sections[1].properties.length(), 1)
}

///|
test "parser/UTF-8 BOM only affects first line" {
  let result = @MoonEditorConfig.parse(
    "\u{FEFF}root = true\n[*.mbt]\ncharset = utf-8\n",
  )
  assert_true(result.config.root)
  assert_eq(result.config.sections.length(), 1)
  assert_eq(result.diagnostics.length(), 0)
}

///|
test "parser/CRLF input" {
  let result = @MoonEditorConfig.parse(
    "root = true\r\n[*.mbt]\r\nindent_size = 2\r\n",
  )
  assert_true(result.config.root)
  assert_eq(result.config.sections[0].properties[0].value, "2")
}

///|
test "parser/options disable colon separator" {
  let defaults = @MoonEditorConfig.ParseOptions::default()
  let result = @MoonEditorConfig.parse_with_options("[*]\ncharset:utf-8\n", {
    ..defaults,
    allow_colon_separator: false,
  })
  assert_eq(result.diagnostics.length(), 1)
  assert_eq(result.diagnostics[0].code, "EC1003")
}

///|
test "parser/options disable duplicate warning" {
  let defaults = @MoonEditorConfig.ParseOptions::default()
  let result = @MoonEditorConfig.parse_with_options("[*]\na = 1\na = 2\n", {
    ..defaults,
    warn_duplicate_keys: false,
  })
  assert_eq(result.diagnostics.length(), 0)
}

///|
test "parser/options disable preamble warning" {
  let defaults = @MoonEditorConfig.ParseOptions::default()
  let result = @MoonEditorConfig.parse_with_options("custom = value\n", {
    ..defaults,
    warn_unknown_preamble: false,
  })
  assert_eq(result.diagnostics.length(), 0)
  assert_eq(result.config.preamble.length(), 1)
}

///|
test "parser/unset is preserved" {
  let result = @MoonEditorConfig.parse("[*]\nindent_size = unset\n")
  assert_eq(result.config.sections[0].properties[0].value, "unset")
  assert_eq(@MoonEditorConfig.validate(result.config).length(), 0)
}
