///|
pub(all) enum PropertyKind {
  Choice(Array[String])
  Boolean
  PositiveInteger
  PositiveIntegerOrTab
  FreeText
} derive(Debug, Eq)

///|
pub(all) struct PropertySchema {
  name : String
  kind : PropertyKind
  description : String
  standard : Bool
} derive(Debug, Eq)

///|
pub fn standard_property_schemas() -> Array[PropertySchema] {
  [
    {
      name: "indent_style",
      kind: Choice(["tab", "space"]),
      description: "缩进使用制表符或空格",
      standard: true,
    },
    {
      name: "indent_size",
      kind: PositiveIntegerOrTab,
      description: "每级缩进的列数",
      standard: true,
    },
    {
      name: "tab_width",
      kind: PositiveInteger,
      description: "制表符显示宽度",
      standard: true,
    },
    {
      name: "end_of_line",
      kind: Choice(["lf", "crlf", "cr"]),
      description: "换行符格式",
      standard: true,
    },
    {
      name: "charset",
      kind: Choice(["latin1", "utf-8", "utf-8-bom", "utf-16be", "utf-16le"]),
      description: "文件字符编码",
      standard: true,
    },
    {
      name: "trim_trailing_whitespace",
      kind: Boolean,
      description: "是否移除行尾空白",
      standard: true,
    },
    {
      name: "insert_final_newline",
      kind: Boolean,
      description: "是否保证文件末尾换行",
      standard: true,
    },
    {
      name: "max_line_length",
      kind: PositiveInteger,
      description: "建议的最大行宽",
      standard: true,
    },
    {
      name: "root",
      kind: Boolean,
      description: "是否停止搜索父目录",
      standard: true,
    },
  ]
}

///|
pub fn property_schema(name : String) -> PropertySchema? {
  let normalized = lower_ascii(name)
  for schema in standard_property_schemas() {
    if schema.name == normalized {
      return Some(schema)
    }
  }
  None
}

///|
fn is_positive_integer(value : String) -> Bool {
  guard parse_decimal(value) is Some(number) else { return false }
  number > 0
}

///|
fn valid_for_kind(value : String, kind : PropertyKind) -> Bool {
  if lower_ascii(value) == "unset" {
    return true
  }
  match kind {
    Choice(values) => values.any(candidate => candidate == lower_ascii(value))
    Boolean => lower_ascii(value) == "true" || lower_ascii(value) == "false"
    PositiveInteger => is_positive_integer(value)
    PositiveIntegerOrTab =>
      lower_ascii(value) == "tab" || is_positive_integer(value)
    FreeText => value != ""
  }
}

///|
fn expected_description(kind : PropertyKind) -> String {
  match kind {
    Choice(values) => "可选值：" + values.join("、") + "，或 unset"
    Boolean => "可选值：true、false 或 unset"
    PositiveInteger => "应为正整数或 unset"
    PositiveIntegerOrTab => "应为正整数、tab 或 unset"
    FreeText => "值不能为空"
  }
}

///|
fn validate_property(
  property : Property,
  diagnostics : Array[Diagnostic],
) -> Unit {
  match property_schema(property.key) {
    None => ()
    Some(schema) =>
      if !valid_for_kind(property.value, schema.kind) {
        diagnostics.push({
          line: property.source.line,
          severity: Error,
          code: "EC2001",
          message: "属性 `" +
          property.key +
          "` 的值 `" +
          property.value +
          "` 无效",
          hint: expected_description(schema.kind),
          span: property.span,
        })
      }
  }
}

///|
fn validate_cross_properties(
  section : Section,
  diagnostics : Array[Diagnostic],
) -> Unit {
  let mut indent_style : Property? = None
  let mut indent_size : Property? = None
  let mut tab_width : Property? = None
  for property in section.properties {
    match property.key {
      "indent_style" => indent_style = Some(property)
      "indent_size" => indent_size = Some(property)
      "tab_width" => tab_width = Some(property)
      _ => ()
    }
  }
  if indent_style is Some(style) &&
    lower_ascii(style.value) == "tab" &&
    indent_size is None &&
    tab_width is Some(width) {
    diagnostics.push({
      line: width.source.line,
      severity: Information,
      code: "EC2101",
      message: "indent_size 未设置，将继承 tab_width = " + width.value,
      hint: "这是 EditorConfig 的标准派生行为。",
      span: width.span,
    })
  }
}

///|
pub fn validate(config : EditorConfig) -> Array[Diagnostic] {
  let diagnostics : Array[Diagnostic] = []
  for property in config.preamble {
    validate_property(property, diagnostics)
  }
  for section in config.sections {
    let program = compile_glob(section.pattern)
    for issue in program.diagnostics {
      diagnostics.push({
        line: section.source.line,
        severity: Error,
        code: "EC2002",
        message: "无效的 Glob：" + issue,
        hint: "检查字符集合和转义符是否闭合。",
        span: section.span,
      })
    }
    for property in section.properties {
      validate_property(property, diagnostics)
    }
    validate_cross_properties(section, diagnostics)
  }
  diagnostics
}

///|
pub fn has_errors(diagnostics : Array[Diagnostic]) -> Bool {
  diagnostics.any(diagnostic => diagnostic.severity is Error)
}
