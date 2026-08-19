///|
fn layer(
  path : String,
  directory : String,
  source : String,
) -> @MoonEditorConfig.ConfigLayer {
  {
    path,
    directory,
    config: @MoonEditorConfig.parse_document(path, source).config,
  }
}

///|
test "resolver/single layer applies matching sections" {
  let resolution = @MoonEditorConfig.resolve_layers(
    [
      layer(
        "/repo/.editorconfig", "/repo", "[*]\ncharset = utf-8\n[*.mbt]\nindent_size = 2\n",
      ),
    ],
    "/repo/src/main.mbt",
  )
  assert_eq(resolution.properties.length(), 3)
  assert_eq(resolution.get("charset").unwrap().value, "utf-8")
  assert_eq(resolution.get("indent_size").unwrap().value, "2")
  assert_eq(resolution.get("tab_width").unwrap().value, "2")
}

///|
test "resolver/nonmatching sections remain in trace" {
  let resolution = @MoonEditorConfig.resolve_layers(
    [
      layer(
        "/repo/.editorconfig", "/repo", "[*.md]\nindent_size = 4\n[*.mbt]\nindent_size = 2\n",
      ),
    ],
    "/repo/main.mbt",
  )
  assert_eq(resolution.sections.length(), 2)
  assert_false(resolution.sections[0].matched)
  assert_true(resolution.sections[1].matched)
  assert_eq(resolution.properties[0].value, "2")
}

///|
test "resolver/nearer layer overrides parent regardless of input order" {
  let root = layer(
    "/repo/.editorconfig", "/repo", "[*]\nindent_size = 4\ncharset = utf-8\n",
  )
  let child = layer(
    "/repo/src/.editorconfig", "/repo/src", "[*.mbt]\nindent_size = 2\n",
  )
  for layers in [[root, child], [child, root]] {
    let resolution = @MoonEditorConfig.resolve_layers(
      layers, "/repo/src/main.mbt",
    )
    let property = resolution.get("indent_size").unwrap()
    assert_eq(property.value, "2")
    assert_eq(property.config_path, "/repo/src/.editorconfig")
    assert_eq(property.history.length(), 2)
  }
}

///|
test "resolver/three-level hierarchy" {
  let resolution = @MoonEditorConfig.resolve_layers(
    [
      layer(
        "/repo/.editorconfig", "/repo", "[*]\nindent_size = 8\ncharset = latin1\n",
      ),
      layer(
        "/repo/src/.editorconfig", "/repo/src", "[*]\nindent_size = 4\ncharset = utf-8\n",
      ),
      layer(
        "/repo/src/lib/.editorconfig", "/repo/src/lib", "[*.mbt]\nindent_size = 2\n",
      ),
    ],
    "/repo/src/lib/main.mbt",
  )
  assert_eq(resolution.get("indent_size").unwrap().value, "2")
  assert_eq(resolution.get("charset").unwrap().value, "utf-8")
  assert_eq(resolution.get("indent_size").unwrap().history.length(), 3)
}

///|
test "resolver/root true discards outer layers" {
  let resolution = @MoonEditorConfig.resolve_layers(
    [
      layer("/.editorconfig", "/", "[*]\nindent_size = 8\ncharset = latin1\n"),
      layer(
        "/repo/.editorconfig", "/repo", "root = true\n[*]\nindent_size = 2\n",
      ),
    ],
    "/repo/main.mbt",
  )
  assert_eq(resolution.get("indent_size").unwrap().value, "2")
  assert_true(resolution.get("charset") is None)
}

///|
test "resolver/unset removes inherited property" {
  let resolution = @MoonEditorConfig.resolve_layers(
    [
      layer(
        "/repo/.editorconfig", "/repo", "[*]\nindent_size = 4\ncharset = utf-8\n",
      ),
      layer(
        "/repo/src/.editorconfig", "/repo/src", "[*.mbt]\nindent_size = unset\n",
      ),
    ],
    "/repo/src/main.mbt",
  )
  assert_true(resolution.get("indent_size") is None)
  assert_true(resolution.get("tab_width") is None)
  assert_eq(resolution.get("charset").unwrap().value, "utf-8")
}

