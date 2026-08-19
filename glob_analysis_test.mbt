///|
test "glob analysis/counts structural tokens" {
  let metrics = @MoonEditorConfig.analyze_glob("src/**/file[0-9]?.{mbt,md}")
  assert_true(metrics.literals > 5)
  assert_true(metrics.separators >= 2)
  assert_true(metrics.single_wildcards >= 1)
  assert_true(metrics.recursive_wildcards >= 1)
  assert_true(metrics.character_classes >= 2)
  assert_eq(metrics.alternatives, 2)
  assert_true(metrics.matches_directories)
}

///|
test "glob analysis/literal is more specific than wildcard" {
  let exact = @MoonEditorConfig.glob_specificity("src/main.mbt")
  let broad = @MoonEditorConfig.glob_specificity("src/**")
  assert_true(exact > broad)
  assert_true(
    @MoonEditorConfig.glob_specificity("*.mbt") >
    @MoonEditorConfig.glob_specificity("*"),
  )
}

///|
test "glob analysis/evaluates a path matrix" {
  let cases = @MoonEditorConfig.evaluate_glob("*.mbt", [
    "main.mbt", "README.md", "src/lib.mbt",
  ])
  assert_eq(cases.length(), 3)
  assert_true(cases[0].matched)
  assert_false(cases[1].matched)
  assert_true(cases[2].matched)
  for item in cases {
    assert_true(item.explanation != "")
  }
}

///|
test "glob analysis/generates matching examples" {
  let examples = @MoonEditorConfig.glob_examples("{src,test}/**.mbt")
  assert_true(examples.length() >= 2)
  for example in examples {
    assert_true(@MoonEditorConfig.glob_matches("{src,test}/**.mbt", example))
  }
}

///|
test "glob analysis/finds overlap witness" {
  let witness = @MoonEditorConfig.glob_overlap_witness("*.mbt", "x.*")
  assert_true(witness is Some(_))
  let value = witness.unwrap()
  assert_true(@MoonEditorConfig.glob_matches("*.mbt", value))
  assert_true(@MoonEditorConfig.glob_matches("x.*", value))
}

///|
test "glob analysis/no witness for disjoint extensions" {
  assert_true(@MoonEditorConfig.glob_overlap_witness("*.mbt", "*.md") is None)
}

///|
test "glob analysis/complex pattern warning" {
  let warning = @MoonEditorConfig.glob_complexity_warning(
    "{src,test,examples}/**/*?*?*?*.{mbt,md,json}",
    threshold=50,
  )
  assert_true(warning is Some(_))
  assert_true(warning.unwrap().contains("估算状态数"))
}

///|
test "glob analysis/simple pattern has no warning" {
  assert_true(@MoonEditorConfig.glob_complexity_warning("*.mbt") is None)
}

///|
test "glob analysis/alternatives increase state estimate" {
  let simple = @MoonEditorConfig.analyze_glob("*.mbt")
  let alternatives = @MoonEditorConfig.analyze_glob("*.{mbt,md,json,toml}")
  assert_true(alternatives.estimated_states > simple.estimated_states)
}

///|
test "glob analysis/directory flag" {
  assert_false(@MoonEditorConfig.analyze_glob("*.mbt").matches_directories)
  assert_true(@MoonEditorConfig.analyze_glob("src/*.mbt").matches_directories)
  assert_true(@MoonEditorConfig.analyze_glob("**.mbt").matches_directories)
}
