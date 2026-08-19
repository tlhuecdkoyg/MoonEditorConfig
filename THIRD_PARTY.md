# 第三方来源与规范说明

MoonEditorConfig 是原创 MoonBit 实现，不包含从其他 EditorConfig Core
实现复制或翻译的源代码。

项目行为依据以下公开规范设计：

- EditorConfig Specification 0.17.2：<https://spec.editorconfig.org/>
- EditorConfig Core Tests：<https://github.com/editorconfig/editorconfig-core-test>

仓库中的测试用例由本项目重新编写，用于覆盖规范概念及项目自身的回归场景，
没有直接打包或复制官方测试仓库。若未来引入上游 fixture，必须在此文件中记录
具体文件、版本、许可证和所做修改。

运行时依赖：

- `moonbitlang/x`，遵循其上游许可证；本项目主要使用 `fs` 和 `sys` 包实现原生 CLI。
- Studio 使用浏览器 Web API，通过 MoonBit JavaScript FFI 连接 DOM，不依赖前端框架。

项目本身采用 Apache-2.0 许可证，详见根目录 `LICENSE`。
