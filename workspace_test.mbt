///|
fn virtual_project() -> Array[@MoonEditorConfig.VirtualFile] {
  [
    {
      path: "/repo/.editorconfig",
      content: "root = true\n[*]\ncharset = utf-8\nindent_size = 4\n",
    },
    { path: "/repo/src/.editorconfig", content: "[*.mbt]\nindent_size = 2\n" },
    { path: "/repo/src/main.mbt", content: "fn main {}\n" },
    { path: "/repo/README.md", content: "# Project\n" },
  ]
}

///|
test "workspace/discovers leaf and root configs" {
  let (layers, diagnostics) = @MoonEditorConfig.discover_virtual_configs(
    virtual_project(),
    "/repo/src/main.mbt",
  )
  assert_eq(layers.length(), 2)
  assert_eq(layers[0].path, "/repo/src/.editorconfig")
  assert_eq(layers[1].path, "/repo/.editorconfig")
  assert_eq(diagnostics.length(), 0)
}

///|
test "workspace/stops at root true" {
  let files = virtual_project()
  files.push({ path: "/.editorconfig", content: "[*]\ncharset = latin1\n" })
  let result = @MoonEditorConfig.resolve_workspace(files, "/repo/src/main.mbt")
  assert_eq(result.discovered_configs.length(), 2)
  assert_eq(result.resolution.get("charset").unwrap().value, "utf-8")
}

///|
test "workspace/resolves hierarchy" {
  let result = @MoonEditorConfig.resolve_workspace(
    virtual_project(),
    "/repo/src/main.mbt",
  )
  assert_eq(result.target, "/repo/src/main.mbt")
  assert_eq(result.resolution.get("indent_size").unwrap().value, "2")
  assert_eq(result.resolution.get("charset").unwrap().value, "utf-8")
  assert_eq(result.diagnostics.length(), 0)
}

///|
test "workspace/file without child config uses root" {
  let result = @MoonEditorConfig.resolve_workspace(
    virtual_project(),
    "/repo/README.md",
  )
  assert_eq(result.discovered_configs.length(), 1)
  assert_eq(result.resolution.get("indent_size").unwrap().value, "4")
}

///|
test "workspace/missing configs is valid empty result" {
  let result = @MoonEditorConfig.resolve_workspace([], "/repo/main.mbt")
  assert_eq(result.discovered_configs.length(), 0)
  assert_eq(result.resolution.properties.length(), 0)
  assert_eq(result.diagnostics.length(), 0)
}

///|
test "workspace/parse diagnostics preserve config path" {
  let files : Array[@MoonEditorConfig.VirtualFile] = [
    { path: "/repo/.editorconfig", content: "root = maybe\n[*.mbt\n" },
  ]
  let result = @MoonEditorConfig.resolve_workspace(files, "/repo/main.mbt")
  assert_eq(result.diagnostics.length(), 3)
  assert_eq(result.diagnostics[0].span.start.file, "/repo/.editorconfig")
}

///|
test "workspace/batch returns targets in requested order" {
  let results = @MoonEditorConfig.resolve_workspace_batch(virtual_project(), [
    "/repo/README.md", "/repo/src/main.mbt",
  ])
  assert_eq(results.length(), 2)
  assert_eq(results[0].target, "/repo/README.md")
  assert_eq(results[1].target, "/repo/src/main.mbt")
}

///|
test "workspace/groups targets by effective property" {
  let results = @MoonEditorConfig.resolve_workspace_batch(virtual_project(), [
    "/repo/README.md", "/repo/src/main.mbt", "/outside/file.txt",
  ])
  let groups = @MoonEditorConfig.group_targets_by_property(
    results, "indent_size",
  )
  assert_eq(groups["4"].length(), 1)
  assert_eq(groups["2"].length(), 1)
  assert_eq(groups["<unset>"].length(), 1)
}

///|
test "workspace/reports uncovered targets" {
  let results = @MoonEditorConfig.resolve_workspace_batch(virtual_project(), [
    "/repo/README.md", "/outside/file.txt",
  ])
  let uncovered = @MoonEditorConfig.uncovered_targets(results)
  assert_eq(uncovered.length(), 1)
  assert_eq(uncovered[0], "/outside/file.txt")
}

///|
test "workspace/normalizes Windows paths" {
  let files : Array[@MoonEditorConfig.VirtualFile] = [
    {
      path: "C:\\repo\\.editorconfig",
      content: "root = true\n[*.mbt]\nindent_size = 2\n",
    },
  ]
  let result = @MoonEditorConfig.resolve_workspace(
    files, "C:\\repo\\src\\main.mbt",
  )
  assert_eq(result.discovered_configs[0], "C:/repo/.editorconfig")
  assert_eq(result.resolution.get("indent_size").unwrap().value, "2")
}
