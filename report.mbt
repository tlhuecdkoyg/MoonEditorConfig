///|
pub fn Severity::label_zh(self : Severity) -> String {
  match self {
    Error => "错误"
    Warning => "警告"
    Information => "提示"
  }
}

///|
pub fn Diagnostic::render_zh(self : Diagnostic) -> String {
  let location = if self.span.start.file == "<memory>" {
    "第 " + self.line.to_string() + " 行"
  } else {
    self.span.start.file +
    ":" +
    self.line.to_string() +
    ":" +
    self.span.start.column.to_string()
  }
  let base = location +
    " [" +
    self.code +
    "] " +
    self.severity.label_zh() +
    "：" +
    self.message
  if self.hint == "" {
    base
  } else {
    base + "\n  建议：" + self.hint
  }
}

///|
pub fn Resolution::explain_zh(self : Resolution) -> String {
  let output = StringBuilder::new()
  output.write_string("目标文件：" + self.target + "\n\n")
  output.write_string(
    "最终配置（" + self.properties.length().to_string() + " 项）\n",
  )
  if self.properties.length() == 0 {
    output.write_string("  没有匹配的配置属性\n")
  }
  for property in self.properties {
    output.write_string("  " + property.key + " = " + property.value + "\n")
    for step in property.history {
      output.write_string(
        "    ← " +
        step.config_path +
        ":" +
        step.line.to_string() +
        " [" +
        step.pattern +
        "] " +
        step.action +
        " `" +
        step.value +
        "`\n",
      )
    }
  }
  output.write_string(
    "\n配置段匹配过程（" +
    self.sections.length().to_string() +
    " 项）\n",
  )
  for trace in self.sections {
    let marker = if trace.matched { "✓" } else { "·" }
    output.write_string(
      "  " +
      marker +
      " " +
      trace.config_path +
      ":" +
      trace.line.to_string() +
      " [" +
      trace.pattern +
      "]\n",
    )
    output.write_string("    " + trace.reason + "\n")
  }
  if self.diagnostics.length() > 0 {
    output.write_string(
      "\n诊断（" + self.diagnostics.length().to_string() + " 项）\n",
    )
    for diagnostic in self.diagnostics {
      output.write_string("  " + diagnostic.render_zh() + "\n")
    }
  }
  output.to_string()
}

///|
pub fn summarize(config : EditorConfig) -> String {
  let property_count = config.preamble.length() +
    config.sections.fold(init=0, (count, section) => {
      count + section.properties.length()
    })
  "配置文件包含 " +
  config.sections.length().to_string() +
  " 个节、" +
  property_count.to_string() +
  " 个属性，root = " +
  bool_text(config.root)
}
