# 2026 年 11 月持续可用性维护

维护目的：按组委会提醒，**完成兼容性检查和必要修复**。维护版本为 `0.1.3`，检查日期为 2026-11-11；对应邮件截止时间为 2026-11-13 09:00（北京时间，UTC+8）。

## 工具链与范围

实际 `moon version --all` 与检查当日[官方发布元数据](https://cli.moonbitlang.com/version.json)一致：

- `moonc v0.10.20+65efd5b93 (2026-11-05)`。
- `moon` / `moonrun 0.1.20261104 (940aa18 2026-11-04)`。
- 依赖 `moonbitlang/x@0.5.7`。

范围包括源码及依赖兼容性、wasm / wasm-gc / JavaScript / native 四后端库验证、原生 CLI、README 可执行样例、Studio JavaScript 构建与持续集成。本地使用 Windows / MSVC、Node.js 26.5.1；CI 使用 Ubuntu、Node.js 22 和相同 MoonBit 工具链归档。浏览器交互的此前验证另见 [Studio 回归说明](STUDIO-BROWSER-TEST.md)。

## 必要修复

1. 修正缩进、首行 BOM、CRLF 及 UTF-16 源码位置。此前带缩进的 `charset = utf-8-bom` 提案可能把原文改为 `charset = utf-8om`；现在替换范围精确对应属性，保留相邻空白和行尾。
2. 格式化重新保留键中分隔符及值中反斜杠的转义，验证解析—格式化—解析的键值一致和格式化幂等。
3. 文档含语法错误时，禁止基于恢复后的语法树生成自动全量重写，保留错误行供人工处理。
4. CLI 发现 `.editorconfig` 读取失败立即返回 2，不再忽略子层失败后输出父层结果。`query` 遇配置错误返回 1；错误写入 stderr，`resolve --json` 的 stdout 保持纯 JSON 或在 I/O 失败时为空。

公开 API 签名保持不变。源码位置数值修正为真实坐标，CLI 的失败退出码及错误输出流按 README 声明的语义修正。

## 复现命令

在项目根目录执行：

```text
moon version --all
moon check --target all --deny-warn
moon test --target all --deny-warn
moon build --target all --release
moon build --target native --release cmd/main
moon run --target native tools/cli_regression_test.mbtx
moon info
moon fmt --check
```

`parser_format_regression_test.mbt` 覆盖坐标、编辑范围、转义往返和错误文档保护。CLI 工具实际启动编译后的程序，包含 10 组退出码、stderr/stdout 和 JSON 可解析性检查；默认寻找 `_build/native/release/build/cmd/main/main` 或 `main.exe`，也可传入可执行文件的绝对路径。工具仅在 `_build/cli-regression/` 创建本轮样本，使用当前固定 SDK 的实验性 `core/async`，相应警告已知；业务源码仍以 `--deny-warn` 验证。

CI 新增相同 CLI 回归步骤，继续执行四后端检查、测试、格式、接口及构建。发布前核对生成接口和实际打包内容，GitHub 与 Mooncakes 以对应提交的 CI 及公开注册表结果为准。`0.1.1`、`0.1.2` 的历史维护记录保留在原文件中，不作为本版本新提交的验证替代。

本地实际结果：四后端各 **184/184** 测试通过，10 组真实 CLI 回归通过，真实 Chrome 的诊断跳转、目标切换、格式化与主题检查通过。以上严格检查、release 构建、接口、格式及打包命令均以退出码 0 结束，公开 `.mbti` 接口无变化。ZIP 包保留两层 `.editorconfig` 示例及新的 CLI 回归工具。
