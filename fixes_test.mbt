///|
test "fixes/canonical formatting is safe" {
  let source = "root=true\n[*]\nindent_size:2\n"
  let plan = @MoonEditorConfig.plan_fixes(source)
  assert_eq(plan.safe_count, 1)
  assert_eq(plan.review_count, 0)
  assert_eq(plan.safe_source, "root = true\n\n[*]\nindent_size = 2\n")
  assert_true(plan.diff.contains("-root=true"))
  assert_true(plan.diff.contains("+root = true"))
}

///|
test "fixes/already formatted source has no safe edit" {
  let source = "root = true\n\n[*]\nindent_size = 2\n"
  let plan = @MoonEditorConfig.plan_fixes(source)
  assert_eq(plan.safe_count, 0)
  assert_eq(plan.safe_source, source)
  assert_eq(plan.diff, "")
}

///|
test "fixes/missing root requires review" {
  let plan = @MoonEditorConfig.plan_fixes("[*]\nindent_size = 2\n")
  assert_true(plan.review_count >= 1)
  assert_true(
    plan.edits.any(edit => edit.title.contains("搜索根") && !edit.safe),
  )
}

///|
test "fixes/UTF-8 BOM replacement requires review" {
  let plan = @MoonEditorConfig.plan_fixes(
    "root = true\n\n[*]\ncharset = utf-8-bom\n",
  )
  assert_true(
    plan.edits.any(edit => edit.title.contains("无 BOM") && !edit.safe),
  )
}

///|
test "fixes/applies insertion replacement and deletion" {
  let edits : Array[@MoonEditorConfig.TextEdit] = [
    {
      start_offset: 0,
      end_offset: 0,
      replacement: "A",
      title: "insert",
      safe: true,
    },
    {
      start_offset: 1,
      end_offset: 3,
      replacement: "X",
      title: "replace",
      safe: true,
    },
    {
      start_offset: 4,
      end_offset: 5,
      replacement: "",
      title: "delete",
      safe: true,
    },
  ]
  assert_eq(@MoonEditorConfig.validate_edits(edits, 5).length(), 0)
  assert_eq(@MoonEditorConfig.apply_edits("12345", edits), "A1X4")
}

///|
test "fixes/rejects out of range edits" {
  let edits : Array[@MoonEditorConfig.TextEdit] = [
    {
      start_offset: -1,
      end_offset: 2,
      replacement: "",
      title: "negative",
      safe: true,
    },
    {
      start_offset: 3,
      end_offset: 9,
      replacement: "",
      title: "too far",
      safe: true,
    },
  ]
  assert_eq(@MoonEditorConfig.validate_edits(edits, 5).length(), 2)
}

///|
test "fixes/rejects reversed range" {
  let edits : Array[@MoonEditorConfig.TextEdit] = [
    {
      start_offset: 4,
      end_offset: 2,
      replacement: "",
      title: "reversed",
      safe: true,
    },
  ]
  assert_eq(@MoonEditorConfig.validate_edits(edits, 5).length(), 1)
}

///|
test "fixes/rejects overlapping edits" {
  let edits : Array[@MoonEditorConfig.TextEdit] = [
    {
      start_offset: 1,
      end_offset: 4,
      replacement: "A",
      title: "first",
      safe: true,
    },
    {
      start_offset: 3,
      end_offset: 5,
      replacement: "B",
      title: "second",
      safe: true,
    },
  ]
  let errors = @MoonEditorConfig.validate_edits(edits, 6)
  assert_eq(errors.length(), 1)
  assert_true(errors[0].contains("重叠"))
}

///|
test "fixes/adjacent edits do not overlap" {
  let edits : Array[@MoonEditorConfig.TextEdit] = [
    {
      start_offset: 0,
      end_offset: 2,
      replacement: "A",
      title: "first",
      safe: true,
    },
    {
      start_offset: 2,
      end_offset: 4,
      replacement: "B",
      title: "second",
      safe: true,
    },
  ]
  assert_eq(@MoonEditorConfig.validate_edits(edits, 4).length(), 0)
  assert_eq(@MoonEditorConfig.apply_edits("1234", edits), "AB")
}

///|
test "fixes/insertion edits at same point are valid" {
  let edits : Array[@MoonEditorConfig.TextEdit] = [
    {
      start_offset: 0,
      end_offset: 0,
      replacement: "A",
      title: "first",
      safe: true,
    },
    {
      start_offset: 2,
      end_offset: 2,
      replacement: "B",
      title: "second",
      safe: true,
    },
  ]
  assert_eq(@MoonEditorConfig.validate_edits(edits, 2).length(), 0)
  assert_eq(@MoonEditorConfig.apply_edits("12", edits), "A12B")
}
