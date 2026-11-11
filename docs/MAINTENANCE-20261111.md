# 2026 年 11 月兼容维护记录

维护版本：`0.1.1`。维护日期：2026-11-11。范围为现有解析库、CLI、Studio 和 CI 的工具链兼容性；不增加编辑器插件或改变 EditorConfig 解析规则。

## 工具链与依赖

- `moonc v0.10.20+65efd5b93`，构建日期 2026-11-05。
- `moon` / `moonrun 0.1.20261104 (940aa18)`，构建日期 2026-11-04。
- 依赖 `moonbitlang/x@0.5.7`。
- 本地 Windows 使用 Node.js `v26.5.1`；GitHub Actions 显式安装 Node.js 22。
- CI 通过官方安装器的 `MOONBIT_INSTALL_VERSION=0.10.20+65efd5b93` 固定编译器，并输出 `moon version --all` 供核对。

编译器版本取自实际 `moon version --all` 输出；构建日期与维护日期分别记录。

## 修改内容

1. 完成并保留 2026-11-09 的本地迁移：规范 `#derive`、`Int32`、`StringBuilder()`、迭代器及 JSON API。通过显式 Eq/Debug 扩展保留原有公开方法调用。
2. 将 README 的解析、验证和层级解析示例改为可执行测试；补充公开派生方法兼容和 Studio Unicode JSON 解析回归。
3. 增加 CLI `--version` / `-V`。统一模块、README、CLI 与更新日志的 `0.1.1`，将从未实际发布的旧 `0.2.0` 日志节澄清为开发历史。
4. 增加 `examples/workspace` 两层配置，复现父配置继承、子配置覆盖及来源查询。目标源码文件可尚未创建。
5. CI 增加显式 Node.js 安装和全部后端 release 构建。保留 README 符号链接，并将用户的 `.VSCodeCounter/` 列入忽略规则，未修改该目录内容。

生成接口的差异主要为 `Int` 的规范名称 `Int32`、派生属性布局和显式公开 Eq/Debug 方法；未删除原有业务 API。

## 本地验证

以下命令在项目根目录执行；使用上述固定 SDK，未在项目内执行 `moon update`。

| 命令 | 结果 |
| --- | --- |
| `moon version --all` | 与以上基线一致 |
| `moon check --target all --deny-warn` | 通过 |
| `moon test --target all --deny-warn` | wasm、wasm-gc、JS、native 各 164/164 通过 |
| `moon build --target all --release` | CLI 四后端及 Studio JS 构建通过 |
| `moon info` | 通过，已核对生成接口 |
| `moon fmt --check` | 通过 |
| `git diff --check` | 通过 |
| `node --check tools/studio_server.mjs` | 通过 |
| `node --check _build/js/release/build/web/app/app.js` | 通过 |

原生 release 可执行文件 `_build/native/release/build/cmd/main/main.exe` 的实际运行结果：

- `--version` 输出 `MoonEditorConfig 0.1.1`，退出码 0。
- `check examples/valid.editorconfig` 报告 1 个节、4 个属性及 `root = true`，退出码 0。
- `resolve examples/workspace/src/main.mbt --json` 输出有效的继承与覆盖结果：`charset=utf-8`、`indent_style=space`、`indent_size=2`、派生 `tab_width=2`，无诊断。
- `query examples/workspace/src/main.mbt indent_size` 输出 `2`，来源为子目录 `.editorconfig` 第 2 行。
- `match '*.mbt' README.md` 返回不匹配，退出码 1；未知命令、读取不存在配置文件均返回退出码 2。PowerShell 验证非零退出码时显式转发 `$LASTEXITCODE`。

使用现有 `node tools/studio_server.mjs` 临时服务，在本地端口 8877 验证：首页 `/web/index.html` 返回 HTTP 200、`text/html`；生成的 `app.js` 返回 HTTP 200、`text/javascript`。测试结束关闭本轮临时服务。Studio 分析引擎随四后端测试执行，Unicode 快照经 JSON 解析器验证。

本记录反映本地结果，未将配置中的远程 CI 等同于已执行结果；GitHub Actions 以实际运行记录为准。本轮未执行完整浏览器交互 E2E 测试，也未从 Windows 本地结果推断 Linux 本地测试结果。GitHub 推送、Mooncakes 发布及独立消费验证由发布流程另行核实。

## 发布归档中的示例完整性

发布预检发现，默认的点文件过滤会遗漏两份示例 `.editorconfig`。依据[官方打包规则](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html#publishing-files-with-moonignore)，在 `examples/workspace/.moonignore` 中仅恢复该目录的 `.editorconfig`、`src/.editorconfig` 及规则文件本身；保留根 `.gitignore`，未使用已弃用的 manifest `include` / `exclude` 字段。

当前固定 SDK 的 `moon package --frozen --list` 检查通过，生成的 `tlhuecdkoyg-MoonEditorConfig-0.1.1.zip` 经 `tar -tf` 确认包含三份文件，未包含 `.VSCodeCounter/`、`.git/`、`.mooncakes/` 或根 `_build/`。从真实 ZIP 中提取示例到 `_build/package-dotfiles-20261111` 后，原生 release CLI 的 `resolve .../src/main.mbt --json` 和 `query .../src/main.mbt indent_size` 均以退出码 0 完成，正确得到继承的 `charset=utf-8`、覆盖后的 `indent_size=2` 和解包后子目录配置第 2 行的来源。此修复不改业务源码，未重新执行已通过的 164 项业务测试。
