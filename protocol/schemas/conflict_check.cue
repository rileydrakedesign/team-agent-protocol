// SPDX-License-Identifier: Apache-2.0
//
// conflict.check — pre-write check returning the highest-confidence conflict
// report available within the latency budget. Request → response. See
// protocol/SPEC.md §8.1.

package schemas

// Single intended-write target. file is required; hunks is optional. When
// hunks is absent, the daemon is asking "is anyone else touching this file at
// all" (Level 1). When hunks is present, the daemon is asking for hunk-level
// (Level 2) and semantic (Level 3) checks too.
#IntendedWrite: {
	file:   #FilePath
	hunks?: [...#Hunk]
}

// Reference to the peer involved in a conflict.
#PeerRef: {
	developer_id: #DeveloperId
	agent_id:     #AgentId
	branch:       #BranchName
}

// Pair of overlapping hunks: the caller's intended hunk plus the peer's
// dirty hunk. Present only for Level 2+ reports.
#HunkOverlap: {
	mine:   #Hunk
	theirs: #Hunk
}

// Single conflict report.
#ConflictReport: {
	level: #ConflictLevel
	with:  #PeerRef
	file:  #FilePath

	// For Level 2+: list of overlapping hunk pairs.
	overlap_hunks?: [...#HunkOverlap]

	// For Level 3 (semantic): the symbol affected.
	symbol?: =~"^[A-Za-z_][A-Za-z0-9_.:]{0,255}$"

	// Confidence score. Level 1 and 2 are exact (1.0). Level 3 may be lower.
	confidence: #Confidence

	// Short, ASCII-bounded human-readable explanation. Never interpolated
	// into agent prompts (sandboxing rule, docs/THREAT_MODEL.md §5).
	message?: =~"^[\\x20-\\x7e]{0,256}$"
}

#ConflictCheckParams: {
	developer_id: #DeveloperId
	agent_id:     #AgentId
	repo:         #RepoUrl
	branch:       #BranchName

	intended_writes: [...#IntendedWrite] & list.MinItems(1)
}

import "list"

#ConflictCheckRequest: #Request & {
	method: "conflict.check"
	params: #ConflictCheckParams
}

#ConflictCheckResult: {
	// Highest level reached within the latency budget. 1 means only the
	// local-cache check ran; 2 means Level 2 also ran; 3+ means semantic
	// analysis ran. The partial flag indicates whether higher levels were
	// requested but timed out.
	level_reached: #ConflictLevel
	partial:       bool

	// Conflict reports, one per affected file × peer. Empty list means no
	// conflicts at the level reached.
	conflicts: [...#ConflictReport]

	// Server timestamp at which the check completed.
	checked_at: #Timestamp
}

#ConflictCheckResponse: #Response & {
	result: #ConflictCheckResult
}
