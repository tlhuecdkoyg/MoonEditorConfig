# MoonEditorConfig

MoonEditorConfig is a MoonBit-native EditorConfig core for resolving project
style settings with traceable sources. Given a target path, it will discover
`.editorconfig` files, match sections, merge inherited settings, and explain
which file and line produced each result.

## Project Scope

The first release focuses on a reusable core and CLI rather than an IDE plugin:

- Parse `.editorconfig` files with source locations and diagnostics
- Match EditorConfig glob sections, including `*`, `**`, `?`, and character sets
- Walk parent directories and stop at `root = true`
- Resolve effective properties with deterministic precedence
- Explain every property and its originating section
- Provide JSON output for CI and editor integrations

The implementation follows the [EditorConfig specification](https://spec.editorconfig.org/)
and uses the official [core test suite](https://github.com/editorconfig/editorconfig-core-test)
as a compatibility reference.

## Development

```powershell
moon fmt
moon check --deny-warn
moon test --deny-warn
```

The command-line interface will be added after the core data model and resolver
are established.

## License

Apache-2.0. See [LICENSE](LICENSE).