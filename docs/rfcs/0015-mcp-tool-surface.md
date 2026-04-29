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
