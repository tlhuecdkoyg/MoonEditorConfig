///|
/// Explicitly retain the derived methods exposed by earlier compiler versions.
pub extend ConflictKind with @debug.Debug::{to_repr}

///|
pub extend ConflictKind with Eq::{equal, not_equal}

///|
pub extend ConfigConflict with @debug.Debug::{to_repr}

///|
pub extend ConfigConflict with Eq::{equal, not_equal}

///|
pub extend DiffKind with @debug.Debug::{to_repr}

///|
pub extend DiffKind with Eq::{equal, not_equal}

///|
pub extend DiffLine with @debug.Debug::{to_repr}

///|
pub extend DiffLine with Eq::{equal, not_equal}

///|
pub extend DiffHunk with @debug.Debug::{to_repr}

///|
pub extend DiffHunk with Eq::{equal, not_equal}

///|
pub extend TextEdit with @debug.Debug::{to_repr}

///|
pub extend TextEdit with Eq::{equal, not_equal}

///|
pub extend FixPlan with @debug.Debug::{to_repr}

///|
pub extend FixPlan with Eq::{equal, not_equal}

///|
pub extend FormatOptions with @debug.Debug::{to_repr}

///|
pub extend FormatOptions with Eq::{equal, not_equal}

///|
pub extend GlobToken with @debug.Debug::{to_repr}

///|
pub extend GlobToken with Eq::{equal, not_equal}

///|
pub extend GlobProgram with @debug.Debug::{to_repr}

///|
pub extend GlobProgram with Eq::{equal, not_equal}

///|
pub extend GlobMetrics with @debug.Debug::{to_repr}

///|
pub extend GlobMetrics with Eq::{equal, not_equal}

///|
pub extend GlobCase with @debug.Debug::{to_repr}

///|
pub extend GlobCase with Eq::{equal, not_equal}

///|
pub extend SourceLocation with @debug.Debug::{to_repr}

///|
pub extend SourceLocation with Eq::{equal, not_equal}

///|
pub extend SourceSpan with @debug.Debug::{to_repr}

///|
pub extend SourceSpan with Eq::{equal, not_equal}

///|
pub extend Severity with @debug.Debug::{to_repr}

///|
pub extend Severity with Eq::{equal, not_equal}

///|
pub extend Diagnostic with @debug.Debug::{to_repr}

///|
pub extend Diagnostic with Eq::{equal, not_equal}

///|
pub extend Property with @debug.Debug::{to_repr}

///|
pub extend Property with Eq::{equal, not_equal}

///|
pub extend Section with @debug.Debug::{to_repr}

///|
pub extend Section with Eq::{equal, not_equal}

///|
pub extend EditorConfig with @debug.Debug::{to_repr}

///|
pub extend EditorConfig with Eq::{equal, not_equal}

///|
pub extend ParseResult with @debug.Debug::{to_repr}

///|
pub extend ParseResult with Eq::{equal, not_equal}

///|
pub extend ConfigLayer with @debug.Debug::{to_repr}

///|
pub extend ConfigLayer with Eq::{equal, not_equal}

///|
pub extend SectionTrace with @debug.Debug::{to_repr}

///|
pub extend SectionTrace with Eq::{equal, not_equal}

///|
pub extend PropertyStep with @debug.Debug::{to_repr}

///|
pub extend PropertyStep with Eq::{equal, not_equal}

///|
pub extend ResolvedProperty with @debug.Debug::{to_repr}

///|
pub extend ResolvedProperty with Eq::{equal, not_equal}

///|
pub extend Resolution with @debug.Debug::{to_repr}

///|
pub extend Resolution with Eq::{equal, not_equal}

///|
pub extend ParseOptions with @debug.Debug::{to_repr}

///|
pub extend ParseOptions with Eq::{equal, not_equal}

///|
pub extend FindingCategory with @debug.Debug::{to_repr}

///|
pub extend FindingCategory with Eq::{equal, not_equal}

///|
pub extend Finding with @debug.Debug::{to_repr}

///|
pub extend Finding with Eq::{equal, not_equal}

///|
pub extend QualityStats with @debug.Debug::{to_repr}

///|
pub extend QualityStats with Eq::{equal, not_equal}

///|
pub extend QualityReport with @debug.Debug::{to_repr}

///|
pub extend QualityReport with Eq::{equal, not_equal}

///|
pub extend PropertyKind with @debug.Debug::{to_repr}

///|
pub extend PropertyKind with Eq::{equal, not_equal}

///|
pub extend PropertySchema with @debug.Debug::{to_repr}

///|
pub extend PropertySchema with Eq::{equal, not_equal}

///|
pub extend VirtualFile with @debug.Debug::{to_repr}

///|
pub extend VirtualFile with Eq::{equal, not_equal}

///|
pub extend WorkspaceResult with @debug.Debug::{to_repr}

///|
pub extend WorkspaceResult with Eq::{equal, not_equal}
