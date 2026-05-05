// SPDX-License-Identifier: Apache-2.0
//
// conflict.declare — proactive declaration that an agent is about to edit
// specified files / hunks. The declaration is advisory: the relay records it
// in awareness state and surfaces it on subsequent peer conflict.check calls,
// but does not block writes. Request → response. See protocol/SPEC.md §8.2.

package schemas

import "list"
#ConflictDeclareParams: {
	developer_id: #DeveloperId
	agent_id:     #AgentId
	repo:         #RepoUrl
	branch:       #BranchName

	// Files (and optional hunks) being declared.
	targets: [...#IntendedWrite] & list.MinItems(1)

	// Lifetime of the declaration in seconds. Bounded; declarations
	// auto-expire to prevent indefinite locks.
	ttl_seconds: #TtlSeconds

	// Optional ASCII-bounded reason. Advisory.
	reason?: =~"^[\\x20-\\x7e]{0,128}$"
}

#ConflictDeclareRequest: #Request & {
	method: "conflict.declare"
	params: #ConflictDeclareParams
}

#ConflictDeclareResult: {
	// Server-issued declaration handle. Used by conflict.release.
	declaration_id: =~"^tap_decl_[A-Za-z0-9_-]{16,}$"

	// Server timestamp at which the declaration expires.
	expires_at: #Timestamp
}

#ConflictDeclareResponse: #Response & {
	result: #ConflictDeclareResult
}
