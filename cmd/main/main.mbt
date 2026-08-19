///|
fn usage() -> String {
  (
    #|MoonEditorConfig - EditorConfig 解析、验证与来源追踪工具
    #|
    #|用法：
    #|  moon run cmd/main -- check <.editorconfig>
    #|  moon run cmd/main -- resolve <目标文件> [--json]
    #|  moon run cmd/main -- explain <目标文件>
    #|  moon run cmd/main -- query <目标文件> <属性名>
    #|  moon run cmd/main -- match <glob> <相对路径>
    #|  moon run cmd/main -- format <.editorconfig> [--write]
    #|  moon run cmd/main -- audit <.editorconfig>
    #|  moon run cmd/main -- diff <.editorconfig>
    #|  moon run cmd/main -- conflicts <.editorconfig>
    #|
    #|退出码：0 = 成功，1 = 发现错误或未匹配，2 = 参数/文件错误
  )
}

///|
fn fail_usage(message : String) -> Unit {
  println("错误：" + message)
  println("")
  println(usage())
  @sys.exit(2)
}

///|
fn read_source(path : String) -> String? {
  Some(@fs.read_file_to_string(path)) catch {
    _ => {
      println("错误：无法读取文件 " + path)
      None
    }
  }
}

///|
fn absolute_path(path : String) -> String {
  let normalized = @lib.normalize_path(path)
  let windows_absolute = normalized.length() >= 3 &&
    normalized[1] == ':' &&
    normalized[2] == '/'
  if normalized.has_prefix("/") || windows_absolute {
    normalized
  } else {
    match @env.current_dir() {
      Some(directory) => @lib.normalize_path(directory + "/" + normalized)
      None => normalized
    }
  }
}

///|
fn config_path(directory : String) -> String {
  if directory.has_suffix("/") {
    directory + ".editorconfig"
  } else {
    directory + "/.editorconfig"
  }
}

///|
fn target_directory(target : String) -> String {
  match @lib.parent_path(target) {
    Some(directory) => directory
    None => absolute_path(".")
  }
}

///|
fn discover_layers(
  target : String,
) -> (Array[@lib.ConfigLayer], Array[@lib.Diagnostic]) {
  let layers : Array[@lib.ConfigLayer] = []
  let diagnostics : Array[@lib.Diagnostic] = []
  let mut directory = target_directory(target)
  let mut finished = false
  while !finished {
    let candidate = config_path(directory)
    if @fs.path_exists(candidate) {
      match read_source(candidate) {
        Some(source) => {
          let parsed = @lib.parse_document(candidate, source)
          layers.push({ path: candidate, directory, config: parsed.config })
          for diagnostic in parsed.diagnostics {
            diagnostics.push(diagnostic)
          }
          if parsed.config.root {
            finished = true
          }
        }
        None => ()
      }
    }
    if !finished {
      match @lib.parent_path(directory) {
        Some(parent) if parent != directory => directory = parent
        _ => finished = true
      }
    }
  }
  (layers, diagnostics)
}

///|
fn resolve_target(path : String) -> @lib.Resolution {
  let target = absolute_path(path)
  let (layers, parse_diagnostics) = discover_layers(target)
  let resolution = @lib.resolve_layers(layers, target)
  for diagnostic in parse_diagnostics {
    resolution.diagnostics.push(diagnostic)
  }
  resolution
}

///|
fn run_check(path : String) -> Unit {
  guard read_source(path) is Some(source) else {
    @sys.exit(2)
    return
  }
  let result = @lib.parse_document(absolute_path(path), source)
  let diagnostics = result.diagnostics.copy()
  for diagnostic in @lib.validate(result.config) {
    diagnostics.push(diagnostic)
  }
  if diagnostics.length() == 0 {
    println("通过：" + @lib.summarize(result.config))
  } else {
    for diagnostic in diagnostics {
      println(diagnostic.render_zh())
    }
    if @lib.has_errors(diagnostics) {
      @sys.exit(1)
    }
  }
}

///|
fn render_properties(resolution : @lib.Resolution) -> Unit {
  if resolution.properties.length() == 0 {
    println("未找到适用于目标文件的配置。")
    return
  }
  println("目标文件：" + resolution.target)
  println("最终配置：")
  for property in resolution.properties {
    println("  " + property.key + " = " + property.value)
  }
}

