// SPDX-License-Identifier: Apache-2.0
//
// conflict.notify — server-pushed notification of a newly detected conflict
// affecting the recipient's branch. Notification (no response). See
// protocol/SPEC.md §8.4.

package schemas

import "list"

#ConflictNotifyParams: {
	// The agent the notification targets.
	developer_id: #DeveloperId
	agent_id:     #AgentId

	// The repo and branch the conflict affects.
	repo:   #RepoUrl
	branch: #BranchName

	// Server timestamp at detection.
	detected_at: #Timestamp

	// Conflict reports; at least one. Reuses the #ConflictReport type from
	// conflict.check for ergonomic consistency.
	conflicts: [...#ConflictReport] & list.MinItems(1)
}

#ConflictNotify: #Notification & {
	method: "conflict.notify"
	params: #ConflictNotifyParams
}
