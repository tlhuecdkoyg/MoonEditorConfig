# MoonEditorConfig

MoonEditorConfig 是使用 MoonBit 编写的 EditorConfig 核心库，面向需要统一
代码风格的项目。给定一个目标文件路径后，它可以查找 `.editorconfig`，匹配
配置段，合并继承关系，并解释每项最终配置来自哪个文件、哪个段和哪一行。

## 项目范围

第一阶段优先完成可复用核心库和命令行工具，暂不制作 IDE 插件：

- 解析 `.editorconfig`，保留来源位置并生成诊断信息
- 匹配 EditorConfig Glob，包括 `*`、`**`、`?` 和字符集合
- 向父目录查找配置，并在 `root = true` 时停止
- 按确定的优先级计算最终属性
- 解释每项属性的来源和覆盖关系
- 为 CI 和编辑器集成提供 JSON 输出

实现遵循 [EditorConfig 规范](https://spec.editorconfig.org/)，并以官方
[核心测试套件](https://github.com/editorconfig/editorconfig-core-test)
作为兼容性参考。

## 当前进度

目前已经完成：

- 带行号的基础配置解析
- 非法行诊断
- 基础 Glob 匹配
- 匹配配置段后的属性合并
- 属性来源和配置段来源追踪

## 开发命令

```powershell
moon fmt
moon check --deny-warn
moon test --deny-warn
```

命令行工具将在核心数据模型和解析流程稳定后继续加入。

## 许可证

Apache-2.0，详见 [LICENSE](LICENSE)。