// SPDX-License-Identifier: Apache-2.0
//
// agent.disconnect — server-initiated termination of an agent session. Sent
// by relay (or by daemon to a locally-attached agent). Notification (no
// response). See protocol/SPEC.md §6.4.

package schemas

// Reason codes are a closed enum. Adding a value is a MINOR protocol bump
// (per docs/VERSIONING.md §2.2) only if existing recipients are documented to
// gracefully ignore unknown values. They are not; therefore additions are
// MAJOR until the gracefully-ignore guarantee is added in a later version.
#DisconnectReason:
	"version_unsupported" |
	"policy_violation" |
	"idle_timeout" |
	"auth_revoked" |
	"server_shutdown" |
	"client_error"

#AgentDisconnectParams: {
	developer_id: #DeveloperId
	agent_id:     #AgentId
	reason:       #DisconnectReason

	// Optional human-readable detail. Printable ASCII, bounded. Never
	// interpolated into agent prompts (see docs/THREAT_MODEL.md §5).
	detail?: =~"^[\\x20-\\x7e]{0,256}$"
}

#AgentDisconnect: #Notification & {
	method: "agent.disconnect"
	params: #AgentDisconnectParams
}
