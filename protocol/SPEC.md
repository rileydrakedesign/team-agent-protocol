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

Lifecycle messages establish, maintain, and terminate an agent's connection. Every TAP session begins with `agent.register` and ends with either `agent.deregister` (clean) or `agent.disconnect` (server-initiated).

Free-text fields in lifecycle messages (`intent`, `detail`, `reason`) MUST NOT be interpolated into any agent prompt by recipient implementations. The mandatory sandboxing rule is specified in [`../docs/THREAT_MODEL.md`](../docs/THREAT_MODEL.md) §5.

### 6.1 `agent.register` (request → response)

Sent by an agent (via daemon) on session start. Schema in [`schemas/agent_register.cue`](schemas/agent_register.cue).

- **Direction.** Agent → daemon → relay. Local socket frame to the daemon; WSS frame to the relay.
- **Idempotency.** Repeated registration with the same `agent_id` returns the same `session_token`. Re-registering with a new `session_id` yields a new `agent_id` (per §4.2 derivation).
- **Side effects.** The agent is added to presence (§7); an awareness subscription is established at the negotiated scope; an entry is appended to the audit log.

#### Request params

| Field | Type | Required | Notes |
|---|---|---|---|
| `developer_id` | string | yes | §4.1. |
| `agent_id` | string | yes | §4.2. |
| `machine_id` | string | yes | §4.3. |
| `editor` | string | yes | `claude-code`, `cursor`, `codex`, `aider`, `generic-mcp`, or future-allocated. |
| `session_id` | UUID | yes | RFC 4122 v4. |
| `repo` | string | yes | Canonical repo URL per §4.4. |
| `branch` | string | yes | Git branch name; restricted character set per schema. |
| `worktree` | string | yes | Absolute path. |
| `capabilities` | string[] | yes | Advisory; routed through to peers. |

#### Response result

| Field | Type | Required | Notes |
|---|---|---|---|
| `session_token` | string | yes | Opaque relay-issued handle, prefix `tap_sess_`. |
| `awareness_scope.repo` | string | yes | Echo of the registered repo. |
| `awareness_scope.branches` | string[] | no | Empty or absent means all branches. |
| `awareness_scope.developers` | string[] | no | Empty or absent means all team members. |
| `tap_version` | semver | yes | Negotiated; may be lower than requested per [`../docs/VERSIONING.md`](../docs/VERSIONING.md) §3. |

### 6.2 `agent.heartbeat` (notification)

Periodic liveness signal. Schema in [`schemas/agent_heartbeat.cue`](schemas/agent_heartbeat.cue).

- **Direction.** Agent → daemon → relay.
- **Cadence.** The daemon MUST send `agent.heartbeat` at least every 30 seconds per attached agent. The relay MAY treat 90 seconds of silence as missed and emit `agent.disconnect` with `reason: idle_timeout`.
- **Sequence.** `params.sequence` is monotonically increasing per agent. The relay MAY use it to detect missed or reordered heartbeats.

#### Params

| Field | Type | Required | Notes |
|---|---|---|---|
| `developer_id` | string | yes | §4.1. |
| `agent_id` | string | yes | §4.2. |
| `branch` | string | yes | Current branch; doubles as a branch-switch signal. |
| `dirty_file_count` | int | yes | Non-negative; bounded ≤ 100,000. |
| `intent` | string | no | Bounded length; ASCII control characters forbidden by schema. |
| `sequence` | int | yes | Monotonically increasing. |

### 6.3 `agent.deregister` (notification)

Clean-shutdown notification. Schema in [`schemas/agent_deregister.cue`](schemas/agent_deregister.cue).

- **Direction.** Agent → daemon → relay.
- **Effect.** The relay MUST remove the agent from presence within 5 seconds. Messages addressed to the agent after deregistration are routed to its durable inbox (specified in Phase 4).

#### Params

| Field | Type | Required | Notes |
|---|---|---|---|
| `developer_id` | string | yes | §4.1. |
| `agent_id` | string | yes | §4.2. |
| `reason` | string | no | Lowercase snake_case, ≤ 32 chars. Advisory; relay does not interpret. |

### 6.4 `agent.disconnect` (server-initiated notification)

Server-initiated termination. Schema in [`schemas/agent_disconnect.cue`](schemas/agent_disconnect.cue).