///|
test "resolver/later section wins in same file" {
  let resolution = @MoonEditorConfig.resolve_layers(
    [
      layer(
        "/repo/.editorconfig", "/repo", "[*]\nindent_size = 4\n[*.mbt]\nindent_size = 2\n[src/**]\nindent_size = 3\n",
      ),
    ],
    "/repo/src/main.mbt",
  )
  let property = resolution.get("indent_size").unwrap()
  assert_eq(property.value, "3")
  assert_eq(property.history.length(), 3)
  assert_eq(property.pattern, "src/**")
}

///|
test "resolver/custom properties participate normally" {
  let resolution = @MoonEditorConfig.resolve_layers(
    [layer("/repo/.editorconfig", "/repo", "[*]\nmy_editor_flag = enabled\n")],
    "/repo/main.mbt",
  )
  assert_eq(resolution.get("MY_EDITOR_FLAG").unwrap().value, "enabled")
}

///|
test "resolver/target outside layer reports warning" {
  let resolution = @MoonEditorConfig.resolve_layers(
    [layer("/other/.editorconfig", "/other", "[*]\nindent_size = 2\n")],
    "/repo/main.mbt",
  )
  assert_eq(resolution.properties.length(), 0)
  assert_eq(resolution.diagnostics.length(), 1)
  assert_eq(resolution.diagnostics[0].code, "EC3001")
}

///|
test "resolver/relative paths are recorded" {
  let resolution = @MoonEditorConfig.resolve_layers(
    [layer("/repo/.editorconfig", "/repo", "[src/**.mbt]\nindent_size = 2\n")],
    "/repo/src/parser/main.mbt",
  )
  assert_eq(resolution.sections[0].relative_path, "src/parser/main.mbt")
  assert_true(resolution.sections[0].matched)
}

///|
test "resolver/derives tab width from numeric indent size" {
  let resolution = @MoonEditorConfig.resolve_layers(
    [layer("/repo/.editorconfig", "/repo", "[*]\nindent_size = 6\n")],
    "/repo/main.mbt",
  )
  let tab = resolution.get("tab_width").unwrap()
  assert_eq(tab.value, "6")
  assert_eq(tab.history[0].action, "derived from indent_size")
}

///|
test "resolver/indent size tab derives from tab width" {
  let resolution = @MoonEditorConfig.resolve_layers(
    [
      layer(
        "/repo/.editorconfig", "/repo", "[*]\ntab_width = 3\nindent_size = tab\n",
      ),
    ],
    "/repo/main.mbt",
  )
  assert_eq(resolution.get("indent_size").unwrap().value, "3")
  assert_eq(resolution.get("tab_width").unwrap().value, "3")
}

///|
test "resolver/no layers returns empty resolution" {
  let resolution = @MoonEditorConfig.resolve_layers([], "/repo/main.mbt")
  assert_eq(resolution.target, "/repo/main.mbt")
  assert_eq(resolution.properties.length(), 0)
  assert_eq(resolution.sections.length(), 0)
  assert_eq(resolution.diagnostics.length(), 0)
}

///|
test "resolver/normalizes target separators" {
  let resolution = @MoonEditorConfig.resolve_layers(
    [
      layer(
        "C:/repo/.editorconfig", "C:/repo", "[src/*.mbt]\nindent_size = 2\n",
      ),
    ],
    "C:\\repo\\src\\main.mbt",
  )
  assert_eq(resolution.target, "C:/repo/src/main.mbt")
  assert_true(resolution.sections[0].matched)
}

///|
test "resolver/compatibility resolve does not derive properties" {
  let config = @MoonEditorConfig.parse("[*]\nindent_size = 2\n").config
  let properties = @MoonEditorConfig.resolve(config, "main.mbt")
  assert_eq(properties.length(), 1)
  assert_eq(properties[0].key, "indent_size")
}
