///|
fn audit_text(source : String) -> @MoonEditorConfig.QualityReport {
  let parsed = @MoonEditorConfig.parse_document("/.editorconfig", source)
  @MoonEditorConfig.audit(parsed.config, initial=parsed.diagnostics)
}

///|
test "quality/healthy project scores 100" {
  let report = audit_text(
    "root = true\n[*]\ncharset = utf-8\nend_of_line = lf\n[*.mbt]\nindent_size = 2\n",
  )
  assert_eq(report.score, 100)
  assert_eq(report.grade, "优秀")
  assert_eq(report.findings.length(), 0)
  assert_false(report.has_blockers())
}

///|
test "quality/missing root emits information" {
  let report = audit_text("[*]\ncharset = utf-8\n")
  assert_eq(report.findings.length(), 1)
  assert_eq(report.findings[0].code, "EC4001")
  assert_eq(report.stats.information, 1)
}

///|
test "quality/empty section emits warning" {
  let report = audit_text("root = true\n[*]\n[*.mbt]\nindent_size = 2\n")
  assert_true(report.findings.any(finding => finding.code == "EC4002"))
  assert_eq(report.stats.warnings, 1)
}

///|
test "quality/duplicate patterns emit maintainability hint" {
  let report = audit_text(
    "root = true\n[*]\ncharset = utf-8\n[*.mbt]\nindent_size = 2\n[*.mbt]\ntab_width = 2\n",
  )
  assert_true(report.findings.any(finding => finding.code == "EC4003"))
}

///|
test "quality/mixed-case property emits style hint" {
  let report = audit_text("root = true\n[*]\nCharset = utf-8\n")
  assert_true(report.findings.any(finding => finding.code == "EC4004"))
}

///|
test "quality/UTF-8 BOM emits portability hint" {
  let report = audit_text("root = true\n[*]\ncharset = utf-8-bom\n")
  assert_true(report.findings.any(finding => finding.code == "EC4005"))
  assert_eq(report.stats.information, 1)
}

///|
test "quality/extreme line length emits warning" {
  let report = audit_text("root = true\n[*]\nmax_line_length = 1000\n")
  assert_true(report.findings.any(finding => finding.code == "EC4006"))
  assert_eq(report.stats.warnings, 1)
}

///|
test "quality/missing catch-all emits hint" {
  let report = audit_text("root = true\n[*.mbt]\nindent_size = 2\n")
  assert_true(report.findings.any(finding => finding.code == "EC4007"))
}

///|
test "quality/custom properties counted separately" {
  let report = audit_text(
    "root = true\n[*]\ncharset = utf-8\nide_flag = enabled\n",
  )
  assert_eq(report.stats.standard_properties, 1)
  assert_eq(report.stats.custom_properties, 1)
  assert_eq(report.stats.properties, 3)
}

///|
test "quality/parser and semantic errors are blockers" {
  let report = audit_text("root = maybe\n[*]\nindent_size = 0\n")
  assert_true(report.has_blockers())
  assert_true(report.stats.errors >= 2)
  assert_true(report.score < 60)
}

///|
test "quality/summary is Chinese and complete" {
  let summary = audit_text("[*]\nindent_size = 0\n").summary_zh()
  assert_true(summary.contains("质量评分"))
  assert_true(summary.contains("错误"))
  assert_true(summary.contains("警告"))
  assert_true(summary.contains("提示"))
}

///|
test "quality/grades follow thresholds" {
  assert_eq(audit_text("root = true\n[*]\ncharset = utf-8\n").grade, "优秀")
  let weak = audit_text("broken\n[*]\nindent_size = 0\ncharset = utf32\n")
  assert_true(weak.grade == "需改进" || weak.grade == "高风险")
}
