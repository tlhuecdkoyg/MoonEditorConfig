///|
fn usage() -> String {
  (
    #|MoonEditorConfig - EditorConfig 配置解析与诊断工具
    #|
    #|用法：
    #|  moon run cmd/main -- check <.editorconfig>
    #|
    #|退出码：0 = 没有诊断，1 = 存在诊断，2 = 参数或读取错误
  )
}

///|
fn read_source(path : String) -> String? {
  Some(@fs.read_file_to_string(path)) catch {
    _ => {
      println("错误：无法读取文件 \{path}")
      None
    }
  }
}

///|
fn run_check(path : String) -> Unit {
  guard read_source(path) is Some(source) else {
    @sys.exit(2)
    return
  }
  let result = @lib.parse(source)
  let diagnostics = result.diagnostics.copy()
  for diagnostic in @lib.validate(result.config) {
    diagnostics.push(diagnostic)
  }
  if diagnostics.length() == 0 {
    println("通过：未发现配置诊断")
  } else {
    for diagnostic in diagnostics {
      println("第 \{diagnostic.line} 行：\{diagnostic.message}")
    }
    @sys.exit(1)
  }
}

///|
fn main {
  match @env.args() {
    [_, "check", path] => run_check(path)
    [_, "--help"] | [_, "-h"] => println(usage())
    _ => {
      println(usage())
      @sys.exit(2)
    }
  }
}
