// SPDX-License-Identifier: Apache-2.0
//
// agent.register — initial handshake from a newly-attached agent. Sent by
// the daemon to the relay (and locally between adapter and daemon) when an
// agent session begins. The relay responds with a session token and the
// negotiated awareness subscription.

package schemas

// Request params for agent.register.
#AgentRegisterParams: {
	developer_id: #DeveloperId
	agent_id:     #AgentId
	machine_id:   #MachineId
	editor:       #Editor
	session_id:   string & =~"^[0-9a-f-]{36}$" // RFC 4122 UUID, lowercase

	repo:     #RepoUrl
	branch:   #BranchName
	worktree: #WorktreePath

	capabilities: [...#Capability]
}

#AgentRegisterRequest: #Request & {
	method: "agent.register"
	params: #AgentRegisterParams
}

// Response result for agent.register.
#AgentRegisterResult: {
	// Server-issued, opaque session handle. Used in subsequent
	// state.subscribe / msg.send calls for this agent.
	session_token: string & =~"^tap_sess_[A-Za-z0-9_-]{32,}$"

	// Awareness subscription scope the relay accepted. May differ from
	// what the daemon requested if policy narrows it.
	awareness_scope: {
		repo: #RepoUrl
		branches?: [...#BranchName] // empty/absent means all branches
		developers?: [...#DeveloperId] // empty/absent means all team members
	}

	// Negotiated protocol version. May be lower than requested if the
	// relay only supports an older version.
	tap_version: #SemVer
}

#AgentRegisterResponse: #Response & {
	result: #AgentRegisterResult
}