- **Direction.** Relay → daemon → agent (or daemon → agent locally).
- **Effect.** The recipient MUST close its session immediately. The daemon SHOULD surface `detail` to the developer (e.g., desktop notification) but MUST NOT route `detail` into any agent prompt.

#### Params

| Field | Type | Required | Notes |
|---|---|---|---|
| `developer_id` | string | yes | §4.1. |
| `agent_id` | string | yes | §4.2. |
| `reason` | enum | yes | Closed enum: `version_unsupported`, `policy_violation`, `idle_timeout`, `auth_revoked`, `server_shutdown`, `client_error`. |
| `detail` | string | no | Printable ASCII, ≤ 256 chars. |

Adding a `reason` value is a MAJOR bump until v0.2 introduces a gracefully-ignore-unknown guarantee, per [`../docs/VERSIONING.md`](../docs/VERSIONING.md) §2.2.

## 7. Awareness messages

Awareness messages establish and maintain a shared view of which agents are working on which branches and files. Awareness state is per-(repo, developer, agent); the relay aggregates announcements from every connected daemon and pushes diffs to every active subscription whose scope matches.

The `#AgentAwarenessRecord` type in [`schemas/state_announce.cue`](schemas/state_announce.cue) is the unit of awareness data. It is reused by every method in this section.

Free-text fields in awareness records (`intent`) MUST NOT be interpolated into any agent prompt. The mandatory sandboxing rule is specified in [`../docs/THREAT_MODEL.md`](../docs/THREAT_MODEL.md) §5.

### 7.1 `state.announce` (notification)

An agent declares its current branch state. Schema in [`schemas/state_announce.cue`](schemas/state_announce.cue).

- **Direction.** Agent → daemon → relay.
- **When emitted.** Whenever the daemon's git state engine detects a meaningful change (branch switch, dirty-file change, intent update). Implementations SHOULD debounce.
- **Sequence.** `params.sequence` is monotonically increasing per (developer, agent). Lets the relay detect dropped announcements.

#### Params

| Field | Type | Required | Notes |
|---|---|---|---|
| `repo` | string | yes | Canonical repo URL. |
| `record` | object | yes | `#AgentAwarenessRecord`. |
| `sequence` | int | yes | Monotonically increasing per (developer, agent). |

`record.dirty_files` MAY be empty (clean worktree). `record.intent` is optional. Hunk ranges MUST satisfy `end_line >= start_line`; the schema rejects inverted ranges.

### 7.2 `state.query` (request → response)

Request a one-shot awareness snapshot at a given scope. Schema in [`schemas/state_query.cue`](schemas/state_query.cue).

- **Direction.** Daemon → relay.
- **Scoping.** The relay enforces repo membership on every query. Cross-repo queries require an explicit policy grant (Phase 4).
- **Incremental fetch.** If `since` is set, the relay returns only records updated at or after that timestamp.

#### Request params

| Field | Type | Required | Notes |
|---|---|---|---|
| `scope.repo` | string | yes | Required. Absence fails closed. |
| `scope.branches` | string[] | no | Empty/absent means all branches. |
| `scope.developers` | string[] | no | Empty/absent means all team members. |
| `since` | timestamp | no | RFC 3339 UTC. Returns only records updated at or after. |

#### Response result

| Field | Type | Required | Notes |
|---|---|---|---|
| `records` | object[] | yes | `#AgentAwarenessRecord[]`. May be empty. May contain duplicates within a single result; recipients MUST tolerate. |
| `server_sequence` | int | yes | Server-current awareness sequence at snapshot time. |
| `snapshot_at` | timestamp | yes | Server timestamp at which the snapshot was assembled. |

### 7.3 `state.subscribe` (request → response)

Open a long-lived subscription. Schema in [`schemas/state_subscribe.cue`](schemas/state_subscribe.cue).

- **Direction.** Daemon → relay.
- **Effect.** The relay returns an immediate snapshot in the response, allocates a `subscription_id`, and begins streaming `state.diff` notifications over the same connection.
- **Resumption.** If `since_sequence` is supplied and is still in the relay's diff window, the snapshot in the response is empty and the diffs cover the gap. Otherwise the relay falls back to a full snapshot.

#### Request params

