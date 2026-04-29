---
status: draft
phase: 2
owners: [@rileydrakedesign]
last-reviewed: 2026-04-29
rfc_number: 0015
title: "MCP tool surface"
discussion_pr: ""
implementation_tracking: []
---

# RFC 0015 — MCP tool surface

> **Out-of-order Phase 2 RFC authored in Phase 1.** Per [`../DOCUMENTATION_PLAN.md`](../DOCUMENTATION_PLAN.md) §9, the MCP tool surface is on the critical path: every adapter (Claude Code first, Cursor / Codex / Aider in Phase 5) and the daemon's own MCP server depend on this contract. Designing it now, before Phase 2 implementation begins, prevents the rework that would follow if adapter and daemon teams started against an unspecified surface.

---

## 1. Summary

This RFC specifies the **set of MCP tools the local daemon exposes to attached agents** and the contract every adapter MUST satisfy when surfacing those tools to an agent's editor harness.

The tool surface is small (twelve tools, organized in five categories) and intentionally narrow: it offers exactly the capabilities an agent needs to participate in cross-developer awareness, conflict prevention, and (in Phase 4) consults — and nothing more. The daemon does not expose generic "read file" or "shell" tools; those are the editor's job, not TAP's.

Each tool is specified with:

- a stable name (snake_case, `tap_*` prefix),
- a JSON Schema for inputs (derived from `protocol/schemas/`),
- a JSON Schema for outputs,
- a side-effect classification (read-only, advisory, state-mutating),
- a sandboxing posture (which fields, if any, originate with peer agents and therefore require the structured-envelope rule per [`../THREAT_MODEL.md`](../THREAT_MODEL.md) §5).

The contract between adapter and editor is also specified: how the adapter registers the daemon's MCP server with the editor, how it handles the `PreToolUse` / `PostToolUse` hook flow, and how it MUST present inbound peer content to the editor's UI rather than the agent's prompt.

---

## 2. Motivation

### 2.1 Why now

