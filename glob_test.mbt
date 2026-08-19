///|
test "glob/literal exact matches" {
  assert_true(@MoonEditorConfig.glob_matches("README.md", "README.md"))
  assert_false(@MoonEditorConfig.glob_matches("README.md", "README.mbt.md"))
  assert_true(@MoonEditorConfig.glob_matches("main.mbt", "src/main.mbt"))
}

///|
test "glob/star remains in one segment" {
  assert_true(@MoonEditorConfig.glob_matches("src/*.mbt", "src/main.mbt"))
  assert_false(
    @MoonEditorConfig.glob_matches("src/*.mbt", "src/parser/main.mbt"),
  )
  assert_true(@MoonEditorConfig.glob_matches("*.mbt", "src/parser/main.mbt"))
  assert_false(@MoonEditorConfig.glob_matches("*.mbt", "src/parser/main.md"))
}

///|
test "glob/double star crosses directories" {
  assert_true(@MoonEditorConfig.glob_matches("src/**.mbt", "src/main.mbt"))
  assert_true(
    @MoonEditorConfig.glob_matches("src/**.mbt", "src/parser/main.mbt"),
  )
  assert_true(@MoonEditorConfig.glob_matches("**", "src/parser/main.mbt"))
  assert_false(@MoonEditorConfig.glob_matches("src/**.mbt", "test/main.mbt"))
}

///|
test "glob/question mark matches exactly one non-separator" {
  assert_true(@MoonEditorConfig.glob_matches("file?.mbt", "file1.mbt"))
  assert_true(@MoonEditorConfig.glob_matches("file?.mbt", "filex.mbt"))
  assert_false(@MoonEditorConfig.glob_matches("file?.mbt", "file.mbt"))
  assert_false(@MoonEditorConfig.glob_matches("file?.mbt", "file12.mbt"))
  assert_false(@MoonEditorConfig.glob_matches("src?main", "src/main"))
}

///|
test "glob/positive character class" {
  assert_true(@MoonEditorConfig.glob_matches("file[abc].txt", "filea.txt"))
  assert_true(@MoonEditorConfig.glob_matches("file[abc].txt", "filec.txt"))
  assert_false(@MoonEditorConfig.glob_matches("file[abc].txt", "filed.txt"))
}

///|
test "glob/negative character class" {
  assert_true(@MoonEditorConfig.glob_matches("file[!abc].txt", "filed.txt"))
  assert_false(@MoonEditorConfig.glob_matches("file[!abc].txt", "filea.txt"))
  assert_true(@MoonEditorConfig.glob_matches("[!0-9].mbt", "x.mbt"))
  assert_false(@MoonEditorConfig.glob_matches("[!0-9].mbt", "7.mbt"))
}

///|
test "glob/character ranges" {
  assert_true(@MoonEditorConfig.glob_matches("file[a-z].txt", "filem.txt"))
  assert_true(@MoonEditorConfig.glob_matches("file[0-9].txt", "file5.txt"))
  assert_false(@MoonEditorConfig.glob_matches("file[a-z].txt", "fileM.txt"))
  assert_false(@MoonEditorConfig.glob_matches("file[0-9].txt", "filex.txt"))
}

///|
test "glob/reversed character ranges are accepted" {
  assert_true(@MoonEditorConfig.glob_matches("[z-a].txt", "m.txt"))
  assert_false(@MoonEditorConfig.glob_matches("[z-a].txt", "0.txt"))
}

///|
test "glob/brace alternatives" {
  assert_true(@MoonEditorConfig.glob_matches("*.{mbt,md}", "main.mbt"))
  assert_true(@MoonEditorConfig.glob_matches("*.{mbt,md}", "README.md"))
  assert_false(@MoonEditorConfig.glob_matches("*.{mbt,md}", "main.c"))
  assert_true(@MoonEditorConfig.glob_matches("{src,test}/**.mbt", "test/a.mbt"))
}

