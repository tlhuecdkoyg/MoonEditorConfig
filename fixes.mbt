///|
pub(all) struct TextEdit {
  start_offset : Int
  end_offset : Int
  replacement : String
  title : String
  safe : Bool
} derive(Debug, Eq)

///|
pub(all) struct FixPlan {
  edits : Array[TextEdit]
  safe_count : Int
  review_count : Int
  safe_source : String
  diff : String
} derive(Debug, Eq)

///|
fn canonical_format_edit(source : String, config : EditorConfig) -> TextEdit? {
  let formatted = format_config(config)
  if formatted == source {
    None
  } else {
    Some({
      start_offset: 0,
      end_offset: source.length(),
      replacement: formatted,
      title: "应用规范化排版",
      safe: true,
    })
  }
}

///|
fn suggested_root_edit(config : EditorConfig) -> TextEdit? {
  if config.root {
    None
  } else {
    Some({
      start_offset: 0,
      end_offset: 0,
      replacement: "root = true\n\n",
      title: "将当前文件设为配置搜索根",
      safe: false,
    })
  }
}

///|
fn utf8_bom_review_edits(config : EditorConfig) -> Array[TextEdit] {
  let edits : Array[TextEdit] = []
  for section in config.sections {
    for property in section.properties {
      if property.key == "charset" && lower_ascii(property.value) == "utf-8-bom" {
        edits.push({
          start_offset: property.span.start.offset,
          end_offset: property.span.end.offset,
          replacement: "charset = utf-8",
          title: "改用无 BOM 的 UTF-8",
          safe: false,
        })
      }
    }
  }
  edits
}

///|
fn sort_edits_descending(edits : Array[TextEdit]) -> Array[TextEdit] {
  let ordered = edits.copy()
  ordered.sort_by((left, right) => right.start_offset - left.start_offset)
  ordered
}

///|
fn ranges_overlap(left : TextEdit, right : TextEdit) -> Bool {
  left.start_offset < right.end_offset && right.start_offset < left.end_offset
}

///|
/// Validate that edits can be applied together without ambiguity.
pub fn validate_edits(
  edits : Array[TextEdit],
  source_length : Int,
) -> Array[String] {
  let errors : Array[String] = []
  for index, edit in edits {
    if edit.start_offset < 0 ||
      edit.end_offset < edit.start_offset ||
      edit.end_offset > source_length {
      errors.push("编辑 `" + edit.title + "` 的范围超出源码边界。")
    }
    for previous in 0..<index {
      if ranges_overlap(edit, edits[previous]) {
        errors.push(
          "编辑 `" +
          edit.title +
          "` 与 `" +
          edits[previous].title +
          "` 的范围重叠。",
        )
      }
    }
  }
  errors
}

///|
/// Apply non-overlapping edits. Call `validate_edits` first for untrusted data.
pub fn apply_edits(source : String, edits : Array[TextEdit]) -> String {
  let output = StringBuilder::new()
  let ordered = sort_edits_descending(edits)
  let mut result = source
  for edit in ordered {
    result = result[:edit.start_offset].to_owned() +
      edit.replacement +
      result[edit.end_offset:].to_owned()
  }
  output.write_string(result)
  output.to_string()
}

///|
/// Build conservative automatic edits and separate review-required proposals.
pub fn plan_fixes(source : String) -> FixPlan {
  let parsed = parse(source)
  let edits : Array[TextEdit] = []
  match canonical_format_edit(source, parsed.config) {
    Some(edit) => edits.push(edit)
    None => ()
  }
  match suggested_root_edit(parsed.config) {
    Some(edit) => edits.push(edit)
    None => ()
  }
  for edit in utf8_bom_review_edits(parsed.config) {
    edits.push(edit)
  }
  let mut safe_count = 0
  let mut review_count = 0
  for edit in edits {
    if edit.safe {
      safe_count += 1
    } else {
      review_count += 1
    }
  }
  let safe_edits : Array[TextEdit] = []
  for edit in edits {
    if edit.safe {
      safe_edits.push(edit)
    }
  }
  let safe_source = if validate_edits(safe_edits, source.length()).length() == 0 {
    apply_edits(source, safe_edits)
  } else {
    source
  }
  {
    edits,
    safe_count,
    review_count,
    safe_source,
    diff: unified_diff(source, safe_source),
  }
}
