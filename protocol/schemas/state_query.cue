// SPDX-License-Identifier: Apache-2.0
//
// state.query — request a one-shot awareness snapshot at a given scope.
// Request → response. See protocol/SPEC.md §7.2.

package schemas

#StateQueryParams: {
	scope: #AwarenessScope

	// If set, the relay returns only records updated at or after this time.
	// Lets a reconnecting daemon ask for "what changed while I was offline"
	// without paying for a full snapshot.
	since?: #Timestamp
}

#StateQueryRequest: #Request & {
	method: "state.query"
	params: #StateQueryParams
}

#StateQueryResult: {
	// Records matching the scope (and `since` if set), in unspecified order.
	// Implementations MUST tolerate duplicates within a single result.
	records: [...#AgentAwarenessRecord]

	// Server-current awareness sequence number. Useful as a baseline for a
	// subsequent state.subscribe call to avoid missing diffs.
	server_sequence: int & >=0

	// Server timestamp at which the snapshot was assembled.
	snapshot_at: #Timestamp
}

#StateQueryResponse: #Response & {
	result: #StateQueryResult
}
