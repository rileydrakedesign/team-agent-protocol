// SPDX-License-Identifier: Apache-2.0
//
// agent.heartbeat — periodic liveness signal sent at least every 30 s per
// attached agent. Carries optional state delta. Notification (no response).
// See protocol/SPEC.md §6.2.

package schemas

#AgentHeartbeatParams: {
	developer_id: #DeveloperId
	agent_id:     #AgentId

	// Branch the agent is currently attached to. Required: heartbeat doubles
	// as a branch-switch signal.
	branch: #BranchName

	// Number of dirty files in the agent's worktree. Used by relay to flag
	// large in-flight changes for cross-developer awareness.
	dirty_file_count: int & >=0 & <=100_000

	// Optional declared intent, bounded length, control characters forbidden.
	intent?: #Intent

	// Monotonically increasing sequence number per agent. Lets the relay
	// detect missed or reordered heartbeats. Wraps every 2^53.
	sequence: int & >=0
}

#AgentHeartbeat: #Notification & {
	method: "agent.heartbeat"
	params: #AgentHeartbeatParams
}
