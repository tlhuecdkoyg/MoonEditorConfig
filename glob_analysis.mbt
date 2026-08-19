///|
pub(all) struct GlobMetrics {
  literals : Int
  separators : Int
  single_wildcards : Int
  recursive_wildcards : Int
  character_classes : Int
  alternatives : Int
  estimated_states : Int
  matches_directories : Bool
} derive(Debug, Eq)

///|
pub(all) struct GlobCase {
  path : String
  matched : Bool
  explanation : String
} derive(Debug, Eq)

///|
fn token_metrics(token : GlobToken, metrics : GlobMetrics) -> GlobMetrics {
  match token {
    Literal(_) => { ..metrics, literals: metrics.literals + 1 }
    Separator =>
      {
        ..metrics,
        separators: metrics.separators + 1,
        matches_directories: true,
      }
    AnyCharacter | AnySegment =>
      { ..metrics, single_wildcards: metrics.single_wildcards + 1 }
    AnyPath =>
      {
        ..metrics,
        recursive_wildcards: metrics.recursive_wildcards + 1,
        matches_directories: true,
      }
    CharacterClass(..) =>
      { ..metrics, character_classes: metrics.character_classes + 1 }
  }
}

///|
/// Measure a glob's structural complexity for diagnostics and UI display.
pub fn analyze_glob(pattern : String) -> GlobMetrics {
  let program = compile_glob(pattern)
  let mut metrics : GlobMetrics = {
    literals: 0,
    separators: 0,
    single_wildcards: 0,
    recursive_wildcards: 0,
    character_classes: 0,
    alternatives: program.alternatives.length(),
    estimated_states: 0,
    matches_directories: false,
  }
  for alternative in program.alternatives {
    for token in alternative {
      metrics = token_metrics(token, metrics)
    }
  }
  let wildcard_factor = 1 +
    metrics.single_wildcards * 2 +
    metrics.recursive_wildcards * 5
  metrics = {
    ..metrics,
    estimated_states: (metrics.literals + metrics.separators + 1) *
    wildcard_factor *
    metrics.alternatives,
  }
  metrics
}

///|
/// A stable score used only to compare how specific two matching patterns are.
pub fn glob_specificity(pattern : String) -> Int {
  let metrics = analyze_glob(pattern)
  metrics.literals * 10 +
  metrics.character_classes * 4 +
  metrics.separators * 2 -
  metrics.single_wildcards * 3 -
  metrics.recursive_wildcards * 8 -
  (metrics.alternatives - 1) * 2
}

///|
/// Evaluate a pattern against many paths while retaining explanations.
pub fn evaluate_glob(
  pattern : String,
  paths : Array[String],
) -> Array[GlobCase] {
  let cases : Array[GlobCase] = []
  for path in paths {
    let matched = glob_matches(pattern, path)
    cases.push({ path, matched, explanation: explain_glob(pattern, path) })
  }
  cases
}

///|
fn replace_token_samples(
  tokens : Array[GlobToken],
  wildcard : String,
) -> String {
  let output = StringBuilder::new()
  for token in tokens {
    match token {
      Literal(code) => output.write_char(code.unsafe_to_char())
      Separator => output.write_char('/')
      AnyCharacter => output.write_char('x')
      AnySegment => output.write_string(wildcard)
      AnyPath => output.write_string("dir/" + wildcard)
      CharacterClass(chars~, ranges~, negated~) =>
        if negated {
          output.write_char('x')
        } else if chars.length() > 0 {
          output.write_char(chars[0].unsafe_to_char())
        } else if ranges.length() > 0 {
          output.write_char(ranges[0].0.unsafe_to_char())
        } else {
          output.write_char('x')
        }
    }
  }
  output.to_string()
}

///|
/// Generate deterministic examples that help users understand a pattern.
pub fn glob_examples(pattern : String) -> Array[String] {
  let program = compile_glob(pattern)
  let examples : Array[String] = []
  for tokens in program.alternatives {
    for wildcard in ["x", "sample", "long-name"] {
      let candidate = replace_token_samples(tokens, wildcard)
      if glob_matches(pattern, candidate) &&
        !examples.any(existing => existing == candidate) {
        examples.push(candidate)
      }
    }
  }
  examples
}

///|
/// Look for concrete evidence that two patterns overlap by generating examples
/// from each side. `None` means no witness was found, not a formal proof.
pub fn glob_overlap_witness(left : String, right : String) -> String? {
  let candidates = glob_examples(left)
  for candidate in glob_examples(right) {
    if !candidates.any(existing => existing == candidate) {
      candidates.push(candidate)
    }
  }
  for candidate in candidates {
    if glob_matches(left, candidate) && glob_matches(right, candidate) {
      return Some(candidate)
    }
  }
  None
}

///|
/// Detect patterns whose state space deserves review. The matcher is memoized,
/// so this is a maintainability signal rather than a vulnerability verdict.
pub fn glob_complexity_warning(
  pattern : String,
  threshold? : Int = 500,
) -> String? {
  let metrics = analyze_glob(pattern)
  if metrics.estimated_states > threshold {
    Some(
      "Glob 估算状态数为 " +
      metrics.estimated_states.to_string() +
      "，建议拆分复杂的通配与选择表达式。",
    )
  } else {
    None
  }
}
