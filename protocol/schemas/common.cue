// SPDX-License-Identifier: Apache-2.0
//
// Shared types used across multiple TAP messages. Anything reused by two or
// more message schemas lives here. Identity-specific types live in
// identity.cue; the JSON-RPC envelope lives in envelope.cue.

package schemas

import "list"

// RFC 3339 UTC timestamp. Always Zulu-suffixed for canonical form.
#Timestamp: =~"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\\.[0-9]{1,9})?Z$"

// Free-text intent declared by an agent. Bounded length; printable ASCII +
// common Unicode. Defends against control-character smuggling per
// docs/THREAT_MODEL.md §5.
#Intent: =~"^[^\\x00-\\x1f\\x7f]{0,256}$"

// Path within a repository worktree. Relative to the repo root, forward
// slashes only, no leading slash, no '..' traversal, no NUL bytes.
//
// Length cap is 999 (not 1024) so the regex compiles in Go's regexp/RE2
// engine, which rejects bounded counts >= 1000. Paths longer than 1KB are
// vanishingly rare in real codebases.
#FilePath: =~"^[A-Za-z0-9._-][A-Za-z0-9._/-]{0,999}$" & !~"\\.\\./" & !~"^\\.\\.$" & !~"/\\.\\./"

// 1-indexed inclusive line number within a file.
#LineNumber: int & >=1 & <=2_000_000

// Hunk operation kind.
#HunkOp: "insert" | "delete" | "modify"

// A contiguous range of affected lines plus its operation kind. Both bounds
// inclusive; for pure insertions, end_line == start_line and op == "insert".
//
// The cross-field invariant `end_line >= start_line` is documented in the
// spec text but not enforced at the wire-schema layer because JSON Schema
// cannot express comparisons between sibling fields. The TAP daemon enforces
// it before accepting a hunk; the conformance suite covers it via fixtures.
#Hunk: {
	start_line: #LineNumber
	end_line:   #LineNumber
	op:         #HunkOp
}

// Set of dirty hunks in a single file.
#DirtyFile: {
	file:  #FilePath
	hunks: [...#Hunk] & list.MinItems(1)
}

// Awareness scope: which slices of awareness state a request applies to.
// At least `repo` is required. Empty/absent `branches` or `developers` means
// "all" within the scope of the caller's repo membership.
#AwarenessScope: {
	repo:        #RepoUrl
	branches?:   [...#BranchName]
	developers?: [...#DeveloperId]
}

// Subscription identifier issued by the relay on state.subscribe. Opaque to
// daemons; the relay uses it to correlate state.diff notifications.
#SubscriptionId: =~"^tap_sub_[A-Za-z0-9_-]{16,}$"

// Conflict-detection level. Cf. project-context.md §7.
#ConflictLevel: 1 | 2 | 3 | 4

// Per-conflict confidence. Level 1/2 are exact (1.0); Level 3/4 may be lower.
#Confidence: float & >=0.0 & <=1.0

// TTL for declared conflicts, in seconds. Bounded to prevent indefinite locks.
#TtlSeconds: int & >=1 & <=3600
