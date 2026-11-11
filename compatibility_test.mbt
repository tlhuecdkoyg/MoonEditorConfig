///|
test "migration preserves callable derived equality and debug methods" {
  let parsed = @MoonEditorConfig.parse("[*.mbt]\nindent_size = 2\n")
  let changed = @MoonEditorConfig.parse("[*.mbt]\nindent_size = 4\n")
  assert_true(parsed.equal(parsed))
  assert_false(parsed.not_equal(parsed))
  assert_true(parsed.not_equal(changed))
  assert_true(parsed.config.equal(parsed.config))
  assert_true(parsed.config.sections[0].equal(parsed.config.sections[0]))
  ignore(parsed.to_repr())
  ignore(parsed.config.to_repr())
  ignore(parsed.config.sections[0].to_repr())
}

///|
test "Studio snapshot remains valid JSON with Unicode source" {
  let snapshot = @MoonEditorConfig.studio_snapshot(
    "root = true\n[*.mbt]\nindent_size = 2\ncustom_label = 模型🚀\n", "src/main.mbt",
  )
  ignore(@json.parse(snapshot))
  assert_true(snapshot.contains("\"matchedSections\":1"))
  assert_true(snapshot.contains("模型🚀"))
}
