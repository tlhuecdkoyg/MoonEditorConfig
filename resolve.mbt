///|
pub struct ResolvedProperty {
  key : String
  value : String
  source : SourceLocation
  pattern : String
}

///|
pub fn resolve(config : EditorConfig, path : String) -> Array[ResolvedProperty] {
  let resolved : Array[ResolvedProperty] = []
  for section in config.sections {
    if glob_matches(section.pattern, path) {
      for property in section.properties {
        let item = {
          key: property.key,
          value: property.value,
          source: property.source,
          pattern: section.pattern,
        }
        let mut replaced = false
        for index = 0; index < resolved.length(); index = index + 1 {
          if resolved[index].key == property.key {
            resolved[index] = item
            replaced = true
            break
          }
        }
        if !replaced {
          resolved.push(item)
        }
      }
    }
  }
  resolved
}
