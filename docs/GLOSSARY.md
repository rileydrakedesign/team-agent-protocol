---
status: accepted
phase: continuing
owners: [@rileydrakedesign]
last-reviewed: 2026-04-29
---

# TAP Glossary

This document is the canonical source for every domain term used in TAP documentation, source code, and the wire protocol. Other documents MUST link here rather than redefine terms. Disagreements between this glossary and other documents resolve in favor of this glossary unless the other document is the protocol specification itself, in which case the protocol specification wins and this glossary is updated.

When introducing a new term in any document, add it here in the same change.

Entries are alphabetical within each category.

---

## Core actors and components

**Adapter.** Editor-specific thin client that bridges between an agent and the local daemon. Contains no business logic. Examples: the Claude Code adapter, the Cursor adapter. See `../project-context.md` §3.2.

**Agent.** An LLM-driven coding assistant operating in an editor (Claude Code, Cursor, Codex, Aider, or any MCP-speaking client). May be human-supervised or autonomous. Always associated with exactly one developer and one editor session.

**Daemon.** Long-running per-developer process that owns local git state, agent registration, local policy, and the WSS connection to the relay. One daemon per workstation, multi-tenant across editors and agents. See `../project-context.md` §4.

**Developer.** A human user of TAP. Each developer has exactly one identity in a given org's relay. Developers are the unit of trust, policy, and audit attribution.

**Editor.** A code editor or IDE that hosts an agent. Examples: Claude Code, Cursor, Codex, Aider. TAP is editor-agnostic; per-editor adapters bridge differences.

**Org.** An organization's TAP deployment. One relay serves one org. Federation across orgs is out of scope for TAP v0.1.

**Relay.** Hosted multi-tier service per org that provides identity, presence, awareness, message routing, conflict detection, and consult coordination. See `../project-context.md` §5.

**Worktree.** A git working directory linked to a shared `.git` object store, allowing parallel branch checkouts. Standard pattern for multi-agent development. Each agent typically operates in one worktree.

---

## Identity

**Agent ID.** Per-session identifier for an agent. Computed as `blake3(developer_id || machine_id || editor || session_id)`, hex-encoded, 64 characters. Re-issued on every session. Specified in `../protocol/SPEC.md` §4.2.

**Developer ID.** Per-user, lowercased, stable identifier. Phase 1 derives from the GitHub login obtained via OAuth Device Flow. Enterprise deployments MAY substitute a SAML/OIDC subject claim.

**Machine ID.** Per-workstation, stable across daemon restarts. Locally generated; never re-used after a workstation is decommissioned.

**Repo identity.** Canonical repo URL plus org membership. Relay normalizes URLs (lowercased host, stripped `.git` suffix) before comparing.

**Session token.** Short-lived JWT issued by the relay at `agent.register`. Carried on every subsequent message in the WS subprotocol header.

**Trust pair.** A directed (developer → developer) relationship that controls auto-acceptance of inbound messages and consults at given scope levels. Mutations are signed.

---

## Wire protocol

**Envelope.** The outermost JSON-RPC 2.0 object every TAP message conforms to. Carries `jsonrpc`, `tap_version`, `trace_id`, `id` (when applicable), `method`/`params` (requests/notifications) or `result`/`error` (responses). Schema in [`../protocol/schemas/envelope.cue`](../protocol/schemas/envelope.cue).

