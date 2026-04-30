// SPDX-License-Identifier: Apache-2.0
//
// state.announce — an agent declares its current branch state. Sent by the
// daemon to the relay (and locally between adapter and daemon) whenever the
// daemon's git state engine detects a meaningful change. Notification (no
// response). See protocol/SPEC.md §7.1.

package schemas

// Per-(developer, agent) awareness record. Reused by state.announce,
// state.query result, state.subscribe result, and state.diff payloads.
#AgentAwarenessRecord: {
	developer_id: #DeveloperId
	agent_id:     #AgentId

	branch:   #BranchName
	worktree: #WorktreePath

	// Dirty files, including their hunk ranges. Empty list means the
	// worktree has no uncommitted modifications.
	dirty_files: [...#DirtyFile]

	// Optional declared intent, bounded length, control characters forbidden.
	intent?: #Intent

	// Wall-clock timestamps maintained by the relay; daemons MAY emit them
	// as hints but the relay's values are authoritative on read.
	attached_at?:       #Timestamp
	last_heartbeat_at?: #Timestamp
}

#StateAnnounceParams: {
	repo:   #RepoUrl
	record: #AgentAwarenessRecord

	// Daemon-side monotonically increasing sequence number, separate from
	// the per-agent heartbeat sequence. Lets the relay detect dropped
	// announcements.
	sequence: int & >=0
}

#StateAnnounce: #Notification & {
	method: "state.announce"
	params: #StateAnnounceParams
}
