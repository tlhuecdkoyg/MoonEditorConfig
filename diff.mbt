///|
pub(all) enum DiffKind {
  Unchanged
  Added
  Removed
} derive(Debug, Eq)

///|
pub(all) struct DiffLine {
  kind : DiffKind
  old_line : Int?
  new_line : Int?
  content : String
} derive(Debug, Eq)

///|
pub(all) struct DiffHunk {
  old_start : Int
  old_count : Int
  new_start : Int
  new_count : Int
  lines : Array[DiffLine]
} derive(Debug, Eq)

///|
fn source_lines(source : String) -> Array[String] {
  let lines : Array[String] = []
  if source == "" {
    return lines
  }
  for line in source.split("\n") {
    lines.push(line.to_owned())
  }
  if source.has_suffix("\n") && lines.length() > 0 {
    ignore(lines.pop())
  }
  lines
}

///|
fn lcs_table(left : Array[String], right : Array[String]) -> Array[Array[Int]] {
  let table : Array[Array[Int]] = []
  for _ in 0..<=left.length() {
    let row : Array[Int] = []
    for _ in 0..<=right.length() {
      row.push(0)
    }
    table.push(row)
  }
  for left_index = left.length(); left_index > 0; left_index = left_index - 1 {
    for right_index = right.length()
        right_index > 0
        right_index = right_index - 1 {
      let i = left_index - 1
      let j = right_index - 1
      table[i][j] = if left[i] == right[j] {
        table[i + 1][j + 1] + 1
      } else if table[i + 1][j] >= table[i][j + 1] {
        table[i + 1][j]
      } else {
        table[i][j + 1]
      }
    }
  }
  table
}

///|
/// Compute a deterministic line-oriented diff using a longest common
/// subsequence table. It is intended for configuration-sized documents.
pub fn diff_lines(before : String, after : String) -> Array[DiffLine] {
  let left = source_lines(before)
  let right = source_lines(after)
  let table = lcs_table(left, right)
  let result : Array[DiffLine] = []
  let mut i = 0
  let mut j = 0
  let mut old_line = 1
  let mut new_line = 1
  while i < left.length() || j < right.length() {
    if i < left.length() && j < right.length() && left[i] == right[j] {
      result.push({
        kind: Unchanged,
        old_line: Some(old_line),
        new_line: Some(new_line),
        content: left[i],
      })
      i += 1
      j += 1
      old_line += 1
      new_line += 1
    } else if j < right.length() &&
      (i == left.length() || table[i][j + 1] > table[i + 1][j]) {
      result.push({
        kind: Added,
        old_line: None,
        new_line: Some(new_line),
        content: right[j],
      })
      j += 1
      new_line += 1
    } else {
      result.push({
        kind: Removed,
        old_line: Some(old_line),
        new_line: None,
        content: left[i],
      })
      i += 1
      old_line += 1
    }
  }
  result
}

///|
fn is_changed(line : DiffLine) -> Bool {
  !(line.kind is Unchanged)
}

///|
fn clamp_start(value : Int) -> Int {
  if value < 0 {
    0
  } else {
    value
  }
}

///|
fn hunk_bounds(lines : Array[DiffLine], context : Int) -> Array[(Int, Int)] {
  let bounds : Array[(Int, Int)] = []
  let mut index = 0
  while index < lines.length() {
    if !is_changed(lines[index]) {
      index += 1
      continue
    }
    let start = clamp_start(index - context)
    let mut finish = index + 1
    let mut unchanged_run = 0
    while finish < lines.length() {
      if is_changed(lines[finish]) {
        unchanged_run = 0
      } else {
        unchanged_run += 1
      }
      finish += 1
      if unchanged_run > context * 2 {
        finish -= unchanged_run - context
        break
      }
    }
    if finish > lines.length() {
      finish = lines.length()
    }
    if bounds.length() > 0 {
      let (previous_start, previous_finish) = bounds[bounds.length() - 1]
      if start <= previous_finish {
        bounds[bounds.length() - 1] = (previous_start, finish)
      } else {
        bounds.push((start, finish))
      }
    } else {
      bounds.push((start, finish))
    }
    index = finish
  }
  bounds
}

///|
fn make_hunk(lines : Array[DiffLine], start : Int, finish : Int) -> DiffHunk {
  let selected : Array[DiffLine] = []
  let mut old_start : Int? = None
  let mut new_start : Int? = None
  let mut old_count = 0
  let mut new_count = 0
  for index in start..<finish {
    let line = lines[index]
    selected.push(line)
    if old_start is None && line.old_line is Some(number) {
      old_start = Some(number)
    }
    if new_start is None && line.new_line is Some(number) {
      new_start = Some(number)
    }
    if !(line.kind is Added) {
      old_count += 1
    }
    if !(line.kind is Removed) {
      new_count += 1
    }
  }
  {
    old_start: old_start.unwrap_or(1),
    old_count,
    new_start: new_start.unwrap_or(1),
    new_count,
    lines: selected,
  }
}

///|
/// Group changed lines into unified-diff style hunks.
pub fn diff_hunks(
  before : String,
  after : String,
  context? : Int = 3,
) -> Array[DiffHunk] {
  let lines = diff_lines(before, after)
  let hunks : Array[DiffHunk] = []
  let safe_context = context.clamp(min=0, max=20)
  for bound in hunk_bounds(lines, safe_context) {
    let (start, finish) = bound
    hunks.push(make_hunk(lines, start, finish))
  }
  hunks
}

///|
fn diff_prefix(kind : DiffKind) -> String {
  match kind {
    Unchanged => " "
    Added => "+"
    Removed => "-"
  }
}

///|
/// Render a compact unified diff suitable for terminals and reports.
pub fn unified_diff(
  before : String,
  after : String,
  old_name? : String = "a/.editorconfig",
  new_name? : String = "b/.editorconfig",
  context? : Int = 3,
) -> String {
  if before == after {
    return ""
  }
  let output = StringBuilder::new()
  output.write_string("--- " + old_name + "\n")
  output.write_string("+++ " + new_name + "\n")
  for hunk in diff_hunks(before, after, context~) {
    output.write_string(
      "@@ -" +
      hunk.old_start.to_string() +
      "," +
      hunk.old_count.to_string() +
      " +" +
      hunk.new_start.to_string() +
      "," +
      hunk.new_count.to_string() +
      " @@\n",
    )
    for line in hunk.lines {
      output.write_string(diff_prefix(line.kind) + line.content + "\n")
    }
  }
  output.to_string()
}

///|
/// Show exactly what canonical formatting would change.
pub fn format_diff(source : String) -> String {
  let parsed = parse(source)
  unified_diff(source, format_config(parsed.config))
}
