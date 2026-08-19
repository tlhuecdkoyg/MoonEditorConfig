///|
fn find_property_index(
  properties : Array[ResolvedProperty],
  key : String,
) -> Int? {
  for index, property in properties {
    if property.key == key {
      return Some(index)
    }
  }
  None
}

///|
fn append_step(
  existing : ResolvedProperty,
  step : PropertyStep,
  replacement : Property,
) -> ResolvedProperty {
  let history = existing.history.copy()
  history.push(step)
  {
    key: replacement.key,
    value: replacement.value,
    source: replacement.source,
    pattern: step.pattern,
    config_path: step.config_path,
    history,
  }
}

///|
fn apply_property(
  properties : Array[ResolvedProperty],
  property : Property,
  config_path : String,
  pattern : String,
) -> Unit {
  let normalized_value = lower_ascii(property.value)
  let step : PropertyStep = {
    key: property.key,
    value: property.value,
    config_path,
    pattern,
    line: property.source.line,
    action: if normalized_value == "unset" {
      "unset"
    } else {
      "set"
    },
  }
  match find_property_index(properties, property.key) {
    Some(index) =>
      if normalized_value == "unset" {
        ignore(properties.remove(index))
      } else {
        properties[index] = append_step(properties[index], step, property)
      }
    None =>
      if normalized_value != "unset" {
        properties.push({
          key: property.key,
          value: property.value,
          source: property.source,
          pattern,
          config_path,
          history: [step],
        })
      }
  }
}

///|
fn apply_derived_properties(properties : Array[ResolvedProperty]) -> Unit {
  let indent_index = find_property_index(properties, "indent_size")
  let tab_index = find_property_index(properties, "tab_width")
  match (indent_index, tab_index) {
    (Some(indent), None) if lower_ascii(properties[indent].value) != "tab" => {
      let source = properties[indent]
      properties.push({
        key: "tab_width",
        value: source.value,
        source: source.source,
        pattern: source.pattern,
        config_path: source.config_path,
        history: [
          {
            key: "tab_width",
            value: source.value,
            config_path: source.config_path,
            pattern: source.pattern,
            line: source.source.line,
            action: "derived from indent_size",
          },
        ],
      })
    }
    (Some(indent), Some(tab)) if lower_ascii(properties[indent].value) == "tab" => {
      let source = properties[tab]
      properties[indent] = {
        key: "indent_size",
        value: source.value,
        source: source.source,
        pattern: source.pattern,
        config_path: source.config_path,
        history: properties[indent].history,
      }
    }
    _ => ()
  }
}

///|
fn sorted_layers(layers : Array[ConfigLayer]) -> Array[ConfigLayer] {
  let result = layers.copy()
  result.sort_by((left, right) => {
    path_depth(left.directory) - path_depth(right.directory)
  })
  let mut last_root = -1
  for index, layer in result {
    if layer.config.root {
      last_root = index
    }
  }
  if last_root > 0 {
    let scoped : Array[ConfigLayer] = []
    for index in last_root..<result.length() {
      scoped.push(result[index])
    }
    scoped
  } else {
    result
  }
}

///|
pub fn resolve_layers(
  layers : Array[ConfigLayer],
  target : String,
) -> Resolution {
  let properties : Array[ResolvedProperty] = []
  let traces : Array[SectionTrace] = []
  let diagnostics : Array[Diagnostic] = []
  for layer in sorted_layers(layers) {
    for diagnostic in validate(layer.config) {
      diagnostics.push(diagnostic)
    }
    match relative_path(layer.directory, target) {
      None =>
        diagnostics.push(
          make_diagnostic(
            layer.path,
            1,
            1,
            1,
            0,
            Warning,
            "EC3001",
            "目标文件不在配置目录内",
            "检查配置层的 directory 字段。",
          ),
        )
      Some(relative) =>
        for section in layer.config.sections {
          let matched = glob_matches(section.pattern, relative)
          traces.push({
            config_path: layer.path,
            pattern: section.pattern,
            matched,
            relative_path: relative,
            line: section.source.line,
            reason: explain_glob(section.pattern, relative),
          })
          if matched {
            for property in section.properties {
              apply_property(properties, property, layer.path, section.pattern)
            }
          }
        }
    }
  }
  apply_derived_properties(properties)
  { target: normalize_path(target), properties, sections: traces, diagnostics }
}

///|
/// Compatibility helper for resolving one already parsed document.
pub fn resolve(config : EditorConfig, path : String) -> Array[ResolvedProperty] {
  let properties : Array[ResolvedProperty] = []
  for section in config.sections {
    if glob_matches(section.pattern, path) {
      for property in section.properties {
        apply_property(properties, property, config.path, section.pattern)
      }
    }
  }
  properties
}

///|
pub fn Resolution::get(self : Resolution, key : String) -> ResolvedProperty? {
  let normalized = lower_ascii(key)
  for property in self.properties {
    if property.key == normalized {
      return Some(property)
    }
  }
  None
}
