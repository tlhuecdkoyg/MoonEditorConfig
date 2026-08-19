///|
/// An in-memory file used by browser, test, and editor integrations.
pub(all) struct VirtualFile {
  path : String
  content : String
} derive(Debug, Eq)

///|
/// Result of resolving a target inside a virtual project.
pub(all) struct WorkspaceResult {
  target : String
  discovered_configs : Array[String]
  resolution : Resolution
  diagnostics : Array[Diagnostic]
} derive(Debug, Eq)

///|
fn find_virtual_file(files : Array[VirtualFile], path : String) -> VirtualFile? {
  let normalized = normalize_path(path)
  for file in files {
    if normalize_path(file.path) == normalized {
      return Some(file)
    }
  }
  None
}

///|
fn join_path(directory : String, name : String) -> String {
  if directory == "/" {
    "/" + name
  } else if directory == "" {
    name
  } else {
    directory + "/" + name
  }
}

///|
fn directory_of_target(target : String) -> String {
  match parent_path(target) {
    Some(directory) => directory
    None => ""
  }
}

///|
/// Discover `.editorconfig` files in leaf-to-root order without accessing the
/// host filesystem. Search stops after parsing a file with `root = true`.
pub fn discover_virtual_configs(
  files : Array[VirtualFile],
  target : String,
) -> (Array[ConfigLayer], Array[Diagnostic]) {
  let layers : Array[ConfigLayer] = []
  let diagnostics : Array[Diagnostic] = []
  let mut directory = directory_of_target(normalize_path(target))
  let mut finished = false
  while !finished {
    let candidate = join_path(directory, ".editorconfig")
    match find_virtual_file(files, candidate) {
      Some(file) => {
        let parsed = parse_document(normalize_path(file.path), file.content)
        layers.push({
          path: normalize_path(file.path),
          directory,
          config: parsed.config,
        })
        for diagnostic in parsed.diagnostics {
          diagnostics.push(diagnostic)
        }
        if parsed.config.root {
          finished = true
        }
      }
      None => ()
    }
    if !finished {
      match parent_path(directory) {
        Some(parent) if parent != directory => directory = parent
        _ => finished = true
      }
    }
  }
  (layers, diagnostics)
}

///|
/// Resolve one target using a complete in-memory project snapshot.
pub fn resolve_workspace(
  files : Array[VirtualFile],
  target : String,
) -> WorkspaceResult {
  let normalized_target = normalize_path(target)
  let (layers, parse_diagnostics) = discover_virtual_configs(
    files, normalized_target,
  )
  let resolution = resolve_layers(layers, normalized_target)
  let diagnostics = parse_diagnostics.copy()
  for diagnostic in resolution.diagnostics {
    diagnostics.push(diagnostic)
  }
  let discovered : Array[String] = []
  for layer in layers {
    discovered.push(layer.path)
  }
  {
    target: normalized_target,
    discovered_configs: discovered,
    resolution,
    diagnostics,
  }
}

///|
/// Resolve several files efficiently against the same virtual project.
pub fn resolve_workspace_batch(
  files : Array[VirtualFile],
  targets : Array[String],
) -> Array[WorkspaceResult] {
  let results : Array[WorkspaceResult] = []
  for target in targets {
    results.push(resolve_workspace(files, target))
  }
  results
}

///|
/// List files whose effective configuration differs for a selected property.
pub fn group_targets_by_property(
  results : Array[WorkspaceResult],
  property_name : String,
) -> Map[String, Array[String]] {
  let groups : Map[String, Array[String]] = Map([])
  for result in results {
    let value = match result.resolution.get(property_name) {
      Some(property) => property.value
      None => "<unset>"
    }
    match groups.get(value) {
      Some(paths) => paths.push(result.target)
      None => groups[value] = [result.target]
    }
  }
  groups
}

///|
/// Find project files that have no matching EditorConfig section.
pub fn uncovered_targets(results : Array[WorkspaceResult]) -> Array[String] {
  let paths : Array[String] = []
  for result in results {
    if !result.resolution.sections.any(trace => trace.matched) {
      paths.push(result.target)
    }
  }
  paths
}
