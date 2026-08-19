///|
pub(all) enum FindingCategory {
  Syntax
  Correctness
  Maintainability
  Portability
  Style
} derive(Debug, Eq)

///|
pub(all) struct Finding {
  code : String
  severity : Severity
  category : FindingCategory
  title : String
  detail : String
  suggestion : String
  span : SourceSpan
} derive(Debug, Eq)

///|
pub(all) struct QualityStats {
  sections : Int
  properties : Int
  standard_properties : Int
  custom_properties : Int
  errors : Int
  warnings : Int
  information : Int
} derive(Debug, Eq)

///|
pub(all) struct QualityReport {
  score : Int
  grade : String
  stats : QualityStats
  findings : Array[Finding]
} derive(Debug, Eq)

///|
fn finding_from_diagnostic(diagnostic : Diagnostic) -> Finding {
  {
    code: diagnostic.code,
    severity: diagnostic.severity,
    category: if diagnostic.severity is Error {
      Syntax
    } else {
      Correctness
    },
    title: diagnostic.message,
    detail: diagnostic.message,
    suggestion: diagnostic.hint,
    span: diagnostic.span,
  }
}

///|
fn push_finding(
  findings : Array[Finding],
  code : String,
  severity : Severity,
  category : FindingCategory,
  title : String,
  detail : String,
  suggestion : String,
  span : SourceSpan,
) -> Unit {
  findings.push({ code, severity, category, title, detail, suggestion, span })
}

///|
fn count_properties(config : EditorConfig) -> Int {
  let mut count = config.preamble.length()
  for section in config.sections {
    count += section.properties.length()
  }
  count
}

///|
fn audit_root(config : EditorConfig, findings : Array[Finding]) -> Unit {
  if !config.root {
    let span = make_span(config.path, 1, 1, 1, 0)
    push_finding(
      findings,
      "EC4001",
      Information,
      Maintainability,
      "未声明 root = true",
      "解析器会继续搜索父目录，最终配置可能受到项目外文件影响。",
      "独立项目通常应在仓库根配置中添加 `root = true`。",
      span,
    )
  }
}

///|
fn audit_empty_sections(
  config : EditorConfig,
  findings : Array[Finding],
) -> Unit {
  for section in config.sections {
    if section.properties.length() == 0 {
      push_finding(
        findings,
        "EC4002",
        Warning,
        Maintainability,
        "空配置节",
        "模式 `[" +
        section.pattern +
        "]` 没有包含任何属性，不会改变配置结果。",
        "删除该节，或补充它应设置的属性。",
        section.span,
      )
    }
  }
}

///|
fn audit_duplicate_patterns(
  config : EditorConfig,
  findings : Array[Finding],
) -> Unit {
  for index, section in config.sections {
    for previous in 0..<index {
      if config.sections[previous].pattern == section.pattern {
        push_finding(
          findings,
          "EC4003",
          Information,
          Maintainability,
          "相同模式分散在多个节中",
          "模式 `[" +
          section.pattern +
          "]` 已在第 " +
          config.sections[previous].source.line.to_string() +
          " 行出现。",
          "如果没有刻意利用覆盖顺序，可以合并这些节以降低维护成本。",
          section.span,
        )
        break
      }
    }
  }
}

///|
fn audit_property_spelling(
  config : EditorConfig,
  findings : Array[Finding],
) -> Unit {
  for section in config.sections {
    for property in section.properties {
      if property.raw_key != lower_ascii(property.raw_key) {
        push_finding(
          findings,
          "EC4004",
          Information,
          Style,
          "属性名建议使用小写",
          "EditorConfig 属性不区分大小写，但统一使用小写更便于搜索和审查。",
          "将 `" + property.raw_key + "` 改为 `" + property.key + "`。",
          property.span,
        )
      }
    }
  }
}

