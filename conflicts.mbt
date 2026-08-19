///|
pub(all) enum ConflictKind {
  DuplicateAssignment
  RedundantAssignment
  OverlappingSections
  ConflictingSections
} derive(Debug, Eq)

///|
pub(all) struct ConfigConflict {
  kind : ConflictKind
  key : String
  first_pattern : String
  second_pattern : String
  first_value : String
  second_value : String
  witness_path : String?
  first_line : Int
  second_line : Int
  message : String
} derive(Debug, Eq)

///|
fn same_scope_conflicts(
  section : Section,
  conflicts : Array[ConfigConflict],
) -> Unit {
  for index, property in section.properties {
    for previous in 0..<index {
      let earlier = section.properties[previous]
      if earlier.key == property.key {
        let redundant = lower_ascii(earlier.value) ==
          lower_ascii(property.value)
        conflicts.push({
          kind: if redundant {
            RedundantAssignment
          } else {
            DuplicateAssignment
          },
          key: property.key,
          first_pattern: section.pattern,
          second_pattern: section.pattern,
          first_value: earlier.value,
          second_value: property.value,
          witness_path: glob_examples(section.pattern).get(0),
          first_line: earlier.source.line,
          second_line: property.source.line,
          message: if redundant {
            "同一配置节重复设置相同的值，后一项可以删除。"
          } else {
            "同一配置节重复设置不同的值，后一项会覆盖前一项。"
          },
        })
      }
    }
  }
}

///|
fn compare_sections(
  first : Section,
  second : Section,
  conflicts : Array[ConfigConflict],
) -> Unit {
  guard glob_overlap_witness(first.pattern, second.pattern) is Some(witness) else {
    return
  }
  for left in first.properties {
    for right in second.properties {
      if left.key == right.key {
        let same = lower_ascii(left.value) == lower_ascii(right.value)
        conflicts.push({
          kind: if same {
            OverlappingSections
          } else {
            ConflictingSections
          },
          key: left.key,
          first_pattern: first.pattern,
          second_pattern: second.pattern,
          first_value: left.value,
          second_value: right.value,
          witness_path: Some(witness),
          first_line: left.source.line,
          second_line: right.source.line,
          message: if same {
            "两个可能重叠的配置节设置了相同值，可考虑集中通用配置。"
          } else {
            "两个可能重叠的配置节设置了不同值；后出现的节会覆盖前一节。"
          },
        })
      }
    }
  }
}

///|
/// Find duplicate assignments and concrete cross-section overlap witnesses.
/// Overlap analysis is deliberately conservative: it reports only when a
/// generated path matches both patterns and never claims patterns are disjoint.
pub fn analyze_conflicts(config : EditorConfig) -> Array[ConfigConflict] {
  let conflicts : Array[ConfigConflict] = []
  for section in config.sections {
    same_scope_conflicts(section, conflicts)
  }
  for index, section in config.sections {
    for previous in 0..<index {
      compare_sections(config.sections[previous], section, conflicts)
    }
  }
  conflicts
}

///|
pub fn ConfigConflict::render_zh(self : ConfigConflict) -> String {
  let location = "第 " +
    self.first_line.to_string() +
    "、" +
    self.second_line.to_string() +
    " 行"
  let witness = match self.witness_path {
    Some(path) => "；示例路径：" + path
    None => ""
  }
  location + "：属性 `" + self.key + "`，" + self.message + witness
}

///|
pub fn conflict_count_by_kind(
  conflicts : Array[ConfigConflict],
  kind : ConflictKind,
) -> Int {
  conflicts.fold(init=0, (count, conflict) => {
    count + (if conflict.kind == kind { 1 } else { 0 })
  })
}
