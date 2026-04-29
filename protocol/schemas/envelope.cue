// SPDX-License-Identifier: Apache-2.0
//
// TAP wire envelope. Every message exchanged over WSS (daemon ↔ relay) or
// over the local Unix socket / named pipe (daemon ↔ agent) is a JSON-RPC 2.0
// frame extended with TAP-specific fields. Negotiated at handshake; relay
// supports current and previous major version.

package schemas

// SemVer string. Conformance fixtures may pin to specific versions.
#SemVer: =~"^(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)(?:-[0-9A-Za-z-.]+)?(?:\\+[0-9A-Za-z-.]+)?$"

// 128-bit hex trace ID, lowercase. Compatible with W3C Trace Context.
#TraceID: =~"^[0-9a-f]{32}$"

// JSON-RPC 2.0 message id. May be string, integer, or null.
#JSONRPCId: string | int | null

// All TAP messages share these fields. Concrete request/response/notification
// shapes refine #Envelope further.
#Envelope: {
	jsonrpc: "2.0"
	tap_version: #SemVer
	trace_id: #TraceID
	...
}

// Request: client→server method invocation expecting a response.
#Request: #Envelope & {
	id:     #JSONRPCId & !=null
	method: string & !=""
	params?: {...}
}

// Notification: client→server method invocation that does not expect a
// response. Distinguished from #Request by the absence of `id`.
#Notification: #Envelope & {
	method: string & !=""
	params?: {...}
}

// Response: server→client successful response to a request.
#Response: #Envelope & {
	id:     #JSONRPCId
	result: {...}
}

// ErrorResponse: server→client failure response to a request.
#ErrorResponse: #Envelope & {
	id:    #JSONRPCId
	error: #Error
}

// Standard JSON-RPC 2.0 error codes are reserved (-32768 through -32000).
// TAP-specific errors use codes outside that range; canonical codes are
// listed in protocol/SPEC.md §Errors.
#Error: {
	code:    int
	message: string
	data?:   _
}
