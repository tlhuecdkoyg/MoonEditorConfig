///|
test "glob regression/leading slash preserves directory anchoring" {
  assert_true(@MoonEditorConfig.glob_matches("/src/*.mbt", "src/main.mbt"))
  assert_false(
    @MoonEditorConfig.glob_matches("/src/*.mbt", "test/src/main.mbt"),
  )
  assert_true(@MoonEditorConfig.glob_matches("/*.mbt", "main.mbt"))
  assert_false(@MoonEditorConfig.glob_matches("/*.mbt", "src/main.mbt"))
  let program = @MoonEditorConfig.compile_glob("/src/*.mbt")
  assert_eq(program.source, "/src/*.mbt")
  assert_true(program.matches("src/main.mbt"))
}

///|
test "glob regression/escaped filename matches below the configuration directory" {
  assert_true(
    @MoonEditorConfig.glob_matches("literal\\*.txt", "src/literal*.txt"),
  )
  assert_true(
    @MoonEditorConfig.glob_matches("literal\\?.txt", "src/literal?.txt"),
  )
  assert_true(
    @MoonEditorConfig.glob_matches("literal\\[.txt", "src/literal[.txt"),
  )
  assert_false(
    @MoonEditorConfig.glob_matches("literal\\*.txt", "src/literal1.txt"),
  )
  assert_false(
    @MoonEditorConfig.glob_matches("src/literal\\*.txt", "test/literal*.txt"),
  )
}

///|
test "glob regression/numeric ranges do not wrap through Int32" {
  let pattern = "v{4294967296..4294967297}.txt"
  assert_true(@MoonEditorConfig.glob_matches(pattern, "v4294967296.txt"))
  assert_true(@MoonEditorConfig.glob_matches(pattern, "v4294967297.txt"))
  assert_false(@MoonEditorConfig.glob_matches(pattern, "v0.txt"))
  assert_false(@MoonEditorConfig.glob_matches(pattern, "v1.txt"))
  assert_true(
    @MoonEditorConfig.glob_matches(
      "v{-4294967297..-4294967296}", "v-4294967297",
    ),
  )
}

///|
test "glob regression/Int64 endpoints terminate in both directions" {
  for
    pattern in [
      "{9223372036854775806..9223372036854775807}", "{9223372036854775807..9223372036854775806}",
    ] {
    assert_true(@MoonEditorConfig.glob_matches(pattern, "9223372036854775806"))
    assert_true(@MoonEditorConfig.glob_matches(pattern, "9223372036854775807"))
    assert_false(
      @MoonEditorConfig.glob_matches(pattern, "-9223372036854775808"),
    )
  }
  for
    pattern in [
      "{-9223372036854775808..-9223372036854775807}", "{-9223372036854775807..-9223372036854775808}",
    ] {
    assert_true(@MoonEditorConfig.glob_matches(pattern, "-9223372036854775808"))
    assert_true(@MoonEditorConfig.glob_matches(pattern, "-9223372036854775807"))
    assert_false(@MoonEditorConfig.glob_matches(pattern, "9223372036854775807"))
  }
}

///|
test "glob regression/out of Int64 numeric ranges remain literal" {
  for
    pattern in [
      "{9223372036854775807..9223372036854775808}", "{-9223372036854775809..-9223372036854775808}",
      "{18446744073709551616..18446744073709551617}",
    ] {
    assert_false(@MoonEditorConfig.glob_matches(pattern, "0"))
    assert_false(@MoonEditorConfig.glob_matches(pattern, "-1"))
    assert_true(@MoonEditorConfig.glob_matches(pattern, pattern))
  }
}

///|
test "glob regression/numeric range span limit is bounded without endpoint subtraction" {
  assert_true(@MoonEditorConfig.glob_matches("{0..1000}", "1000"))
  assert_true(@MoonEditorConfig.glob_matches("{1000..0}", "0"))
  assert_false(@MoonEditorConfig.glob_matches("{0..1001}", "0"))
  assert_false(@MoonEditorConfig.glob_matches("{1001..0}", "1001"))
  for
    pattern in [
      "{-2147483648..0}", "{2147483647..-2147483648}", "{-9223372036854775808..9223372036854775807}",
      "{9223372036854775807..-9223372036854775808}",
    ] {
    assert_false(@MoonEditorConfig.glob_matches(pattern, "0"))
    assert_true(@MoonEditorConfig.glob_matches(pattern, pattern))
  }
}

///|
test "glob regression/character classes do not expand braces" {
  for literal in ["a", "b", "*", "c", "{", "1", ".", "2", "}"] {
    assert_true(
      @MoonEditorConfig.glob_matches(
        "file[ab*c{1..2}].txt",
        "file" + literal + ".txt",
      ),
    )
  }
  assert_false(
    @MoonEditorConfig.glob_matches("file[ab*c{1..2}].txt", "file3.txt"),
  )
  assert_true(@MoonEditorConfig.glob_matches("[!{1..2}]", "x"))
  assert_false(@MoonEditorConfig.glob_matches("[!{1..2}]", "{"))
  for literal in ["]", "{", "}"] {
    assert_true(@MoonEditorConfig.glob_matches("[]{}]", literal))
  }
}

///|
test "glob regression/brace alternatives respect whole character classes" {
  for literal in ["{", "}", ",", "x"] {
    assert_true(@MoonEditorConfig.glob_matches("{[{},],x}", literal))
  }
  assert_false(@MoonEditorConfig.glob_matches("{[{},],x}", "y"))
  assert_true(@MoonEditorConfig.glob_matches("\\[v{1..2}", "[v1"))
  assert_true(@MoonEditorConfig.glob_matches("\\[v{1..2}", "[v2"))
}