///|
test "glob/nested brace alternatives" {
  assert_true(
    @MoonEditorConfig.glob_matches("{src,test}/{main,lib}.mbt", "src/main.mbt"),
  )
  assert_true(
    @MoonEditorConfig.glob_matches("{src,test}/{main,lib}.mbt", "test/lib.mbt"),
  )
  assert_false(
    @MoonEditorConfig.glob_matches("{src,test}/{main,lib}.mbt", "docs/main.mbt"),
  )
}

///|
test "glob/numeric ascending range" {
  for value in [1, 2, 3, 4, 5] {
    assert_true(
      @MoonEditorConfig.glob_matches(
        "file{1..5}.txt",
        "file" + value.to_string() + ".txt",
      ),
    )
  }
  assert_false(@MoonEditorConfig.glob_matches("file{1..5}.txt", "file6.txt"))
}

///|
test "glob/numeric descending range" {
  for value in [5, 4, 3, 2, 1] {
    assert_true(
      @MoonEditorConfig.glob_matches(
        "file{5..1}.txt",
        "file" + value.to_string() + ".txt",
      ),
    )
  }
  assert_false(@MoonEditorConfig.glob_matches("file{5..1}.txt", "file0.txt"))
}

///|
test "glob/numeric negative range" {
  assert_true(@MoonEditorConfig.glob_matches("v{-2..2}.txt", "v-2.txt"))
  assert_true(@MoonEditorConfig.glob_matches("v{-2..2}.txt", "v0.txt"))
  assert_true(@MoonEditorConfig.glob_matches("v{-2..2}.txt", "v2.txt"))
  assert_false(@MoonEditorConfig.glob_matches("v{-2..2}.txt", "v3.txt"))
}

///|
test "glob/path separator normalization" {
  assert_true(@MoonEditorConfig.glob_matches("src/*.mbt", "src\\main.mbt"))
  assert_true(
    @MoonEditorConfig.glob_matches("src/**.mbt", "src\\parser\\main.mbt"),
  )
}

///|
test "glob/dotfiles are ordinary names" {
  assert_true(@MoonEditorConfig.glob_matches("*", ".editorconfig"))
  assert_true(@MoonEditorConfig.glob_matches(".*", ".gitignore"))
  assert_false(@MoonEditorConfig.glob_matches("*.mbt", ".editorconfig"))
}

///|
test "glob/empty pattern and path" {
  assert_true(@MoonEditorConfig.glob_matches("", ""))
  assert_false(@MoonEditorConfig.glob_matches("", "file"))
  assert_true(@MoonEditorConfig.glob_matches("*", ""))
}

///|
test "glob/unclosed class reports diagnostic" {
  let program = @MoonEditorConfig.compile_glob("file[abc.txt")
  assert_eq(program.diagnostics.length(), 1)
  assert_false(program.matches("filea.txt"))
}

///|
test "glob/compiled program is reusable" {
  let program = @MoonEditorConfig.compile_glob("*.{mbt,md}")
  assert_eq(program.diagnostics.length(), 0)
  assert_true(program.matches("main.mbt"))
  assert_true(program.matches("README.md"))
  assert_false(program.matches("main.rs"))
}

///|
test "glob/explanation describes outcome" {
  assert_eq(
    @MoonEditorConfig.explain_glob("*.mbt", "main.mbt"),
    "路径与模式匹配",
  )
  assert_true(
    @MoonEditorConfig.explain_glob("*.mbt", "main.md").contains("不匹配"),
  )
  assert_true(
    @MoonEditorConfig.explain_glob("[broken", "x").contains("模式无效"),
  )
}

///|
test "glob/memoized matcher handles long patterns" {
  let pattern = "a*a*a*a*a*a*a*a*a*a*z"
  let subject = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaay"
  assert_false(@MoonEditorConfig.glob_matches(pattern, subject))
}

///|
test "glob/case remains significant" {
  assert_true(@MoonEditorConfig.glob_matches("*.MBT", "main.MBT"))
  assert_false(@MoonEditorConfig.glob_matches("*.MBT", "main.mbt"))
}