| Field | Type | Required | Notes |
|---|---|---|---|
| `scope.repo` | string | yes | Required. |
| `scope.branches` | string[] | no | |
| `scope.developers` | string[] | no | |
| `since_sequence` | int | no | Resume from this sequence if known. |

#### Response result

| Field | Type | Required | Notes |
|---|---|---|---|
| `subscription_id` | string | yes | Opaque, prefix `tap_sub_`. |
| `snapshot` | object[] | yes | `#AgentAwarenessRecord[]`. May be empty when resuming. |
| `server_sequence` | int | yes | First subsequent `state.diff` carries `sequence == server_sequence + 1`. |

### 7.4 `state.diff` (server-pushed notification)

Server-pushed delta for an active subscription. Schema in [`schemas/state_diff.cue`](schemas/state_diff.cue).

- **Direction.** Relay → daemon.
- **Ordering.** `params.sequence` is monotonically increasing per subscription. Recipients MUST detect gaps and reconcile via `state.query`.
- **Idempotency.** The same diff MAY be redelivered after a connection blip. Recipients MUST treat repeated sequences as no-ops.

#### Params

| Field | Type | Required | Notes |
|---|---|---|---|
| `subscription_id` | string | yes | Echoes the value from `state.subscribe`. |
| `sequence` | int | yes | Monotonically increasing per subscription. |
| `emitted_at` | timestamp | yes | Server timestamp of the change set. |
| `changes` | object[] | yes | At least one change. |

#### Change kinds

| `kind` | `record` required? | `reason` allowed? | Meaning |
|---|---|---|---|
| `agent_attached` | yes | no | A new agent appeared in the subscription's scope. |
| `agent_detached` | no (MUST be absent) | yes (advisory) | An agent left the scope. |
| `state_changed` | yes | no | An existing agent's record was updated. |

## 8. Conflict messages

