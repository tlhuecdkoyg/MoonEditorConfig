# Studio 浏览器回归

`tools/studio_browser_test.mbtx` 使用本机已安装的 Chrome、Chromium 或 Edge，通过 Chrome DevTools Protocol 在真实无头浏览器中操作 Studio。它不下载浏览器，也不使用日常浏览器的配置目录。

先在项目根目录构建 JavaScript：

```text
moon build --release --target js
```

然后设置 `MOONEDITORCONFIG_BROWSER` 为浏览器可执行文件的绝对路径，运行：

```text
moon run --target native tools/studio_browser_test.mbtx
```

例如，Windows PowerShell 中可以设置：

```powershell
$env:MOONEDITORCONFIG_BROWSER = 'C:/Program Files/Google/Chrome/Application/chrome.exe'
moon run --target native tools/studio_browser_test.mbtx
```

macOS 或 Linux 的 shell 中可以使用：

```sh
MOONEDITORCONFIG_BROWSER=/absolute/path/to/chromium moon run --target native tools/studio_browser_test.mbtx
```

这些系统上的命令仅说明配置方式；当前已实际验证的环境为 Windows、Chrome 和 MoonBit `v0.10.20+65efd5b93`。需要可运行的 Node.js、原生编译工具链，以及当前 SDK 提供的实验性 `core/async` 包。SDK 会显示该包的实验性依赖警告。此工具是独立手动回归，不作为 CI 的默认必需步骤。

可选环境变量：

| 变量 | 默认值 | 用途 |
| --- | --- | --- |
| `MOONEDITORCONFIG_ROOT` | 当前目录 | 项目根目录；覆盖时须使用绝对路径 |
| `MOONEDITORCONFIG_NODE` | `node` | Node.js 可执行文件名或绝对路径 |
| `MOONEDITORCONFIG_TEST_PORT` | `18765` | 本地 HTTP 端口；应选空闲端口 |

每次运行在 `_build/studio-browser/<时间戳>/` 创建独立浏览器 profile 和进程日志；CDP 使用操作系统分配的端口，仅监听 `127.0.0.1`。HTTP 服务也仅监听本机。工具设置 60 秒总时限、5 秒 CDP 请求时限，并在正常完成或报错时取消自己启动的浏览器和服务器进程。测试目录保留以便诊断，工具不会删除用户目录、终止已有浏览器或关闭浏览器沙箱。

回归检查包含：

- 加载实际编译的 Studio，选择“错误配置”，确认 10 条诊断显示数字行号。
- 点击第 1、4、7 行的诊断，确认文本框聚焦并精确选中对应源代码行。
- 切换 `.mbt` 和 Markdown 目标路径，确认属性从 7 项变为 3 项。
- 执行格式化，检查具体格式化文本；切换主题，检查 DOM 状态与持久化值。

结果以逐行 JSON 输出；断言失败或超时返回非零退出码。修复前的 `0.1.1` Studio 在第一项检查中失败：引擎输出使用 `start.line`，页面错误地读取了 `line`，导致显示 `undefined`，点击诊断选中空文本。当前页面读取规范字段 `start.line`。

此回归验证真实浏览器 DOM 与交互处理程序。它不覆盖屏幕像素命中、视觉布局、辅助技术、剪贴板权限、下载对话框或所有浏览器兼容性。