[`../../project-context.md` §8](../../project-context.md#8-phased-development-plan) places the daemon, the Claude Code adapter, and Level 1/2 conflict detection in Phase 2. None of those can be built without the MCP tool surface:

- The daemon's MCP server has no inputs to validate or operations to dispatch on.
- The Claude Code adapter has no tool list to register with Claude Code.
- The conflict-detection engine has no callers.

[`../DOCUMENTATION_PLAN.md`](../DOCUMENTATION_PLAN.md) §9 explicitly authorizes authoring this RFC out of order in Phase 1. It is also the only externally-visible contract introduced in Phase 2 that other components depend on; getting it wrong forces every adapter to re-implement.

### 2.2 What problem this solves

A TAP-conformant agent needs to do five things during a coding session:

1. Tell the daemon what it's working on (branch, intent, dirty files), so peers can see.
2. Ask the daemon, before writing, whether anyone else is touching the same file or hunks (conflict check).
3. Optionally declare an in-progress edit so peers' subsequent checks find it.
4. Find out who else is online and on what branches.
5. Receive notifications when a peer's activity creates a new conflict.

Today there is no protocol-level surface for any of this. Each item maps to a TAP wire method (`state.announce`, `conflict.check`, etc.) and to one tool in the daemon's MCP server. Without a specified mapping, every adapter would invent its own — defeating the editor-agnostic positioning in [`../../project-context.md` §1.3](../../project-context.md#13-positioning).

### 2.3 What "doing it right" looks like

Three properties anchor the design:

- **Stability.** Tool names and schemas are part of the v0.1 conformance surface. Renames or breaking changes follow [`../VERSIONING.md`](../VERSIONING.md). A v1.0 adapter still works against a v1.x daemon.
- **Editor-agnostic.** Nothing in the tool surface assumes a specific editor's hook model, prompt format, or UI conventions. Adapters bridge editor-specific semantics; the tools themselves do not.
- **Sandboxing as a first-class output property.** Every tool whose output may carry peer-originated content declares it. Adapters use that declaration to route content to the editor's UI rather than the agent's prompt, per [`../THREAT_MODEL.md`](../THREAT_MODEL.md) §5.

### 2.4 Non-goals

- Tools for file I/O, shell execution, code search. These are the editor's responsibility.
- Tools that initiate a consult, message, or task handoff. Those are Phase 4 surfaces and live in a separate RFC (`rfcs/0201-consults-design.md`).
- Editor-specific configuration. Each adapter's `INTERFACES.md` covers that.
- Plumbing for human-in-the-loop approval prompts. That is the daemon ↔ desktop OS surface, not the agent ↔ daemon surface.

---

## 3. Design

### 3.1 Architecture

```
┌──────────────────────┐        ┌──────────────────────┐
│   Editor (e.g.       │        │   Local daemon       │
│   Claude Code)       │        │                      │
│                      │        │  ┌────────────────┐  │
│  ┌────────────────┐  │  MCP   │  │ MCP server     │  │
│  │ Agent + tools  │◀─┼────────┼─▶│ (this RFC)     │  │
│  │  (LLM)         │  │ (UDS)  │  └────────┬───────┘  │
│  └────────────────┘  │        │           │          │
│         ▲            │        │  ┌────────▼───────┐  │
│         │ hooks      │        │  │ git state /    │  │
│  ┌──────┴─────────┐  │        │  │ awareness /    │  │
│  │ Adapter        │──┼────────┼─▶│ conflict /     │  │
│  │ (per editor)   │  │        │  │ policy / audit │  │
│  └────────────────┘  │        │  └────────────────┘  │
└──────────────────────┘        └──────────────────────┘
```

The daemon hosts a single MCP server. Adapters register that server with the editor's MCP-client surface. When the editor invokes a tool, the call flows over a Unix domain socket (Linux/macOS) or a named pipe (Windows) to the daemon, which dispatches to its internal subsystems (git state engine, awareness cache, conflict orchestrator, policy engine, audit log).

This RFC specifies only the agent ↔ daemon contract (the dashed arrow). The editor ↔ adapter and adapter ↔ daemon-MCP-server hops are documented in `docs/components/adapters/<editor>/` per Phase 2.

### 3.2 Transport

The daemon's MCP server speaks MCP over a local IPC channel:

- **Linux / macOS:** Unix domain socket at `$XDG_RUNTIME_DIR/tap/daemon.sock` (Linux) or `~/Library/Application Support/tap/daemon.sock` (macOS). The path is exported as `$TAP_DAEMON_SOCKET` for adapters that prefer environment-variable discovery.
- **Windows:** named pipe at `\\.\pipe\tap-daemon-<user-sid>`. Same `$TAP_DAEMON_SOCKET` discovery.
- **Framing:** MCP's standard JSON-RPC framing. TAP's wire envelope (`protocol/SPEC.md` §3) is used between daemon and relay; **MCP framing is used between daemon and agent**. The two are deliberately distinct: MCP is the editor-side IPC convention, TAP is the network protocol.
- **Authentication:** none at the transport layer. Process-local trust boundary per [`../../protocol/SPEC.md`](../../protocol/SPEC.md) §2.2.
- **Permissions:** the daemon enforces socket permissions `0700` and verifies the caller's UID matches the daemon's owner. Foreign-UID connects are refused.

### 3.3 Discovery

Adapters discover the daemon by, in order:

1. `$TAP_DAEMON_SOCKET`, if set.
2. The platform-default path (§3.2).
3. If neither resolves to a connectable endpoint, the adapter MUST surface a clear error and SHOULD link to the daemon installation guide. Adapters MUST NOT silently degrade to a no-op state.

### 3.4 Tool naming convention

All TAP tools are prefixed `tap_`. Names use snake_case. The category appears as the second word; the action appears third.

- `tap_state_announce`, `tap_state_query`
- `tap_conflict_check`, `tap_conflict_declare`, `tap_conflict_release`
- `tap_session_info`, `tap_peers_list`, `tap_policy_get`

Names are stable per [`../VERSIONING.md`](../VERSIONING.md): renames require a MAJOR bump; adding tools is MINOR.

### 3.5 Schema conventions

Every tool declares input and output schemas as JSON Schema, derived 1:1 from the relevant CUE definitions in `protocol/schemas/`. The mapping is mechanical; any mismatch is a bug in the codegen pipeline (RFC `0001-codegen-pipeline.md`).

Two notes:

- **Inputs are validated by the daemon before dispatch.** An adapter that sends a malformed payload receives an MCP error (JSON-RPC error code `-32602`, mirroring the wire-protocol error).
- **Outputs are validated by the daemon before reply.** A daemon that produces a malformed reply has a bug; the adapter MAY reject it and the daemon SHOULD log it.

### 3.6 Side-effect classification

Every tool declares a side-effect class. Adapters use this to decide how aggressively to gate execution behind hook flows.

| Class | Meaning | Hook posture |
|---|---|---|
| `read_only` | No state mutation; safe to call freely. | No `PreToolUse` gate required. |
| `advisory` | Records caller intent; relay state changes; reversible. | `PreToolUse` MAY gate; recommended quiet. |
| `state_mutating` | Allocates a server-side handle (declaration, subscription) or sends a message that influences peer behavior. | `PreToolUse` SHOULD gate; auditable. |

The classification is independent of the wire-protocol method's idempotency. `tap_conflict_check` is a wire-level request/response but its tool class is `read_only` because it does not mutate awareness state.

### 3.7 Sandboxing contract for outputs

Every tool whose output may carry **peer-originated content** declares so explicitly via an `output.sandboxing.peer_content_fields` array in its tool descriptor. Fields named there carry strings the receiving agent's adapter MUST NOT interpolate into the agent's prompt. The adapter's responsibility is to:

1. Surface those fields through the editor's UI (notification, panel, structured tool-result block) — never as part of the system prompt or user message.
2. If the editor offers no UI primitive that supports this, the adapter MUST replace the field with a stable placeholder (`<peer content elided>`) and surface the original through a side channel (logs, dedicated panel) the agent cannot read.

This rule is the operationalization of [`../THREAT_MODEL.md`](../THREAT_MODEL.md) §5 at the editor boundary. Adapter conformance tests (Phase 2 for Claude Code, Phase 5 for the rest) verify it.

### 3.8 Error model

Tools return errors via MCP's tool-result error mechanism. Error payloads carry a `code` matching the TAP wire-protocol error registry (`protocol/SPEC.md` §13) and a `message`. Common cases:

| Code | When |
|---|---|
| `-32602` | Invalid params (malformed input). |
| `1010` | Rate limited. |
| `1020` | Policy denied (e.g., scope above caller's trust level). |
| `1030` | Repo not opted in. |
| `2001` | Daemon not connected to relay (Phase 3+); `tap_state_query` returns local-cache-only data with a `partial: true` flag instead, when applicable. |

A new error code is added by RFC, allocated from the registry per [`../SPEC_STYLE.md`](../SPEC_STYLE.md) §5.

### 3.9 Versioning

The MCP tool surface versions with the daemon, not with the wire protocol. The daemon's MCP server advertises its tool-surface version as `x-tap-tool-surface-version` in the MCP server descriptor; adapters check it on connect and refuse to attach if the major version is unsupported.

The first version is `1.0.0`, shipped with Phase 2's daemon. Phase 4 introduces consult/messaging tools, which is a MINOR bump.

---

## 4. Tool catalog: awareness and conflict

Tools the agent calls during normal coding flow. Read-only and advisory tools dominate; one tool per wire-protocol method, plus two convenience tools (`tap_peers_on_file`, `tap_conflicts_pending`) computed locally from the awareness cache.

### 4.1 `tap_state_announce`

- **Class:** advisory.
- **Wire mapping:** [`state.announce`](../../protocol/SPEC.md#71-stateannounce-notification).
- **Description.** Declares the agent's current branch and dirty-file state. Called by the adapter via the `PostToolUse` hook after the agent edits, and by the agent directly when it changes branch or declares an `intent`.

#### Input

| Field | Type | Required | Notes |
|---|---|---|---|
| `branch` | string | yes | Current branch. |
| `dirty_files` | object[] | yes | May be empty. Each entry: `{file, hunks[]}` per `protocol/schemas/common.cue#DirtyFile`. |
| `intent` | string | no | Free-text, ≤ 256 chars, no control characters. |

The daemon fills in `developer_id`, `agent_id`, `repo`, `worktree`, and `sequence` from the session.

#### Output

`{ ok: true }` on success; the wire method is a notification with no response, but the MCP tool returns an acknowledgment so the adapter can detect transport failures.

#### Sandboxing

Not applicable — no peer content.

#### Example

```json
// tool call
{ "name": "tap_state_announce",
  "arguments": {
    "branch": "feature/auth-refactor",
    "dirty_files": [
      { "file": "src/auth/oauth.rs",
        "hunks": [{ "start_line": 12, "end_line": 48, "op": "modify" }] }
    ],
    "intent": "extracting OAuth flow"
  } }
// tool result
{ "ok": true }
```

### 4.2 `tap_state_query`

- **Class:** read-only.
- **Wire mapping:** [`state.query`](../../protocol/SPEC.md#72-statequery-request--response).
- **Description.** Returns a snapshot of awareness state at the requested scope. Used for "who else is on this repo?" lookups.

#### Input

| Field | Type | Required | Notes |
|---|---|---|---|
| `branches` | string[] | no | Empty/absent → all branches in the agent's repo. |
| `developers` | string[] | no | Empty/absent → all team members. |
| `since` | timestamp | no | RFC 3339 UTC. Returns only records updated at or after. |

The daemon fills in `repo` from the session.

#### Output

| Field | Type | Notes |
|---|---|---|
| `records` | object[] | `#AgentAwarenessRecord[]`. May be empty. |
| `partial` | bool | True if the daemon could only consult its local cache (e.g., relay disconnected). |
| `snapshot_at` | timestamp | Server timestamp at snapshot. |

#### Sandboxing

`output.sandboxing.peer_content_fields = ["records[].intent"]`. Adapters MUST surface peer intent strings in a UI element (panel, hover, notification), never in the agent's prompt.

### 4.3 `tap_peers_on_file`

- **Class:** read-only.
- **Wire mapping:** none (computed locally from the awareness cache; falls through to `state.query` if the cache is cold).
- **Description.** Convenience tool for the most common pre-edit question: "who else is currently editing this file?". Avoids the agent having to filter `tap_state_query` results client-side.

#### Input

| Field | Type | Required | Notes |
|---|---|---|---|
| `file` | string | yes | Path within the worktree, per `#FilePath`. |

#### Output

| Field | Type | Notes |
|---|---|---|
| `peers` | object[] | One entry per `(developer_id, agent_id, branch)` touching the file. Each carries the peer's `intent` (sandboxed) and the count of overlapping hunks if computable. |
| `partial` | bool | True if local-cache only. |

#### Sandboxing

`peer_content_fields = ["peers[].intent"]`.

### 4.4 `tap_conflict_check`

- **Class:** read-only.
- **Wire mapping:** [`conflict.check`](../../protocol/SPEC.md#81-conflictcheck-request--response).
- **Description.** **The critical hot path.** Called from the adapter's `PreToolUse` hook before any write. Returns conflict reports at the highest level reached within the latency budget. Sub-50 ms from local cache; sub-100 ms end-to-end per [`../../project-context.md` §3.3](../../project-context.md#33-service-level-objectives).

#### Input

| Field | Type | Required | Notes |
|---|---|---|---|
| `intended_writes` | object[] | yes | At least one `{file, hunks?}`. |

#### Output

| Field | Type | Notes |
|---|---|---|
| `level_reached` | int | 1, 2, 3, or 4. |
| `partial` | bool | True if higher levels timed out. |
| `conflicts` | object[] | `#ConflictReport[]`. May be empty. |
| `checked_at` | timestamp | |

#### Sandboxing

`peer_content_fields = ["conflicts[].message"]`. Conflict messages from the relay are operator-controlled in v0.1, but the contract treats them as peer content for forward compatibility with Phase 4.

#### Hook posture

Adapters MUST call this in `PreToolUse` for every write tool the agent invokes. A non-empty `conflicts` array SHOULD block the underlying write and surface the conflict to the developer; details in `rfcs/0030-claude-code-adapter.md`.

### 4.5 `tap_conflict_declare`

- **Class:** state-mutating.
- **Wire mapping:** [`conflict.declare`](../../protocol/SPEC.md#82-conflictdeclare-request--response).
- **Description.** Proactively declares "I'm about to edit X" so peer `tap_conflict_check` calls find it. Allocates a server-side `declaration_id` with a bounded TTL.

#### Input

| Field | Type | Required | Notes |
|---|---|---|---|
| `targets` | object[] | yes | At least one `{file, hunks?}`. |
| `ttl_seconds` | int | yes | 1–3600. Re-declare to extend. |
| `reason` | string | no | Printable ASCII, ≤ 128 chars. |

#### Output

| Field | Type | Notes |
|---|---|---|
| `declaration_id` | string | Opaque, prefix `tap_decl_`. |
| `expires_at` | timestamp | |

#### Sandboxing

Not applicable — no peer content.

### 4.6 `tap_conflict_release`

- **Class:** state-mutating.
- **Wire mapping:** [`conflict.release`](../../protocol/SPEC.md#83-conflictrelease-notification).
- **Description.** Releases a declaration ahead of its TTL. Optimization; declarations also expire automatically.

#### Input

| Field | Type | Required | Notes |
|---|---|---|---|
| `declaration_id` | string | yes | The id returned by `tap_conflict_declare`. |

#### Output

`{ ok: true }`.

### 4.7 `tap_conflicts_pending`

- **Class:** read-only.
- **Wire mapping:** none (locally maintained from `conflict.notify` notifications received since last call).
- **Description.** Returns the queue of conflict notifications the daemon has received for the agent and not yet shown. Lets the agent fetch outstanding notifications between hook invocations without subscribing to every server push.

#### Input

(none)

#### Output

| Field | Type | Notes |
|---|---|---|
| `notifications` | object[] | One entry per pending `conflict.notify`. Each carries the wire-method `params` plus a daemon-issued `notification_id` and `received_at`. |

The agent MAY pass a `notification_id` to a future `tap_conflicts_ack` (Phase 2 follow-up) to acknowledge; in v0.1, the daemon clears pending notifications after they have been read once.

#### Sandboxing

`peer_content_fields = ["notifications[].conflicts[].message"]`.

---

## 5. Tool catalog: introspection, policy, audit

Tools the agent calls to ground itself: who am I, who else is on the team, what policy applies, what just happened. All read-only.

### 5.1 `tap_session_info`

- **Class:** read-only.
- **Wire mapping:** none (returns daemon-side session state populated at `agent.register` time).
- **Description.** Returns the agent's own session metadata. Useful at the start of an agent run to confirm the daemon is reachable, the relay is connected, and the negotiated protocol version is known.

#### Input

(none)

#### Output

| Field | Type | Notes |
|---|---|---|
| `developer_id` | string | §4.1 of the wire spec. |
| `agent_id` | string | §4.2. |
| `repo` | string | Canonical repo URL. |
| `branch` | string | Current branch as known to the daemon. |
| `awareness_scope` | object | Echo of the scope negotiated at `agent.register`. |
| `tap_version` | string | Negotiated protocol version. |
| `daemon_version` | string | The daemon binary's semver. |
| `tool_surface_version` | string | Per §3.9. |
| `relay_connected` | bool | False when the daemon is operating local-only. |
| `relay_last_connected_at` | timestamp | Optional. Present after the first successful relay session. |

#### Sandboxing

Not applicable.

### 5.2 `tap_peers_list`

- **Class:** read-only.
- **Wire mapping:** none (computed from the awareness cache).
- **Description.** Returns peers visible in the agent's awareness scope, with their online status and most recent branch. Lets an agent answer "who's around?" without a full `tap_state_query`.

#### Input

| Field | Type | Required | Notes |
|---|---|---|---|
| `online_only` | bool | no | Default `false`. When `true`, returns only peers with at least one connected agent. |

#### Output

| Field | Type | Notes |
|---|---|---|
| `peers` | object[] | Each: `{developer_id, online, agents: [{agent_id, branch, last_heartbeat_at}]}`. |
| `partial` | bool | True if local-cache only. |

#### Sandboxing

Not applicable. Peer identifiers are infrastructure data, not free-text content from peer agents.

### 5.3 `tap_policy_get`

- **Class:** read-only.
- **Wire mapping:** none (the daemon's local policy engine; see [`../../project-context.md` §4.1](../../project-context.md#41-subsystems)).
- **Description.** Returns the policy snapshot active for the agent's current repo. Lets an agent know, before invoking a higher-scope tool (e.g., a Phase 4 consult), whether it will be auto-approved, prompt the developer, or be denied outright.

#### Input

(none)

#### Output

| Field | Type | Notes |
|---|---|---|
| `repo` | string | Repo the policy applies to. |
| `messaging` | object | Effective rate-limit and auto-approve config. |
| `consults` | object | Effective inbound-scope cap, auto-summarize-after-turns. (Phase 4 fields; v0.1 returns conservative defaults.) |
| `redaction.exclude_files` | string[] | Glob patterns excluded from outbound bundles. |
| `source_files` | string[] | Paths the daemon merged to produce this view (user-global, per-repo). For introspection only. |

The full policy DSL is specified in `rfcs/0206-policy-dsl.md` (Phase 4). v0.1 implementations return the conservative subset corresponding to the Phase 1–2 surface.

#### Sandboxing

Not applicable. Policy data is operator-controlled, never peer-controlled.

### 5.4 `tap_recent_activity`

- **Class:** read-only.
- **Wire mapping:** none (daemon-side rolling buffer of awareness events).
- **Description.** Returns the most recent awareness events the daemon has observed: peers attaching/detaching, branch switches, conflict notifications. Bounded to the last ≤ 100 events or the last 5 minutes, whichever is shorter. Intended for debugging and for UI surfaces (e.g., the dashboard's activity panel rendered through the adapter); not for production decision-making by the agent.

#### Input

| Field | Type | Required | Notes |
|---|---|---|---|
| `limit` | int | no | 1–100. Default 20. |
| `since` | timestamp | no | RFC 3339. Returns only events at or after. |

#### Output

| Field | Type | Notes |
|---|---|---|
| `events` | object[] | Each: `{kind, occurred_at, developer_id?, agent_id?, branch?, file?, summary}`. `kind` ∈ `{agent_attached, agent_detached, state_changed, conflict_detected, conflict_released}`. |
| `truncated` | bool | True if more events were available than the limit. |

#### Sandboxing

`peer_content_fields = ["events[].summary"]`. The daemon constructs `summary` strings from peer-controlled fields (intent, conflict message); they MUST flow to a UI element only.

---

## 6. Phase 4 tools (placeholder)

Phase 4 introduces messaging, consults, tasks, trust, and approval gates. The tool surface gains the following names; full specifications live in `rfcs/0201-consults-design.md`, `rfcs/0200-messaging.md`, `rfcs/0203-task-handoff.md`, `rfcs/0204-trust-graph.md`, and `rfcs/0205-approval-gates.md`. Listing them here reserves the names against accidental collision and makes the v1.x evolution path explicit.

| Name | Class | Wire mapping |
|---|---|---|
| `tap_message_send` | state-mutating | `msg.send` |
| `tap_messages_pending` | read-only | (locally maintained from `msg.deliver`) |
| `tap_consult_request` | state-mutating | `consult.request` |
| `tap_consult_message` | state-mutating | `consult.message` |
| `tap_consult_resolve` | state-mutating | `consult.resolve` |
| `tap_consult_observe` | read-only | `consult.observe` |
| `tap_consult_pending` | read-only | (locally maintained) |
| `tap_task_handoff` | state-mutating | `task.handoff` |
| `tap_task_update` | state-mutating | `task.update` |
| `tap_trust_grant` | state-mutating | `trust.grant` |
| `tap_trust_revoke` | state-mutating | `trust.revoke` |
| `tap_approval_respond` | state-mutating | `approval.respond` |

All Phase 4 tools that surface peer content (every consult and message tool) carry a non-empty `peer_content_fields` array. Phase 4's adapter conformance tests verify the sandboxing rule against this surface; v0.1 adapters do not implement these tools and simply do not register them.

Adding the Phase 4 surface is a MINOR tool-surface bump (1.0.x → 1.1.0). v1.0 adapters continue to function against a v1.1 daemon; they see only the v1.0 tools.
