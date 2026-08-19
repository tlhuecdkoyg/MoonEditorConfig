///|
test "conflicts/different values in one section" {
  let config = @MoonEditorConfig.parse(
      "[*]\nindent_size = 2\nindent_size = 4\n",
    ).config
  let conflicts = @MoonEditorConfig.analyze_conflicts(config)
  assert_eq(conflicts.length(), 1)
  assert_true(
    conflicts[0].kind is @MoonEditorConfig.ConflictKind::DuplicateAssignment,
  )
  assert_eq(conflicts[0].first_value, "2")
  assert_eq(conflicts[0].second_value, "4")
}

///|
test "conflicts/same values in one section" {
  let config = @MoonEditorConfig.parse(
      "[*]\ncharset = utf-8\ncharset = UTF-8\n",
    ).config
  let conflicts = @MoonEditorConfig.analyze_conflicts(config)
  assert_true(
    conflicts[0].kind is @MoonEditorConfig.ConflictKind::RedundantAssignment,
  )
}

///|
test "conflicts/overlapping sections with different values" {
  let config = @MoonEditorConfig.parse(
      "[*.mbt]\nindent_size = 4\n[x.*]\nindent_size = 2\n",
    ).config
  let conflicts = @MoonEditorConfig.analyze_conflicts(config)
  assert_eq(conflicts.length(), 1)
  assert_true(
    conflicts[0].kind is @MoonEditorConfig.ConflictKind::ConflictingSections,
  )
  assert_eq(conflicts[0].witness_path, Some("x.mbt"))
}

///|
test "conflicts/overlapping sections with same values" {
  let config = @MoonEditorConfig.parse(
      "[*.mbt]\nindent_size = 2\n[x.*]\nindent_size = 2\n",
    ).config
  let conflicts = @MoonEditorConfig.analyze_conflicts(config)
  assert_eq(conflicts.length(), 1)
  assert_true(
    conflicts[0].kind is @MoonEditorConfig.ConflictKind::OverlappingSections,
  )
}

///|
test "conflicts/disjoint sections are not reported" {
  let config = @MoonEditorConfig.parse(
      "[*.mbt]\nindent_size = 2\n[*.md]\nindent_size = 4\n",
    ).config
  assert_eq(@MoonEditorConfig.analyze_conflicts(config).length(), 0)
}

///|
test "conflicts/different keys do not conflict" {
  let config = @MoonEditorConfig.parse(
      "[*.mbt]\nindent_size = 2\n[x.*]\ncharset = utf-8\n",
    ).config
  assert_eq(@MoonEditorConfig.analyze_conflicts(config).length(), 0)
}

///|
test "conflicts/count and Chinese rendering" {
  let config = @MoonEditorConfig.parse("[*]\na = 1\na = 2\nb = x\nb = x\n").config
  let conflicts = @MoonEditorConfig.analyze_conflicts(config)
  assert_eq(
    @MoonEditorConfig.conflict_count_by_kind(
      conflicts,
      @MoonEditorConfig.ConflictKind::DuplicateAssignment,
    ),
    1,
  )
  assert_eq(
    @MoonEditorConfig.conflict_count_by_kind(
      conflicts,
      @MoonEditorConfig.ConflictKind::RedundantAssignment,
    ),
    1,
  )
  assert_true(conflicts[0].render_zh().contains("属性"))
  assert_true(conflicts[0].render_zh().contains("第"))
}

///|
test "conflicts/no sections is empty" {
  assert_eq(
    @MoonEditorConfig.analyze_conflicts(
      @MoonEditorConfig.parse("root = true\n").config,
    ).length(),
    0,
  )
}
