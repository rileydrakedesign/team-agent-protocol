# TAP Protocol Specification

**Version:** 0.1.0-draft
**Status:** Draft. Phase 1. Not yet stabilized.
**Source of truth:** the CUE schemas in [`schemas/`](schemas/) take precedence over prose in this document. Discrepancies between this document and the CUE schemas should be treated as bugs in this document.

This specification defines TAP — the Team Agent Protocol — a JSON-RPC 2.0 wire protocol for cross-developer AI agent coordination. TAP is conformant with [Google Agent2Agent (A2A)](https://github.com/google/agent2agent) for identity and discovery, and extends A2A with development-specific message types for awareness, conflict prevention, messaging, consults, and task handoff.

This document is normative. Where prose says MUST, MUST NOT, SHOULD, SHOULD NOT, MAY, the meanings follow [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119) and [RFC 8174](https://datatracker.ietf.org/doc/html/rfc8174).

---

## Table of contents

1. [Overview](#1-overview)
2. [Transport](#2-transport)
3. [Envelope](#3-envelope)
4. [Identity](#4-identity)
5. [Versioning](#5-versioning)
6. [Lifecycle messages](#6-lifecycle-messages)
7. [Awareness messages](#7-awareness-messages)
8. [Conflict messages](#8-conflict-messages)
9. [Messaging](#9-messaging)
10. [Consults](#10-consults)
11. [Tasks](#11-tasks)
12. [Policy and trust](#12-policy-and-trust)
13. [Errors](#13-errors)
14. [Conformance](#14-conformance)

---

## 1. Overview

A TAP-conformant deployment consists of:

- One or more **agents**, each running inside an editor (Claude Code, Cursor, Codex, Aider, or any MCP-speaking client).
- One **daemon** per developer machine, multi-tenant across editors and agents. Owns local git state and the secure connection to the relay.
- One **relay** per organization (hosted or self-hosted), providing identity, presence, awareness, routing, conflict detection, and consult coordination.

Agents speak TAP to the daemon over a Unix socket / named pipe. Daemons speak TAP to the relay over WSS with mTLS. Both use the same JSON-RPC 2.0 envelope.

Phase 1 of TAP scope (this document) covers lifecycle, awareness, and conflict messages. Messaging, consults, tasks, policy, and trust messages will be specified incrementally as their implementations are built; their schemas exist in `schemas/` only when the spec text in this document covers them.

## 2. Transport

### 2.1 Daemon ↔ Relay

- Transport: WSS (RFC 6455) over TCP.
- Authentication: mTLS with daemon-side pinned CA, plus a JWT bearer token in the WebSocket subprotocol handshake. The JWT is issued by the relay's identity service.
- Framing: one TAP envelope per WebSocket text frame. Binary frames MUST be rejected.
- Heartbeats: the daemon MUST send `agent.heartbeat` at least every 30 seconds per attached agent. The relay MAY treat 90 seconds of silence as a missed heartbeat and emit `agent.disconnect`.

### 2.2 Daemon ↔ Agent

- Transport: Unix domain socket on Linux/macOS, named pipe on Windows.
- Authentication: process-local trust boundary; no transport-level auth.
- Framing: identical to §2.1 (one TAP envelope per message, JSON-encoded).
- Discovery: daemon writes its socket path to `$TAP_DAEMON_SOCKET` and to `$XDG_RUNTIME_DIR/tap/daemon.sock` (Linux) / `~/Library/Application Support/tap/daemon.sock` (macOS).

### 2.3 TLS

The relay MUST present a certificate validated against the daemon's pinned CA. Daemons MUST NOT fall back to system trust. CA pinning is configured in `~/.tap/config.toml`.

## 3. Envelope

Every TAP message is a JSON object conforming to [`schemas/envelope.cue`](schemas/envelope.cue). The CUE definitions are normative; this section is summary.

| Field | Type | Required | Notes |
|---|---|---|---|
| `jsonrpc` | string | yes | Always `"2.0"` |
| `tap_version` | semver string | yes | Negotiated at handshake |
| `trace_id` | 32-char lowercase hex | yes | W3C Trace Context-compatible |
| `id` | string \| number \| null | requests/responses | Absent on notifications |
| `method` | string | requests/notifications | TAP method name |
| `params` | object | requests/notifications | Method-specific |
| `result` | object | success responses | Method-specific |
| `error` | object | error responses | See §13 |

Implementations MUST reject messages that fail CUE schema validation. The reference conformance suite (§14) enumerates required negative test cases.

## 4. Identity

See [`schemas/identity.cue`](schemas/identity.cue) for the normative shape of each identifier.

### 4.1 Developer ID

Per-user, lowercased. Phase 1 derives from the GitHub login obtained via OAuth Device Flow. Enterprise deployments MAY substitute a SAML/OIDC subject claim.

### 4.2 Agent ID

Per-session, ephemeral. Derived as `blake3(developer_id || machine_id || editor || session_id)`, hex-encoded, 64 characters. Re-issued on every session.

### 4.3 Machine ID

Per-workstation, stable across daemon restarts. Locally generated; never re-used after a workstation is decommissioned.

### 4.4 Repo identity

Canonical repo URL plus org membership. The relay normalizes URLs (lowercased host, stripped `.git` suffix) before comparing.

### 4.5 Trust pairs

Directed (developer → developer) trust state, controlling auto-acceptance of inbound messages and consults at given scope levels. Specified in §12.

## 5. Versioning

TAP uses semantic versioning. The version triple is `MAJOR.MINOR.PATCH`.

- **MAJOR** version increments on backward-incompatible changes to the envelope or message semantics.
- **MINOR** version increments on backward-compatible additions (new messages, new optional fields).
- **PATCH** version increments on documentation or schema clarifications that do not change wire format.

Negotiation happens at handshake. The relay MUST support the current major version and the previous major version. A daemon connecting with an unsupported version MUST receive an `agent.disconnect` with reason `version_unsupported`.

## 6. Lifecycle messages

### 6.1 `agent.register` (request)

Sent by an agent (via daemon) on session start. Schema in [`schemas/agent_register.cue`](schemas/agent_register.cue).

- Direction: agent → daemon → relay.
- Idempotent: repeated registration with the same `agent_id` returns the same `session_token`.
- Side effects: agent is added to presence, awareness subscription is established, an entry is appended to the audit log.

### 6.2 `agent.heartbeat` (notification)

Periodic liveness signal. Carries optional state delta (current branch, dirty file count). Sent at least every 30 seconds while the agent is attached.

### 6.3 `agent.deregister` (notification)

Sent on clean shutdown. The relay removes the agent from presence within 5 seconds.

### 6.4 `agent.disconnect` (server-initiated notification)

Sent by relay or daemon to terminate a session. Carries a `reason` field: `version_unsupported`, `policy_violation`, `idle_timeout`, `auth_revoked`, `server_shutdown`, `client_error`.

## 7. Awareness messages

*(To be specified in §7 alongside the daemon's awareness subsystem implementation. See `project-context.md` §9.3.)*

- `state.announce`
- `state.query`
- `state.subscribe`
- `state.diff`

## 8. Conflict messages

*(To be specified in §8 alongside the conflict detection engine.)*

- `conflict.check`
- `conflict.declare`
- `conflict.release`
- `conflict.notify`

## 9. Messaging

*(Phase 4. Not specified in this draft.)*

## 10. Consults

*(Phase 4. Not specified in this draft.)*

## 11. Tasks

*(Phase 4. Not specified in this draft.)*

## 12. Policy and trust

*(Phase 4. Not specified in this draft.)*

## 13. Errors

JSON-RPC 2.0 error codes -32768 through -32000 are reserved for transport-level errors. TAP-specific application errors use codes in the range 1000–9999.

| Code | Name | Meaning |
|---|---|---|
| -32700 | Parse error | Malformed JSON |
| -32600 | Invalid request | Envelope failed schema validation |
| -32601 | Method not found | Unknown method name |
| -32602 | Invalid params | Params failed method-specific schema validation |
| -32603 | Internal error | Server-side bug |
| 1001 | Version unsupported | TAP version not supported by peer |
| 1002 | Auth required | JWT missing or expired |
| 1003 | Auth invalid | JWT failed verification |
| 1010 | Rate limited | Per-developer or per-agent rate limit exceeded |
| 1020 | Policy denied | Local or relay policy rejected the request |
| 1030 | Repo not opted in | Caller is not a member of the repo's team |
| 1040 | Scope exceeded | Requested scope above caller's trust level |

The full error code registry is maintained in this document and MUST be updated whenever a new code is introduced.

## 14. Conformance

A conformant TAP implementation MUST pass every fixture in [`conformance/`](conformance/). The fixture format is described in [`conformance/README.md`](conformance/README.md).

The conformance suite is part of this specification. Changes to the suite require the same review process as changes to this document. Implementations that pass the suite may use the TAP trademark as documented in `docs/GOVERNANCE.md`.

---

## Appendix A — Change log

- *2026-04-28:* Draft skeleton established; lifecycle messages (`agent.register`, `agent.heartbeat`, `agent.deregister`, `agent.disconnect`) specified; envelope and identity schemas committed.
