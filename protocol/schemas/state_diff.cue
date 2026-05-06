// SPDX-License-Identifier: Apache-2.0
//
// state.diff — server-pushed delta for an active subscription. Notification
// (no response). See protocol/SPEC.md §7.4.

package schemas

import "list"

// Kind of a single state-diff change.
//
// - agent_attached: a new agent appeared in the subscription's scope.
// - agent_detached: an agent left the scope (deregister, disconnect).
// - state_changed:  an existing agent's record was updated (branch switch,
//                   dirty-file change, intent change).
#StateDiffChangeKind: "agent_attached" | "agent_detached" | "state_changed"

// Single change within a state.diff payload.
#StateDiffChange: {
	kind: #StateDiffChangeKind

	// Identifies the affected agent. Always present.
	developer_id: #DeveloperId
	agent_id:     #AgentId

	// For agent_attached and state_changed, the full current record.
	// For agent_detached, MUST be absent.
	record?: #AgentAwarenessRecord

	// For agent_detached, optional reason (e.g., "deregister",
	// "disconnect:idle_timeout"). Advisory.
	reason?: =~"^[a-z][a-z0-9_:-]{0,64}$"
}

#StateDiffParams: {
	subscription_id: #SubscriptionId

	// Monotonically increasing per-subscription sequence. Recipients MUST
	// detect gaps and reconcile via state.query.
	sequence: int & >=0

	// Server timestamp of the change set.
	emitted_at: #Timestamp

	// One or more changes. Ordering within the list is not significant;
	// recipients MUST treat the list as a set.
	changes: [...#StateDiffChange] & list.MinItems(1)
}

#StateDiff: #Notification & {
	method: "state.diff"
	params: #StateDiffParams
}