Conflict messages let an agent ask the relay (or the daemon's local cache) "is anyone else touching this code right now?", proactively declare an in-progress edit, release a declaration, and receive server-pushed notifications when a peer's activity creates a new conflict.

The conflict-detection engine itself is described in [`../project-context.md` §7](../project-context.md#7-conflict-detection-engine). Levels 1 and 2 are operative in v0.1; Level 3 (semantic) and Level 4 (resource) are reserved for Phase 5. Levels are reported as `level: 1 | 2 | 3 | 4` in `#ConflictReport`; v0.1 implementations only emit `level: 1` or `level: 2`.

Free-text fields in conflict messages (`message`, `reason`) MUST NOT be interpolated into any agent prompt. The mandatory sandboxing rule is specified in [`../docs/THREAT_MODEL.md`](../docs/THREAT_MODEL.md) §5.

### 8.1 `conflict.check` (request → response)

Pre-write check. Returns the highest-confidence result available within the latency budget. Schema in [`schemas/conflict_check.cue`](schemas/conflict_check.cue).

- **Direction.** Daemon → relay (or daemon → local cache for Level 1 only).
- **Latency.** Subject to the SLOs in [`../project-context.md` §3.3](../project-context.md#33-service-level-objectives): P95 ≤ 100 ms end-to-end; ≤ 50 ms from local cache.
- **Partial results.** If higher levels timed out, `result.level_reached` reflects the highest level that completed and `result.partial` is `true`.

#### Request params

| Field | Type | Required | Notes |
|---|---|---|---|
| `developer_id` | string | yes | §4.1. |
| `agent_id` | string | yes | §4.2. |
| `repo` | string | yes | Canonical repo URL. |
| `branch` | string | yes | The branch the writes target. |
| `intended_writes` | object[] | yes | At least one entry. Each carries `file` and optional `hunks`. |

When `hunks` is absent on an intended-write, the request is a Level 1 (file-existence) check for that file. When `hunks` is present, the request is for Level 2 (and Level 3 in Phase 5+).

#### Response result

| Field | Type | Required | Notes |
|---|---|---|---|
| `level_reached` | enum | yes | `1`, `2`, `3`, or `4`. Highest level that completed. |
| `partial` | bool | yes | True if higher levels were requested but timed out. |
| `conflicts` | object[] | yes | `#ConflictReport[]`. Empty list means no conflicts at the level reached. |
| `checked_at` | timestamp | yes | Server timestamp at completion. |

Each `#ConflictReport` carries: `level`, `with` (peer ref: `developer_id` + `agent_id` + `branch`), `file`, optional `overlap_hunks` (Level 2+), optional `symbol` (Level 3+), `confidence ∈ [0.0, 1.0]`, optional `message` (printable ASCII, ≤ 256 chars).

### 8.2 `conflict.declare` (request → response)

Proactive declaration: "I'm about to edit X". Schema in [`schemas/conflict_declare.cue`](schemas/conflict_declare.cue).

- **Direction.** Daemon → relay.
- **Effect.** Advisory. The relay records the declaration in awareness state and surfaces it on subsequent peer `conflict.check` calls. The relay does not block writes.
- **Lifetime.** Bounded by `ttl_seconds` (1–3600). Declarations auto-expire to prevent indefinite locks. Re-declare to extend.

#### Request params

| Field | Type | Required | Notes |
|---|---|---|---|
| `developer_id` | string | yes | §4.1. |
| `agent_id` | string | yes | §4.2. |
| `repo` | string | yes | |
| `branch` | string | yes | |
| `targets` | object[] | yes | At least one. Same shape as `intended_writes` in §8.1. |
| `ttl_seconds` | int | yes | 1–3600. |
| `reason` | string | no | Printable ASCII, ≤ 128 chars. Advisory. |

#### Response result

| Field | Type | Required | Notes |
|---|---|---|---|
| `declaration_id` | string | yes | Opaque, prefix `tap_decl_`. |
| `expires_at` | timestamp | yes | Computed as `now() + ttl_seconds`. |

### 8.3 `conflict.release` (notification)

Release a previously-declared conflict by id. Schema in [`schemas/conflict_release.cue`](schemas/conflict_release.cue).

- **Direction.** Daemon → relay.
- **Effect.** The relay removes the declaration from awareness state within 5 seconds. Declarations also expire automatically at `expires_at`; release is purely an optimization.

#### Params

| Field | Type | Required | Notes |
|---|---|---|---|
| `developer_id` | string | yes | §4.1. |
| `agent_id` | string | yes | §4.2. |
| `declaration_id` | string | yes | Echoes the value from `conflict.declare`. |

### 8.4 `conflict.notify` (server-pushed notification)

Server-pushed notification of a newly detected conflict affecting the recipient's branch. Schema in [`schemas/conflict_notify.cue`](schemas/conflict_notify.cue).

- **Direction.** Relay → daemon.
- **When emitted.** When a peer's `state.announce` or `conflict.declare` creates a new conflict against work the recipient is known (via awareness state) to be doing, or when the recipient's own activity creates a new conflict against a peer's existing state.
- **De-duplication.** The relay SHOULD coalesce repeated notifications for the same `(file, peer)` pair within a short window (implementation-defined; recommended 5 s).

#### Params

| Field | Type | Required | Notes |
|---|---|---|---|
| `developer_id` | string | yes | §4.1. |
| `agent_id` | string | yes | §4.2. |
| `repo` | string | yes | |
| `branch` | string | yes | |
| `detected_at` | timestamp | yes | Server timestamp at detection. |
| `conflicts` | object[] | yes | `#ConflictReport[]`. At least one. |

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

- *2026-04-29:* §6 lifecycle expanded with full field tables, schemas, and fixtures for `agent.heartbeat`, `agent.deregister`, `agent.disconnect`. §7 awareness fully specified (`state.announce`, `state.query`, `state.subscribe`, `state.diff`) with `#AgentAwarenessRecord`, `#DirtyFile`, `#Hunk`, `#AwarenessScope`, `#SubscriptionId`. §8 conflict fully specified (`conflict.check`, `conflict.declare`, `conflict.release`, `conflict.notify`) with `#ConflictReport`, `#IntendedWrite`, `#PeerRef`, `#HunkOverlap`, `#ConflictLevel`, `#Confidence`. Shared types in `schemas/common.cue`. Conformance fixtures cover every new schema with at least one positive and one negative case. Versioning normative text moved to [`../docs/VERSIONING.md`](../docs/VERSIONING.md); §5 retains a summary.
- *2026-04-28:* Draft skeleton established; lifecycle messages (`agent.register`, `agent.heartbeat`, `agent.deregister`, `agent.disconnect`) specified; envelope and identity schemas committed.
