# MoonEditorConfig

MoonEditorConfig 是使用 MoonBit 编写的 EditorConfig 解析、验证、配置解析与
来源追踪工具。它既可以作为 MoonBit 库使用，也提供中文 CLI 和完全在本地运行的
可视化 Studio。

给定一个目标文件，MoonEditorConfig 会从目标目录向上发现 `.editorconfig`，
在 `root = true` 处停止，匹配每个配置节并计算最终属性。与只返回键值的实现不同，
它会保留每次设置、覆盖、派生和取消设置的来源。

## 功能

- 可恢复解析器：保留文件、行、列、偏移量和结构化诊断
- EditorConfig Glob：`*`、`**`、`?`、字符集合、字符范围、选择和数值范围
- 跨平台路径归一化与父目录配置发现
- 层级合并、`root = true`、`unset` 和 `indent_size`/`tab_width` 派生
- 标准属性类型验证，同时保留编辑器自定义属性
- 最终值、匹配节和完整覆盖历史解释
- 配置质量评分、维护建议与重叠节冲突分析
- 规范格式化、统一 Diff 和安全/需复核修复计划
- 内存虚拟工作区、批量解析、属性分组与未覆盖文件检测
- JSON 输出，适合 CI、编辑器和其他工具集成
- 默认中文的 MoonEditorConfig Studio

## 环境要求

- MoonBit `0.1.20260814` 或更新版本
- 启动 Studio 时需要 Node.js；本项目环境已包含
  `D:\conda\environments\moonbit\node.exe`

检查环境：

```powershell
D:\conda\environments\moonbit\moonbit-toolchain\bin\moon.exe version --all
```

## 快速开始

```powershell
cd D:\conda\environments\moonbit\projects\MoonEditorConfig
moon check --deny-warn
moon test --deny-warn
moon run cmd/main -- check examples/valid.editorconfig
```

如果当前终端找不到 `moon`，可直接使用完整路径：

```powershell
D:\conda\environments\moonbit\moonbit-toolchain\bin\moon.exe test --deny-warn
```

## CLI

检查一个配置文件：

```powershell
moon run cmd/main -- check path/to/.editorconfig
```

解析目标文件的最终配置；命令会自动向父目录发现 `.editorconfig`：

```powershell
moon run cmd/main -- resolve src/main.mbt
moon run cmd/main -- resolve src/main.mbt --json
```

显示匹配和覆盖过程：

```powershell
moon run cmd/main -- explain src/main.mbt
```

查询单个属性：

```powershell
moon run cmd/main -- query src/main.mbt indent_size
```

测试 Glob：

```powershell
moon run cmd/main -- match "src/**.mbt" "src/parser/main.mbt"
```

格式化、预览差异和质量审计：

```powershell
moon run cmd/main -- format .editorconfig
moon run cmd/main -- format .editorconfig --write
moon run cmd/main -- diff .editorconfig
moon run cmd/main -- audit .editorconfig
moon run cmd/main -- conflicts .editorconfig
```

退出码：`0` 表示成功，`1` 表示发现阻断错误或查询未命中，`2` 表示参数或
文件访问错误。

## 启动 Studio

PowerShell：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\serve.ps1
```

CMD：

```bat
scripts\serve.cmd
```

看到下面的输出后访问对应地址：

```text
MoonEditorConfig Studio: http://127.0.0.1:8765/web/index.html
```

Studio 默认中文，提供实时编辑、健康评分、最终属性、来源历史、Glob 匹配过程、
诊断跳转、格式化和 JSON 报告导出。所有分析都由浏览器中的 MoonBit/JS 引擎
执行，配置内容不会上传。

端口被占用时可以先设置：

```powershell
$env:MOONEDITORCONFIG_PORT = "8877"
powershell -ExecutionPolicy Bypass -File scripts\serve.ps1
```

## 库 API 示例

解析和验证：

```mbt nocheck
///|
let parsed = @MoonEditorConfig.parse_document(
  "/repo/.editorconfig", "root = true\n[*.mbt]\nindent_size = 2\n",
)

///|
let diagnostics = @MoonEditorConfig.validate(parsed.config)
```

使用内存工作区解析层级配置：

```mbt nocheck
///|
let files : Array[@MoonEditorConfig.VirtualFile] = [
  {
    path: "/repo/.editorconfig",
    content: "root = true\n[*]\ncharset = utf-8\n",
  },
  { path: "/repo/src/.editorconfig", content: "[*.mbt]\nindent_size = 2\n" },
]

///|
let result = @MoonEditorConfig.resolve_workspace(files, "/repo/src/main.mbt")
```

## 项目结构

```text
parser.mbt             可恢复语法解析
model.mbt              公共数据模型与源码范围
glob.mbt               Glob 编译与匹配
glob_analysis.mbt      复杂度、示例与重叠见证
path_utils.mbt         跨平台路径处理
resolve.mbt            单文件与层级配置解析
workspace.mbt          虚拟项目和批量解析
validation.mbt         属性模式和语义验证
quality.mbt            质量评分与维护建议
conflicts.mbt          重复赋值和重叠节分析
format.mbt             规范格式化
diff.mbt               行级 Diff 与统一 Diff
fixes.mbt              文本编辑与修复计划
json.mbt               机器可读输出
report.mbt             中文终端报告
studio_api.mbt         浏览器分析快照
cmd/main/              原生 CLI
web/app/               MoonBit/JS Studio 入口
web/                   页面与样式
```

## 开发与验证

```powershell
moon check --target all --deny-warn
moon test --deny-warn
moon fmt --check
moon info
moon build --target native --release cmd/main
moon build --target js --release web/app
```

GitHub Actions 会执行相同的检查。测试覆盖解析、无效输入、Glob、路径、层级解析、
属性验证、格式化、JSON、虚拟工作区、质量审计、Diff、修复计划和配置冲突。

## 规范与兼容边界

项目以 [EditorConfig Specification 0.17.2](https://spec.editorconfig.org/) 为行为依据，
并参考 [EditorConfig Core Tests](https://github.com/editorconfig/editorconfig-core-test)
设计兼容用例。

当前版本专注于 Core 行为和诊断工具，不包含具体编辑器插件。Glob 重叠分析通过
生成具体见证路径保守报告：没有找到见证不代表两个任意 Glob 在数学上完全不相交。

第三方规范、依赖和测试来源见 [THIRD_PARTY.md](THIRD_PARTY.md)。

## 许可证

Apache-2.0，详见 [LICENSE](LICENSE)。
