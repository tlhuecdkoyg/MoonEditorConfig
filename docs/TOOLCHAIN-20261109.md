# 本地工具链升级记录（2026-11-09）

本地工具链更新为 `moonc v0.10.20+65efd5b93`（构建日期 2026-11-05），配套 `moon` / `moonrun 0.1.20261104 (940aa18)`（构建日期 2026-11-04）。依赖升级为 `moonbitlang/x@0.5.7`，CI 安装版本在本地配置中固定为相同编译器构建。

迁移包括规范的 `#derive`、显式 `Int32`、`StringBuilder()` 及数值 JSON 构造。显式 trait 扩展保留旧编译器隐式提升的方法调用方式；生成接口还包含类型命名与属性布局调整，没有移除原有业务功能。

已在 Windows 本地验证：

- `moon check --target all --deny-warn` 通过。
- wasm、wasm-gc、JavaScript、native 四个后端各 160/160 项测试通过。
- 全部后端 release 构建、`moon info`、`moon fmt --check`、差异空白检查通过。
- 原生 CLI 检查 `examples/valid.editorconfig` 成功，报告 1 个配置节、4 个属性。
- Node.js 26.5.1 对 Studio 服务及生成的 JavaScript 语法检查通过。
- 临时启动 Studio 后，首页和生成的 `app.js` 均返回 HTTP 200，内容类型分别为 HTML 与 JavaScript；验证结束已关闭本轮服务。

README 符号链接和用户已有的 `.VSCodeCounter/` 均保留。项目发布版本未改变；本次仅本地迁移，未提交、推送或重新发布，升级后的远程 CI 尚未执行。
