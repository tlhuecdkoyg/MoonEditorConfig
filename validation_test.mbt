///|
fn validate_text(source : String) -> Array[@MoonEditorConfig.Diagnostic] {
  @MoonEditorConfig.validate(@MoonEditorConfig.parse(source).config)
}

///|
test "validation/all standard values" {
  let source = "[*]\nindent_style = space\nindent_size = 2\ntab_width = 4\nend_of_line = lf\ncharset = utf-8\ntrim_trailing_whitespace = true\ninsert_final_newline = false\nmax_line_length = 100\n"
  assert_eq(validate_text(source).length(), 0)
}

///|
test "validation/indent style choices" {
  for value in ["tab", "space", "TAB", "SPACE", "unset"] {
    assert_eq(validate_text("[*]\nindent_style = " + value + "\n").length(), 0)
  }
  for value in ["tabs", "spaces", "2", "yes"] {
    let diagnostics = validate_text("[*]\nindent_style = " + value + "\n")
    assert_eq(diagnostics.length(), 1)
    assert_eq(diagnostics[0].code, "EC2001")
  }
}

///|
test "validation/indent size choices" {
  for value in ["1", "2", "4", "8", "tab", "unset"] {
    assert_eq(validate_text("[*]\nindent_size = " + value + "\n").length(), 0)
  }
  for value in ["0", "-1", "space", "2.5"] {
    assert_true(
      @MoonEditorConfig.has_errors(
        validate_text("[*]\nindent_size = " + value + "\n"),
      ),
    )
  }
}

///|
test "validation/tab width must be positive" {
  assert_eq(validate_text("[*]\ntab_width = 1\n").length(), 0)
  assert_eq(validate_text("[*]\ntab_width = 16\n").length(), 0)
  assert_true(
    @MoonEditorConfig.has_errors(validate_text("[*]\ntab_width = 0\n")),
  )
  assert_true(
    @MoonEditorConfig.has_errors(validate_text("[*]\ntab_width = -4\n")),
  )
}

///|
test "validation/end of line choices" {
  for value in ["lf", "cr", "crlf", "LF", "CRLF", "unset"] {
    assert_eq(validate_text("[*]\nend_of_line = " + value + "\n").length(), 0)
  }
  for value in ["unix", "windows", "newline"] {
    assert_true(
      @MoonEditorConfig.has_errors(
        validate_text("[*]\nend_of_line = " + value + "\n"),
      ),
    )
  }
}

///|
test "validation/charset choices" {
  for value in ["latin1", "utf-8", "utf-8-bom", "utf-16be", "utf-16le", "unset"] {
    assert_eq(validate_text("[*]\ncharset = " + value + "\n").length(), 0)
  }
  for value in ["utf8", "utf-32", "ascii", "unicode"] {
    assert_true(
      @MoonEditorConfig.has_errors(
        validate_text("[*]\ncharset = " + value + "\n"),
      ),
    )
  }
}

///|
test "validation/boolean choices" {
  for key in ["trim_trailing_whitespace", "insert_final_newline"] {
    for value in ["true", "false", "TRUE", "FALSE", "unset"] {
      assert_eq(validate_text("[*]\n" + key + " = " + value + "\n").length(), 0)
    }
    for value in ["yes", "no", "1", "0"] {
      assert_true(
        @MoonEditorConfig.has_errors(
          validate_text("[*]\n" + key + " = " + value + "\n"),
        ),
      )
    }
  }
}

///|
test "validation/max line length" {
  for value in ["1", "80", "100", "120", "unset"] {
    assert_eq(
      validate_text("[*]\nmax_line_length = " + value + "\n").length(),
      0,
    )
  }
  for value in ["0", "-80", "none", "off"] {
    assert_true(
      @MoonEditorConfig.has_errors(
        validate_text("[*]\nmax_line_length = " + value + "\n"),
      ),
    )
  }
}

///|
test "validation/custom properties remain extensible" {
  let diagnostics = validate_text(
    "[*]\nide_magic = any value\nformatter_mode = experimental\n",
  )
  assert_eq(diagnostics.length(), 0)
}

///|
test "validation/malformed glob" {
  let diagnostics = validate_text("[file[abc]\nindent_size = 2\n")
  assert_eq(diagnostics.length(), 1)
  assert_eq(diagnostics[0].code, "EC2002")
}

///|
test "validation/tab style relationship emits information" {
  let diagnostics = validate_text("[*]\nindent_style = tab\ntab_width = 4\n")
  assert_eq(diagnostics.length(), 1)
  assert_true(
    diagnostics[0].severity is @MoonEditorConfig.Severity::Information,
  )
  assert_eq(diagnostics[0].code, "EC2101")
  assert_false(@MoonEditorConfig.has_errors(diagnostics))
}

///|
test "validation/property schema lookup" {
  assert_eq(
    @MoonEditorConfig.property_schema("INDENT_SIZE").unwrap().name,
    "indent_size",
  )
  assert_eq(
    @MoonEditorConfig.property_schema("charset").unwrap().description,
    "文件字符编码",
  )
  assert_true(@MoonEditorConfig.property_schema("custom") is None)
  assert_eq(@MoonEditorConfig.standard_property_schemas().length(), 9)
}
