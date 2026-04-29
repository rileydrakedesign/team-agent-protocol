// SPDX-License-Identifier: Apache-2.0
//
// agent.deregister — sent by an agent on clean shutdown. Notification (no
// response). The relay removes the agent from presence within 5 seconds.
// See protocol/SPEC.md §6.3.

package schemas

#AgentDeregisterParams: {
	developer_id: #DeveloperId
	agent_id:     #AgentId

	// Free-form short reason. Advisory; relay does not interpret.
	reason?: =~"^[a-z][a-z0-9_]{0,31}$"
}

#AgentDeregister: #Notification & {
	method: "agent.deregister"
	params: #AgentDeregisterParams
}
