// SPDX-License-Identifier: Apache-2.0
//
// Wrapper that exposes the canonical TAP definitions as concrete top-level
// fields so `cue def --out=jsonschema -e CodegenRoot` can reach them and
// emit them as a JSON Schema with `$defs`. This file is purely a build
// artifact for the codegen pipeline (tools/codegen/generate.sh); it
// introduces no new types.
//
// Field names mirror the definition names (without the `#`). CUE's
// jsonschema exporter encodes `#Foo` as a `$defs` key keyed on the literal
// string `#Foo`, which the conformance runners look up via the fixture
// `schema_ref` field.

package schemas

CodegenRoot: {
	// envelope.cue — wire envelope
	Request: #Request

	// agent_register.cue — lifecycle
	AgentRegisterRequest:  #AgentRegisterRequest
	AgentRegisterResponse: #AgentRegisterResponse

	// agent_heartbeat.cue — lifecycle
	AgentHeartbeat: #AgentHeartbeat

	// agent_deregister.cue — lifecycle
	AgentDeregister: #AgentDeregister

	// agent_disconnect.cue — lifecycle
	AgentDisconnect: #AgentDisconnect

	// state_announce.cue — awareness
	StateAnnounce: #StateAnnounce

	// state_query.cue — awareness
	StateQueryRequest:  #StateQueryRequest
	StateQueryResponse: #StateQueryResponse

	// state_subscribe.cue — awareness
	StateSubscribeRequest:  #StateSubscribeRequest
	StateSubscribeResponse: #StateSubscribeResponse

	// state_diff.cue — awareness
	StateDiff: #StateDiff

	// conflict_check.cue — conflict
	ConflictCheckRequest:  #ConflictCheckRequest
	ConflictCheckResponse: #ConflictCheckResponse

	// conflict_declare.cue — conflict
	ConflictDeclareRequest:  #ConflictDeclareRequest
	ConflictDeclareResponse: #ConflictDeclareResponse

	// conflict_release.cue — conflict
	ConflictRelease: #ConflictRelease

	// conflict_notify.cue — conflict
	ConflictNotify: #ConflictNotify
}