///|
fn run_resolve(path : String, json : Bool) -> Unit {
  let resolution = resolve_target(path)
  if json {
    println(resolution.to_json(indent=true))
  } else {
    render_properties(resolution)
  }
  if @lib.has_errors(resolution.diagnostics) {
    @sys.exit(1)
  }
}

///|
fn run_explain(path : String) -> Unit {
  let resolution = resolve_target(path)
  println(resolution.explain_zh())
  if @lib.has_errors(resolution.diagnostics) {
    @sys.exit(1)
  }
}

///|
fn run_query(path : String, key : String) -> Unit {
  let resolution = resolve_target(path)
  match resolution.get(key) {
    Some(property) => {
      println(property.value)
      println(
        "来源：" +
        property.config_path +
        ":" +
        property.source.line.to_string() +
        " [" +
        property.pattern +
        "]",
      )
    }
    None => {
      println("未解析到属性：" + key)
      @sys.exit(1)
    }
  }
}

///|
fn run_match(pattern : String, path : String) -> Unit {
  let program = @lib.compile_glob(pattern)
  if program.diagnostics.length() > 0 {
    println("Glob 无效：" + program.diagnostics.join("；"))
    @sys.exit(2)
    return
  }
  if @lib.glob_matches(pattern, path) {
    println("匹配：" + @lib.explain_glob(pattern, path))
  } else {
    println("不匹配：" + @lib.explain_glob(pattern, path))
    @sys.exit(1)
  }
}

///|
fn run_format(path : String, write : Bool) -> Unit {
  guard read_source(path) is Some(source) else {
    @sys.exit(2)
    return
  }
  let parsed = @lib.parse_document(absolute_path(path), source)
  if @lib.has_errors(parsed.diagnostics) {
    for diagnostic in parsed.diagnostics {
      println(diagnostic.render_zh())
    }
    @sys.exit(1)
    return
  }
  let formatted = @lib.format_config(parsed.config)
  if write {
    try @fs.write_string_to_file(path, formatted) catch {
      _ => {
        println("错误：无法写入文件 " + path)
        @sys.exit(2)
      }
    } noraise {
      _ => println("已格式化：" + path)
    }
  } else {
    println(formatted)
  }
}

///|
fn parsed_file(path : String) -> @lib.ParseResult? {
  match read_source(path) {
    Some(source) => Some(@lib.parse_document(absolute_path(path), source))
    None => None
  }
}

///|
fn run_audit(path : String) -> Unit {
  guard parsed_file(path) is Some(parsed) else {
    @sys.exit(2)
    return
  }
  let report = @lib.audit(parsed.config, initial=parsed.diagnostics)
  println(report.summary_zh())
  for finding in report.findings {
    println("  [" + finding.code + "] " + finding.title)
    println("    " + finding.detail)
    println("    建议：" + finding.suggestion)
  }
  if report.has_blockers() {
    @sys.exit(1)
  }
}

///|
fn run_diff(path : String) -> Unit {
  guard read_source(path) is Some(source) else {
    @sys.exit(2)
    return
  }
  let diff = @lib.format_diff(source)
  if diff == "" {
    println("配置已经符合规范格式。")
  } else {
    println(diff)
  }
}

///|
fn run_conflicts(path : String) -> Unit {
  guard parsed_file(path) is Some(parsed) else {
    @sys.exit(2)
    return
  }
  let conflicts = @lib.analyze_conflicts(parsed.config)
  if conflicts.length() == 0 {
    println("未发现可证明的配置覆盖冲突。")
  } else {
    println(
      "发现 " + conflicts.length().to_string() + " 项配置覆盖关系：",
    )
    for conflict in conflicts {
      println("  " + conflict.render_zh())
    }
  }
}

///|
fn main {
  match @env.args() {
    [_, "check", path] => run_check(path)
    [_, "resolve", path] => run_resolve(path, false)
    [_, "resolve", path, "--json"] => run_resolve(path, true)
    [_, "explain", path] => run_explain(path)
    [_, "query", path, key] => run_query(path, key)
    [_, "match", pattern, path] => run_match(pattern, path)
    [_, "format", path] => run_format(path, false)
    [_, "format", path, "--write"] => run_format(path, true)
    [_, "audit", path] => run_audit(path)
    [_, "diff", path] => run_diff(path)
    [_, "conflicts", path] => run_conflicts(path)
    [_, "--help"] | [_, "-h"] => println(usage())
    _ => fail_usage("参数不完整或命令未知")
  }
}
