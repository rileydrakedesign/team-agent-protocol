// SPDX-License-Identifier: Apache-2.0
//
// state.subscribe — open a long-lived subscription to awareness state.
// Request → response; subsequent state.diff notifications stream over the
// existing connection. See protocol/SPEC.md §7.3.

package schemas

#StateSubscribeParams: {
	scope: #AwarenessScope

	// Optional baseline sequence. If set and known to the relay, the relay
	// streams the diffs since that sequence rather than a full snapshot.
	// If unknown (e.g., too old), the relay returns a fresh snapshot in
	// the response and starts streaming from server_sequence.
	since_sequence?: int & >=0
}

#StateSubscribeRequest: #Request & {
	method: "state.subscribe"
	params: #StateSubscribeParams
}

#StateSubscribeResult: {
	// Opaque subscription identifier. Carried on every state.diff for this
	// subscription.
	subscription_id: #SubscriptionId

	// Snapshot of records matching the scope at subscription time. Empty if
	// since_sequence was supplied and is still in the relay's diff window.
	snapshot: [...#AgentAwarenessRecord]

	// Server-current sequence at subscription time. The first state.diff
	// will carry sequence == server_sequence + 1.
	server_sequence: int & >=0
}

#StateSubscribeResponse: #Response & {
	result: #StateSubscribeResult
}
