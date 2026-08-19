///|
test "diff/equal documents produce no changes" {
  assert_eq(@MoonEditorConfig.diff_lines("a\nb\n", "a\nb\n").length(), 2)
  assert_eq(@MoonEditorConfig.diff_hunks("a\nb\n", "a\nb\n").length(), 0)
  assert_eq(@MoonEditorConfig.unified_diff("a\nb\n", "a\nb\n"), "")
}

///|
test "diff/single addition" {
  let lines = @MoonEditorConfig.diff_lines("a\nc\n", "a\nb\nc\n")
  assert_eq(lines.length(), 3)
  assert_true(lines[0].kind is @MoonEditorConfig.DiffKind::Unchanged)
  assert_true(lines[1].kind is @MoonEditorConfig.DiffKind::Added)
  assert_eq(lines[1].new_line, Some(2))
  assert_true(lines[2].kind is @MoonEditorConfig.DiffKind::Unchanged)
}

///|
test "diff/single removal" {
  let lines = @MoonEditorConfig.diff_lines("a\nb\nc\n", "a\nc\n")
  assert_eq(lines.length(), 3)
  assert_true(lines[1].kind is @MoonEditorConfig.DiffKind::Removed)
  assert_eq(lines[1].old_line, Some(2))
  assert_eq(lines[1].new_line, None)
}

///|
test "diff/replacement is remove plus add" {
  let lines = @MoonEditorConfig.diff_lines("a\nold\nc\n", "a\nnew\nc\n")
  assert_eq(lines.length(), 4)
  assert_true(
    lines.any(line => {
      line.kind is @MoonEditorConfig.DiffKind::Removed && line.content == "old"
    }),
  )
  assert_true(
    lines.any(line => {
      line.kind is @MoonEditorConfig.DiffKind::Added && line.content == "new"
    }),
  )
}

///|
test "diff/hunks include configurable context" {
  let before = "one\ntwo\nthree\nfour\nfive\nsix\nseven\n"
  let after = "one\nTWO\nthree\nfour\nfive\nSIX\nseven\n"
  assert_eq(@MoonEditorConfig.diff_hunks(before, after, context=0).length(), 2)
  assert_eq(@MoonEditorConfig.diff_hunks(before, after, context=3).length(), 1)
}

///|
test "diff/unified headers and markers" {
  let output = @MoonEditorConfig.unified_diff(
    "a\nold\n",
    "a\nnew\n",
    old_name="before",
    new_name="after",
  )
  assert_true(output.has_prefix("--- before\n+++ after\n"))
  assert_true(output.contains("-old"))
  assert_true(output.contains("+new"))
  assert_true(output.contains("@@ -"))
}

///|
test "diff/format diff explains canonicalization" {
  let output = @MoonEditorConfig.format_diff(
    "root=true\n[*.mbt]\nindent_size:2\n",
  )
  assert_true(output.contains("-root=true"))
  assert_true(output.contains("+root = true"))
  assert_true(output.contains("+indent_size = 2"))
}

///|
test "diff/empty to content" {
  let lines = @MoonEditorConfig.diff_lines("", "root = true\n")
  assert_eq(lines.length(), 1)
  assert_true(lines[0].kind is @MoonEditorConfig.DiffKind::Added)
}

///|
test "diff/content to empty" {
  let lines = @MoonEditorConfig.diff_lines("root = true\n", "")
  assert_eq(lines.length(), 1)
  assert_true(lines[0].kind is @MoonEditorConfig.DiffKind::Removed)
}