**JSON-RPC 2.0.** The request-response protocol TAP envelopes conform to. See [JSON-RPC 2.0 spec](https://www.jsonrpc.org/specification).

**Method.** A JSON-RPC method name. TAP method names use the form `category.action` (e.g., `agent.register`, `state.diff`). See [`SPEC_STYLE.md`](SPEC_STYLE.md).

**Notification.** A JSON-RPC message without an `id` field; no response expected.

**Request / Response.** A JSON-RPC pair correlated by `id`.

**Trace ID.** 32-character lowercase hex string identifying a distributed trace. W3C Trace Context-compatible. Carried on every TAP envelope.

**TAP version.** Semantic version string negotiated at handshake. See [`VERSIONING.md`](VERSIONING.md).

---

## Awareness

**Awareness state.** The relay's live map of who is working on what across a team, queryable by repo, branch, file, or developer. Hot path in Redis, durable in Postgres. See `../project-context.md` §5.1.

**Branch state.** The set of (branch, dirty files, hunk ranges, intent, presence) for a given developer-repo pair.

**Dirty file.** A file with uncommitted modifications in a worktree. Includes staged, unstaged, and untracked content.

**Hunk.** A contiguous line range affected by a diff. Stored as `(file, branch, [(start_line, end_line, op)])` where `op` ∈ `{insert, delete, modify}`.

**Intent.** Optional declared purpose of an in-flight change ("refactoring auth", "fixing #123"). Free-text; bounded length.

**Line range.** A `(start_line, end_line)` pair, 1-indexed, inclusive of both bounds.

**Presence.** Online/offline state of an agent. Maintained by relay heartbeat TTL.

---

## Conflict detection

**Level 1 conflict.** Two agents/worktrees have dirty changes to the same file path. Pure string match. Sub-50 ms from local cache. See `../project-context.md` §7.

**Level 2 conflict.** Line-range overlap between dirty hunks across branches. Computed by relay worker on `conflict.check`.

**Level 3 conflict.** Semantic overlap derived from a tree-sitter symbol graph. Detects modifications to the same symbol or modifications to symbols a peer's write depends on. Phase 5.

**Level 4 conflict.** Resource conflicts: shared ports, database migrations, environment variables, build cache. Phase 5.

**Symbol graph.** Per-(repo, branch, commit) tree-sitter-derived graph storing definitions, references, type signatures, and import edges. Used for Level 3 detection.

---

## Messaging, consults, tasks

**Approval gate.** A human-in-the-loop checkpoint. Required for any message or consult action above scope `advisory`. Implemented as `approval.request` / `approval.respond`.

**Auto-approve list.** Per-developer policy list of peer developers whose inbound messages or consults at scope `advisory` or below skip the human approval prompt. Higher scopes always prompt.

**Consult.** A stateful, multi-turn, contextual conversation between two (or more) agents/developers about a specific topic, with lifecycle, transcript, and audit guarantees. The Phase 4 headline feature.

**Context bundle.** A scoped, content-addressed package of files, diffs, and references that travels with a consult so the recipient agent sees only what was deliberately shared. Encrypted at rest with per-consult derived keys.

**Message.** A one-shot, addressed payload sent between two agents or developers. Distinct from a consult, which is multi-turn and stateful.

**Scope.** A declared category of action a message or consult is permitted to perform. Five values, ordered from least to most privileged: `read_only`, `advisory`, `suggest_edit`, `request_handoff`, `execute`. Higher scopes require greater trust or human approval. Specified in `../protocol/SPEC.md` §12 (Phase 4).

**Task handoff.** A request for another agent to take ownership of a unit of work, optionally with full context. Distinct from a consult: a handoff transfers responsibility, a consult exchanges information.

**Transcript.** The persisted record of all turns in a consult. Cryptographically chained per entry; signed by the relay.

**Turn.** A single exchange within a consult.

---

## Policy and trust

**Auto-accept.** Per-repo policy list of peer developers whose inbound consults at scope `advisory` or below are accepted without prompting the recipient developer. Higher scopes always prompt.

**Policy DSL.** The TOML-based language used to express local policy in `~/.tap/policy.toml` (user-global) and `<repo>/.tap/policy.toml` (per-repo, authoritative for repo-scoped decisions). Specified in detail in the Phase 4 RFC `rfcs/0206-policy-dsl.md`.

**Redaction rule.** A policy rule excluding files or fields from outbound bundles. Default exclusions include `.env*`, `secrets/**`, `**/*.pem`, `**/*.key`.

**Trust grant.** Signed mutation establishing or elevating a trust pair. Audited.

---

## Security

**Anchor commit.** Periodic write of the audit-chain head hash to S3 with object versioning, providing tamper-evidence for the chained audit log.

**Audit chain.** The cryptographic chain over audit log entries: each entry carries `prev_hash = blake3(prev_entry)`, each entry is Ed25519-signed by the relay. Verifiable end-to-end.

**Sandbox (inbound message).** The mandatory rule that inbound message content from a peer agent is never prepended or interpolated into the receiving agent's prompt. Content arrives via a structured envelope and is surfaced as scoped MCP resources or tool-call results. See [`THREAT_MODEL.md`](THREAT_MODEL.md) §5.

**STRIDE.** Microsoft's threat-modeling taxonomy: Spoofing, Tampering, Repudiation, Information disclosure, Denial of service, Elevation of privilege. Used informally throughout [`THREAT_MODEL.md`](THREAT_MODEL.md).

---

## Storage and infrastructure

**Core tier.** Stateful relay tier. One process per repo shard. Owns presence, awareness state, message routing, consult coordination, conflict orchestration, durable inbox.

**Durable inbox.** Per-agent message queue persisted in Postgres with S3 archival.

**Edge tier.** Stateless relay tier. WS gateway, TLS termination, JWT validation, rate-limiting, repo-affinity routing.

**Worker tier.** Stateless relay compute, NATS JetStream consumers. Runs Level 2/3 conflict analysis, replay generation, webhook fanout, audit exports.

---

## Process and meta

**Conformance fixture.** A single test case in `protocol/conformance/fixtures/`. JSON document carrying `name`, `description`, `schema_ref`, `data`, `expected_valid`, optional `expected_round_trip`, optional `expected_error_code`. Format specified in [`../protocol/conformance/README.md`](../protocol/conformance/README.md).

**Conformance suite.** The complete set of fixtures any TAP-conformant implementation MUST pass. Versioned with the protocol.

**Decision log.** Append-only record of design decisions. The project-wide log is `../project-context.md` §9.5; per-phase logs are at `phases/phase-N/decisions.md`.

**Drift check.** CI gate that re-runs codegen and fails if generated bindings differ from the committed copy. Implemented in [`../tools/codegen/drift_check.sh`](../tools/codegen/drift_check.sh).

**Informative.** Non-binding text in the protocol specification. Provides context, examples, or explanation. Distinct from normative text.

**Normative.** Binding text in the protocol specification. Implementations MUST conform to normative text. Identified by RFC 2119 keywords (MUST, SHOULD, MAY).

**Phase.** A coherent milestone in the development plan with explicit deliverables and ship criteria. See `../project-context.md` §8.

**RFC.** Request for Comments. The unit of design proposal. Numbered, append-only after acceptance. Process specified in [`RFC_PROCESS.md`](RFC_PROCESS.md).

**Ship criterion.** A measurable, testable condition that must hold before a phase is considered complete.

---

## Cryptography

**AES-256-GCM.** Authenticated encryption with associated data, used for at-rest encryption of consult context bundles.

**BLAKE3.** Cryptographic hash function. Used for `agent_id` derivation and audit-chain `prev_hash` linking.

**Ed25519.** Elliptic-curve signature scheme. Used for relay-signed JWTs and audit-chain entry signatures.

**JWT.** JSON Web Token. Carries developer and agent identity claims. Issued by the relay, signed Ed25519, short TTL (5 min).

**mTLS.** Mutual TLS. Daemon-side pinned CA validates the relay's certificate; relay validates the daemon's client certificate. See `../project-context.md` §2.

---

## Acronyms

| Acronym | Expansion |
|---|---|
| A2A | Google Agent2Agent (protocol) |
| ADR | Architecture Decision Record |
| API | Application Programming Interface |
| BSL | Business Source License |
| CA | Certificate Authority |
| CI | Continuous Integration |
| CUE | "Configure, Unify, Execute" — schema language |
| DSL | Domain-Specific Language |
| DSAR | Data Subject Access Request (GDPR) |
| IA | Information Architecture |
| IDP | Identity Provider |
| JSON-RPC | Remote Procedure Call protocol over JSON |
| JWT | JSON Web Token |
| MCP | Model Context Protocol |
| MSI | Microsoft Installer |
| OAuth | Open Authorization |
| OIDC | OpenID Connect |
| PITR | Point-in-Time Recovery |
| RFC | Request For Comments |
| SAML | Security Assertion Markup Language |
| SCIM | System for Cross-domain Identity Management |
| SIEM | Security Information and Event Management |
| SLO | Service-Level Objective |
| SP | Service Provider (in SAML) |
| SSO | Single Sign-On |
| TAP | Team Agent Protocol |
| TLS | Transport Layer Security |
| TTL | Time To Live |
| WSS | WebSocket Secure |
