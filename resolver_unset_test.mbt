///|
test "resolver/explicit tab width unset prevents rederivation" {
  let result = @MoonEditorConfig.resolve_layers(
    [
      layer(
        "/repo/.editorconfig", "/repo", "[*]\nindent_size=4\ntab_width=8\n[src/*.mbt]\ntab_width=unset\n",
      ),
    ],
    "/repo/src/main.mbt",
  )
  assert_eq(result.get("indent_size").unwrap().value, "4")
  assert_true(result.get("tab_width") is None)
}

///|
test "resolver/unset before indent assignment still cancels inference" {
  let result = @MoonEditorConfig.resolve_layers(
    [
      layer(
        "/repo/.editorconfig", "/repo", "[*]\ntab_width=UnSeT\nindent_size=2\n",
      ),
    ],
    "/repo/main.mbt",
  )
  assert_eq(result.get("indent_size").unwrap().value, "2")
  assert_true(result.get("tab_width") is None)
}

///|
test "resolver/later explicit assignment replaces unset across layers" {
  let result = @MoonEditorConfig.resolve_layers(
    [
      layer("/repo/.editorconfig", "/repo", "[*]\nindent_size=4\ntab_width=8\n"),
      layer("/repo/src/.editorconfig", "/repo/src", "[*]\ntab_width=unset\n"),
      layer(
        "/repo/src/lib/.editorconfig", "/repo/src/lib", "[*]\ntab_width=3\n",
      ),
    ],
    "/repo/src/lib/main.mbt",
  )
  assert_eq(result.get("indent_size").unwrap().value, "4")
  assert_eq(result.get("tab_width").unwrap().value, "3")
}

///|
test "resolver/nonmatching unset does not cancel a default" {
  let result = @MoonEditorConfig.resolve_layers(
    [
      layer(
        "/repo/.editorconfig", "/repo", "[*]\nindent_size=4\n[*.md]\ntab_width=unset\n",
      ),
    ],
    "/repo/main.mbt",
  )
  assert_eq(result.get("tab_width").unwrap().value, "4")
}

///|
test "resolver/root boundary discards outer unset before derivation" {
  let result = @MoonEditorConfig.resolve_layers(
    [
      layer("/.editorconfig", "/", "[*]\ntab_width=unset\n"),
      layer("/repo/.editorconfig", "/repo", "root=true\n[*]\nindent_size=2\n"),
    ],
    "/repo/main.mbt",
  )
  let tab = result.get("tab_width").unwrap()
  assert_eq(tab.value, "2")
  assert_eq(tab.config_path, "/repo/.editorconfig")
  assert_eq(tab.history[0].action, "derived from indent_size")
}

///|
test "resolver/tab indent keeps editor default after explicit width unset" {
  let result = @MoonEditorConfig.resolve_layers(
    [
      layer(
        "/repo/.editorconfig", "/repo", "[*]\nindent_size=tab\ntab_width=8\n",
      ),
      layer(
        "/repo/src/.editorconfig", "/repo/src", "[*.mbt]\ntab_width=unset\n",
      ),
    ],
    "/repo/src/main.mbt",
  )
  let indent = result.get("indent_size").unwrap()
  assert_eq(indent.value, "tab")
  assert_eq(indent.config_path, "/repo/.editorconfig")
  assert_true(result.get("tab_width") is None)
}
