///|
test "path/normalizes separators" {
  assert_eq(
    @MoonEditorConfig.normalize_path("src\\parser\\main.mbt"),
    "src/parser/main.mbt",
  )
  assert_eq(
    @MoonEditorConfig.normalize_path("C:\\repo\\main.mbt"),
    "C:/repo/main.mbt",
  )
}

///|
test "path/removes dot segments" {
  assert_eq(
    @MoonEditorConfig.normalize_path("./src/./main.mbt"),
    "src/main.mbt",
  )
  assert_eq(
    @MoonEditorConfig.normalize_path("src/lib/../main.mbt"),
    "src/main.mbt",
  )
  assert_eq(
    @MoonEditorConfig.normalize_path("/repo/src/../main.mbt"),
    "/repo/main.mbt",
  )
}

///|
test "path/preserves unresolved parent segments" {
  assert_eq(
    @MoonEditorConfig.normalize_path("../../src/main.mbt"),
    "../../src/main.mbt",
  )
  assert_eq(
    @MoonEditorConfig.normalize_path("../src/../main.mbt"),
    "../main.mbt",
  )
}

///|
test "path/parent paths" {
  assert_eq(
    @MoonEditorConfig.parent_path("/repo/src/main.mbt"),
    Some("/repo/src"),
  )
  assert_eq(@MoonEditorConfig.parent_path("/repo"), Some("/"))
  assert_eq(@MoonEditorConfig.parent_path("main.mbt"), None)
}

///|
test "path/relative path within base" {
  assert_eq(
    @MoonEditorConfig.relative_path("/repo", "/repo/src/main.mbt"),
    Some("src/main.mbt"),
  )
  assert_eq(@MoonEditorConfig.relative_path("/repo", "/repo"), Some(""))
  assert_eq(
    @MoonEditorConfig.relative_path("", "src/main.mbt"),
    Some("src/main.mbt"),
  )
}

///|
test "path/relative rejects sibling prefix collision" {
  assert_eq(
    @MoonEditorConfig.relative_path("/repo", "/repository/main.mbt"),
    None,
  )
  assert_eq(
    @MoonEditorConfig.relative_path("/repo/a", "/repo/b/main.mbt"),
    None,
  )
}
