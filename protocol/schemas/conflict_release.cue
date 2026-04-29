// SPDX-License-Identifier: Apache-2.0
//
// conflict.release — release a previously-declared conflict. Notification
// (no response). The relay removes the declaration from awareness state
// within 5 seconds. Declarations also expire automatically per their
// ttl_seconds; release is purely an optimization. See protocol/SPEC.md §8.3.

package schemas

#ConflictReleaseParams: {
	developer_id:   #DeveloperId
	agent_id:       #AgentId
	declaration_id: =~"^tap_decl_[A-Za-z0-9_-]{16,}$"
}

#ConflictRelease: #Notification & {
	method: "conflict.release"
	params: #ConflictReleaseParams
}