///|
fn audit_encoding(config : EditorConfig, findings : Array[Finding]) -> Unit {
  for section in config.sections {
    for property in section.properties {
      if property.key == "charset" && lower_ascii(property.value) == "utf-8-bom" {
        push_finding(
          findings,
          "EC4005",
          Information,
          Portability,
          "UTF-8 BOM 可能影响部分工具",
          "现代工具通常更适合无 BOM 的 UTF-8；脚本解释器也可能把 BOM 当作内容。",
          "若无兼容性要求，考虑使用 `charset = utf-8`。",
          property.span,
        )
      }
    }
  }
}

///|
fn audit_line_length(config : EditorConfig, findings : Array[Finding]) -> Unit {
  for section in config.sections {
    for property in section.properties {
      if property.key == "max_line_length" &&
        parse_decimal(property.value) is Some(value) &&
        value > 500 {
        push_finding(
          findings,
          "EC4006",
          Warning,
          Maintainability,
          "最大行宽异常大",
          "max_line_length = " +
          property.value +
          " 很可能无法发挥格式约束作用。",
          "确认该数值是否是笔误，或使用更符合团队规范的上限。",
          property.span,
        )
      }
    }
  }
}

///|
fn audit_catch_all(config : EditorConfig, findings : Array[Finding]) -> Unit {
  if config.sections.length() == 0 {
    return
  }
  let covered = config.sections.any(section => {
    section.pattern == "*" || section.pattern == "**"
  })
  if !covered {
    push_finding(
      findings,
      "EC4007",
      Information,
      Maintainability,
      "缺少通用配置节",
      "当前配置只覆盖特定文件模式，新类型文件可能不会获得编码和换行设置。",
      "考虑添加 `[*]` 并放置 charset、end_of_line 等通用属性。",
      config.sections[0].span,
    )
  }
}

///|
fn report_stats(
  config : EditorConfig,
  findings : Array[Finding],
) -> QualityStats {
  let mut standard = 0
  let mut custom = 0
  for section in config.sections {
    for property in section.properties {
      if property_schema(property.key) is Some(_) {
        standard += 1
      } else {
        custom += 1
      }
    }
  }
  let mut errors = 0
  let mut warnings = 0
  let mut information = 0
  for finding in findings {
    match finding.severity {
      Error => errors += 1
      Warning => warnings += 1
      Information => information += 1
    }
  }
  {
    sections: config.sections.length(),
    properties: count_properties(config),
    standard_properties: standard,
    custom_properties: custom,
    errors,
    warnings,
    information,
  }
}

///|
fn quality_grade(score : Int) -> String {
  if score >= 95 {
    "优秀"
  } else if score >= 85 {
    "良好"
  } else if score >= 70 {
    "可用"
  } else if score >= 50 {
    "需改进"
  } else {
    "高风险"
  }
}

///|
/// Perform a static quality audit without changing the source document.
pub fn audit(
  config : EditorConfig,
  initial? : Array[Diagnostic] = [],
) -> QualityReport {
  let findings : Array[Finding] = []
  for diagnostic in initial {
    findings.push(finding_from_diagnostic(diagnostic))
  }
  for diagnostic in validate(config) {
    findings.push(finding_from_diagnostic(diagnostic))
  }
  audit_root(config, findings)
  audit_empty_sections(config, findings)
  audit_duplicate_patterns(config, findings)
  audit_property_spelling(config, findings)
  audit_encoding(config, findings)
  audit_line_length(config, findings)
  audit_catch_all(config, findings)
  let stats = report_stats(config, findings)
  let score = (100 -
  stats.errors * 22 -
  stats.warnings * 8 -
  stats.information * 2).clamp(min=0, max=100)
  { score, grade: quality_grade(score), stats, findings }
}

///|
pub fn QualityReport::has_blockers(self : QualityReport) -> Bool {
  self.stats.errors > 0
}

///|
pub fn QualityReport::summary_zh(self : QualityReport) -> String {
  "质量评分 " +
  self.score.to_string() +
  "/100（" +
  self.grade +
  "）；" +
  self.stats.errors.to_string() +
  " 个错误，" +
  self.stats.warnings.to_string() +
  " 个警告，" +
  self.stats.information.to_string() +
  " 个提示。"
}
