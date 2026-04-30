# TAP — Team Agent Protocol

> A protocol and platform for cross-developer AI agent coordination, conflict prevention, and bilateral consults during active development.

This document is the source of truth for the TAP project. It is designed to be read by Claude Code (and other coding agents) as project context. Keep it updated as decisions evolve. When you (the agent) are uncertain, refer back here before asking the user.

---

## 0. How to use this document

- **Section 1** is the product thesis. Read it once, refer back when scoping decisions feel ambiguous.
- **Section 2** is locked architectural decisions. Do not revisit without explicit user approval.
- **Sections 3–7** describe the system in detail.
- **Section 8** is the phased development plan with explicit ship criteria.
- **Section 9** is the working-state block — current phase, current task, open questions. **Update this as work progresses.**
- **Section 10** is a glossary.

When starting a new session: read sections 1, 2, and 9 at minimum.

---

## 1. Product thesis

### 1.1 The problem

Modern development teams increasingly run multiple AI coding agents per developer (Claude Code, Cursor, Codex, Aider) across isolated git worktrees. This pattern surfaces two recurring failures:

1. **Silent merge conflicts.** Agents working in separate worktrees are blind to each other's in-flight changes. Conflicts surface at PR time, after significant work has already been done on incompatible assumptions.
2. **Coordination overhead between humans.** When developer A's agent needs context that developer B has — about the auth refactor, the database migration, the API contract change — the only path is human-mediated: A messages B in Slack, B context-switches, copies files into their own agent, gets an answer, copies it back to A's agent. The agents themselves cannot consult each other.

Single-developer multi-agent orchestration is solved (Claude Code Agent Teams, GitHub Squad, Augment Intent, sub-agent patterns). Cross-developer agent coordination is empty space.

### 1.2 The solution

TAP is two products fused:

1. **Cross-developer awareness and conflict prevention.** A real-time map of who is touching what across the team, with file-level, hunk-level, and semantic conflict detection delivered to agents before they write.
2. **Agent-to-agent consults.** A first-class primitive for one developer's agent to open a stateful, contextual conversation with another developer's agent, with full security, audit, and human-oversight guarantees.

The fusion matters. Conflict detection without messaging tells you "your agent conflicts with Riley's branch" — useful. Conflict detection plus consults lets your agent ask Riley's agent *about* the conflict and resolve it collaboratively — qualitatively different.

### 1.3 Positioning

- **Editor-agnostic.** Works with any agent that speaks MCP, with first-class adapters for the most-used coding agents.
- **Open-core.** Protocol, daemon, adapters, SDKs are Apache 2.0. Hosted relay is BSL 1.1 with 4-year Apache conversion. Enterprise features (SSO, on-prem, advanced policy, compliance) are commercial.
- **Conformant with Google A2A** for agent identity and discovery; extends with development-specific primitives.
- **Standards-aspirational.** TAP aims to be the IETF-track protocol for team-scoped agent collaboration, not a single-vendor stack.

### 1.4 Non-goals

- TAP is not an agent. It does not write code, plan tasks, or invoke LLMs on behalf of users.
- TAP is not a code review tool. It does not replace PRs, CI, or human review.
- TAP is not a chat platform. Human-to-human chat happens elsewhere (Slack, Linear); TAP integrates rather than competes.
- TAP is not a single-developer orchestrator. Within-machine multi-agent coordination is solved by editor-native features; TAP starts at the team boundary.

---

## 2. Locked architectural decisions

These decisions are frozen unless overturned by explicit user direction. Agents working on the project should treat them as constraints.

| Concern | Decision |
|---|---|
| Daemon language | Rust |
| Relay edge tier language | Go |
| Relay core tier language | Go (Rust permitted for performance-critical paths if measured) |
| Worker tier language | Mixed: Go for orchestration, Rust for tree-sitter/semantic analysis |
| Wire format | JSON-RPC 2.0 over WSS |
| Schema language | CUE; bindings generated for Rust, Go, TypeScript |
| Daemon ↔ agent transport | Unix socket (Linux/macOS) / named pipe (Windows) with same JSON-RPC framing |
| Hot state | Redis cluster |
| Durable state | Postgres with read replicas |
| Pub/sub & queues | NATS JetStream |
| Object store | S3-compatible |
| Analytics store | ClickHouse (Phase 5+) |
| Container orchestration | Kubernetes |
| Identity baseline | GitHub OAuth Device Flow (developer); SAML/OIDC (enterprise) |
| Daemon trust to relay | mTLS with daemon-side pinned CA |
| Audit integrity | Cryptographic chaining (each entry hashes the prior) |
| Inbound message handling | Structured envelope; never raw prompt prepending |
| Protocol baseline | Conformant with Google A2A; extends |
| Conformance | Public test suite required for any TAP implementation |
| License (protocol, adapters, daemon, SDKs) | Apache 2.0 |
| License (relay) | BSL 1.1 with 4-year conversion to Apache 2.0 |
| Repository structure | Monorepo |
| Versioning | Semantic versioning per component; protocol versioned independently |

Do not change these without recording the rationale in section 9 and getting user approval.

---

## 3. System overview

### 3.1 Components

```
┌─────────────────────────────────────────────────────────────────────┐
│                       DEVELOPER WORKSTATIONS                         │
│                                                                      │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐            │
│  │ Claude Code  │   │   Cursor     │   │    Codex     │            │
│  │  + adapter   │   │  + adapter   │   │  + adapter   │            │
│  └──────┬───────┘   └──────┬───────┘   └──────┬───────┘            │
│         │ Unix socket       │ MCP              │ MCP                │
│         └───────────────────┼──────────────────┘                    │
│                             │                                        │
│                    ┌────────▼─────────┐                              │
│                    │  Local Daemon    │  Rust, one per developer    │
│                    │  - Git watcher   │                              │
│                    │  - State cache   │                              │
│                    │  - MCP server    │                              │
│                    │  - Agent router  │                              │
│                    │  - Consult mgr   │                              │
│                    │  - Local policy  │                              │
│                    └────────┬─────────┘                              │
└─────────────────────────────┼───────────────────────────────────────┘
                              │ WSS (TAP, mTLS-pinned)
                              │
        ┌─────────────────────▼─────────────────────────┐
        │                RELAY CLUSTER                   │
        │  Edge:    WS gateway, auth, rate limits        │
        │  Core:    routing, presence, awareness, consult│
        │  Workers: conflict detection, semantic, replay │
        │  Storage: Postgres, Redis, NATS, S3, ClickHouse│
        └────────────┬──────────────────────┬────────────┘
                     │                       │
            ┌────────▼────────┐    ┌────────▼────────┐
            │  Web Dashboard  │    │  Admin / Audit  │
            │   (Next.js)     │    │     Console     │
            └─────────────────┘    └─────────────────┘
```

### 3.2 Component summary

- **Editor adapters.** Thin clients per editor. Register the agent with the local daemon, expose the daemon's TAP tools to the agent via the editor's native mechanism (MCP, hooks, plugin API), stream agent activity events back to the daemon. Adapters contain no business logic.
- **Local daemon.** One per developer machine, multi-tenant across editors and agents. Long-running OS service. Owns git state, local awareness cache, agent routing, consult management, local policy.
- **Relay.** Hosted multi-tier service. Edge tier handles WSS gateway and auth. Core tier owns presence, awareness state, message routing, consult coordination. Worker tier runs expensive jobs (semantic conflict detection, replay generation, webhook fanout).
- **Protocol (TAP).** JSON-RPC 2.0 over WSS for daemon ↔ relay; same framing over Unix socket for daemon ↔ agent. Conforms with Google A2A; extends with development-specific message types.
- **Web dashboard.** Live activity map, consult list, conflict heatmap, audit log search, trust and policy management.
- **Admin / audit console.** Restricted-access surface for org administrators: audit log with compliance export, SSO/SCIM management, billing, incident response tooling.

### 3.3 Service-level objectives

| Metric | Target |
|---|---|
| Conflict check end-to-end (daemon → relay → daemon) P95 | ≤ 100 ms |
| Conflict check from local cache only P95 | ≤ 50 ms |
| Message delivery P95 | ≤ 250 ms |
| Awareness state propagation P95 (cross-region) | ≤ 500 ms |
| Hosted plan availability | 99.9% |
| Enterprise plan availability | 99.95% |

---

## 4. Local daemon

### 4.1 Subsystems

- **Git state engine.** Watches every opted-in repo. Native filesystem events (inotify / FSEvents / ReadDirectoryChangesW) trigger debounced reads of `git status --porcelain=v2`, `git worktree list --porcelain`, `git diff --name-only`, `git rev-parse`. Maintains a per-repo state graph: branches, worktrees, dirty files, staged hunks, recent commits, untracked files.
- **Hunk-level diff tracker.** Parses dirty diffs into line ranges. Maintains `(file, branch, [(start_line, end_line, op)])`. Required for Level 2 conflict detection.
- **Local awareness cache.** Read-through cache of the relay's awareness state for every participating repo. Sub-50 ms local query mandatory — the PreToolUse hook is on the critical path of every agent edit. Updates pushed from relay over WSS as deltas, not full snapshots.
- **MCP server.** Exposes daemon capabilities to local agents over Unix socket / named pipe. Tool schema is part of the TAP spec. Discovery via well-known socket path or `TAP_DAEMON_SOCKET` env var.
- **Agent router.** Multiple agents can be registered to one daemon. Inbound messages from the relay are routed to the right agent based on `agent_id`, branch context, or routing rules.
- **Consult manager.** Active consult registry (persisted to local SQLite). Context bundler (packages files/diffs for outbound, redacts per policy, pushes content-addressed bundle to relay). Context resolver (fetches inbound bundles, exposes contents as scoped MCP resources). Approval UX (native desktop notifications). Transcript persistence.
- **Local policy engine.** Rules evaluated before outbound messages and on inbound messages: rate limits, scope checks, auto-approve lists, redaction rules. Configured via `~/.tap/policy.toml` and per-repo `.tap/policy.toml` (per-repo file authoritative for repo-scoped decisions).
- **Outbound queue.** Persistent (SQLite-backed) buffer for messages destined for the relay when offline.
- **Telemetry.** Structured JSON logs, OpenTelemetry traces, optional anonymous usage metrics (opt-in only).

### 4.2 Distribution

Single static binary per platform.

- **macOS:** signed and notarized; Homebrew tap.
- **Linux:** musl static binary; deb / rpm / apk; AUR.
- **Windows:** signed MSI; Scoop.

Auto-update via signed manifests. Reproducible builds. Transparency log for releases.

### 4.3 Configuration

```toml
# ~/.tap/config.toml
[identity]
github_token_keychain_ref = "tap.github.token"

[relay]
url = "wss://relay.tap.dev"
ca_pin = "sha256:..."

[telemetry]
anonymous_metrics = false

# ~/.tap/policy.toml (user-global defaults)
[messaging]
default_inbound_scope_max = "advisory"
auto_approve_from = []  # list of GitHub usernames
rate_limit_outbound_per_minute = 30

[consults]
default_inbound_scope_max = "advisory"
require_human_approval_above_scope = "suggest_edit"
auto_summarize_after_turns = 20

# <repo>/.tap/policy.toml (per-repo overrides; authoritative for this repo)
[redaction]
exclude_files = [
  ".env*",
  "secrets/**",
  "**/*.pem",
  "**/*.key"
]

[consults]
auto_accept_from = ["riley", "sam"]  # for advisory-scope consults only
```

---

## 5. Relay

### 5.1 Tiers

**Edge tier.** Stateless WS gateway. Terminates TLS, validates JWTs, enforces rate limits, routes to core nodes by repo affinity (consistent hash on repo ID). Behind a global anycast load balancer. Per-connection memory budget under 50 KB to support 100k+ concurrent connections per edge node.

**Core tier.** Stateful. One process per repo shard. Owns:

- *Presence.* Sorted-set in Redis, heartbeat TTL. Diff broadcasts via in-memory pub/sub plus NATS for cross-node fanout.
- *Awareness state.* Live map of `repo → branch → developer → files → intent`. Hot path in Redis with Postgres write-behind. Changes published as deltas.
- *Message router.* `msg.send` → resolve recipients → push if connected, persist to durable inbox if not.
- *Consult coordinator.* Lifecycle state machine, transcript persistence with Ed25519 chaining, multi-party turn ordering (Lamport clocks plus relay-assigned sequence numbers), session multiplexing across a single WS connection.
- *Conflict orchestration.* Receives `conflict.check` requests, fans out to detector workers, returns aggregated results.
- *Durable inbox.* Per-agent message queue (Postgres, S3 archival).

**Worker tier.** Stateless compute, NATS JetStream consumers. Horizontally scalable.

- Level 2 hunk-overlap analysis
- Level 3 semantic conflict detection (tree-sitter parsing → symbol graph → cross-branch dependency analysis)
- Replay artifact generation
- Webhook fanout (GitHub, GitLab event ingestion)
- Audit log compliance exports

### 5.2 Storage

- **Postgres** (primary, read replicas): identity, team membership, durable inbox, audit log, billing, policy configuration, semantic graph cache, consult transcripts.
- **Redis** (cluster mode): presence, hot awareness state, rate limit counters, ephemeral session data.
- **NATS JetStream:** state diffs, work queues, audit fan-out.
- **S3-compatible:** audit archival, replay artifacts, semantic graph snapshots, consult context bundles (encrypted at rest with per-consult derived keys).
- **ClickHouse** (Phase 5+): analytics queries over audit log.

### 5.3 Deployment

Kubernetes. Multi-region active-active for edge; regional with DR replication for core. Postgres via managed provider (RDS / Cloud SQL / Crunchy Bridge) with PITR. Redis via managed cluster. NATS self-hosted.

### 5.4 Observability

OpenTelemetry traces end-to-end (every TAP message gets a trace ID that follows it from origin agent → daemon → relay → recipient daemon → recipient agent). Prometheus metrics. Structured logs to managed sink. Grafana dashboards. PagerDuty wired to SLO breaches.

---

## 6. Protocol (TAP v0.1)

### 6.1 Transport

- Daemon ↔ Relay: WSS, JSON-RPC 2.0, mTLS with pinned CA on daemon side, JWT for developer/agent identity in handshake.
- Daemon ↔ Agent: Unix socket / named pipe, JSON-RPC 2.0, no transport-level auth (process-local trust boundary).

### 6.2 Identity

- **Developer identity:** GitHub by default; SAML/OIDC for enterprise. Issued as JWT, short TTL, refresh token in OS keychain.
- **Agent identity:** `agent_id = hash(developer_id, machine_id, editor, session_id)`. Ephemeral; re-registers each session.
- **Repo identity:** canonical URL plus org membership; teams scoped within an org.
- **Trust pairs:** per-(developer, developer) trust state; controls auto-approve.

### 6.3 Message taxonomy

All messages carry `tap_version` (semver) and `trace_id`. Negotiated at handshake; relay supports N-1 major version.

**Lifecycle.**
- `agent.register` — initial handshake; capabilities, repo, branch, worktree
- `agent.heartbeat` — periodic liveness + state
- `agent.deregister` — clean shutdown
- `agent.disconnect` — server-initiated termination

**Awareness.**
- `state.announce` — push state changes (dirty files, intent, branch switches)
- `state.query` — request current awareness snapshot for a scope
- `state.subscribe` — long-lived subscription to state diffs
- `state.diff` — server-pushed delta

**Conflict.**
- `conflict.check` — pre-write check; returns conflict report (Level 1, 2, or 3 depending on what's available)
- `conflict.declare` — proactive declaration ("I'm about to edit X")
- `conflict.release` — release a declared lock
- `conflict.notify` — server-pushed notification of newly detected conflict

**Messaging.** (one-shot, addressed)
- `msg.send` — addressed message (dev → dev, agent → agent, agent → broadcast)
- `msg.deliver` — server-pushed delivery
- `msg.ack` — delivery and processing acknowledgement
- `msg.error` — delivery failure

**Consults.** (stateful, multi-turn)
- `consult.request` — initiator opens a consult; carries topic, context bundle reference, scope, urgency
- `consult.accept` — recipient accepts (human, agent, or auto-accept policy)
- `consult.reject` — recipient declines; may include suggested alternative
- `consult.message` — turn within an active consult
- `consult.context_update` — add files / diffs mid-consult
- `consult.invite` — add a third party
- `consult.handoff` — escalate consult into a `task.handoff`
- `consult.summarize` — request or push a rolling summary
- `consult.resolve` — terminal state with outcome and artifacts
- `consult.abandon` — terminal state without resolution
- `consult.observe` — human subscribes to live transcript

**Tasks.**
- `task.handoff` — request another agent take ownership of a task
- `task.accept` / `task.reject` — recipient response
- `task.update` — progress notification
- `task.complete` — terminal state with result

**Policy and trust.**
- `policy.evaluate` — server-side policy check (used by relay before delivering high-scope messages)
- `trust.grant` / `trust.revoke` — bilateral trust state changes (signed)
- `approval.request` / `approval.respond` — human-in-the-loop gate

### 6.4 Schemas

CUE schemas in `protocol/schemas/`. Build-time generation produces:

- `crates/tap-protocol` (Rust)
- `pkg/protocol` (Go)
- `packages/tap-protocol` (TypeScript)

Conformance test suite in `protocol/conformance/` — fixtures any implementation must pass.

### 6.5 Versioning

Protocol versioned independently of components. Backward compatibility maintained within a major version. Negotiated at handshake. Relay supports current and previous major version.

---

## 7. Conflict detection engine

Four levels, composable. A `conflict.check` returns the highest-confidence result available within the latency budget.

**Level 1 — File-level.** Two agents/worktrees have dirty changes to the same file path. Pure string match on awareness state. Implemented in daemon's local cache. Sub-50 ms.

**Level 2 — Hunk-level.** Line-range overlap analysis. Each daemon reports `(file, branch, [(start_line, end_line, op)])`. Conflict detector compares ranges. Worker job triggered by `conflict.check`; result cached at relay 30 s.

**Level 3 — Semantic.** Per-branch symbol graph built with tree-sitter. Graph stores definitions, references, type signatures, import edges. On `conflict.check`:

1. Map intended write to AST nodes
2. Query symbol graph for affected symbols
3. Check whether other branches modify same symbols, or modify symbols this write depends on
4. Produce structured conflict report

Languages at launch: Rust, TypeScript, Go, Python, Java. Cached aggressively per `(repo, branch, commit)`. Incremental rebuild on commit.

**Level 4 — Runtime/resource.** Shared ports, database migrations, environment variables, build cache invalidation. Detected via daemon-reported metadata (declared dev server ports, running migrations, modified config files).

---

## 8. Phased development plan

Each phase is a coherent milestone with explicit ship criteria. No time estimates; phases ship when criteria are met.

### Phase 1 — Protocol & foundations

**Goal:** stable specification and scaffolding.

**Deliverables:**
- TAP v0.1 specification document (formal)
- CUE schemas; generated bindings for Rust, Go, TypeScript
- Conformance test suite
- Repository structure, CI/CD pipeline, security policy, contribution guidelines
- Threat model document

**Ship criteria:** an external implementer can read the spec and produce a conformant client without consulting source code.

### Phase 2 — Daemon, local conflict detection, Claude Code adapter

**Goal:** a single developer running multiple agents in worktrees has Level 1 and Level 2 conflicts caught before write.

**Deliverables:**
- Daemon: git state engine, hunk diff tracker, local awareness cache, MCP server, agent router, local policy engine, outbound queue, telemetry
- Claude Code adapter: hook scripts (`SessionStart`, `PreToolUse`, `PostToolUse`, `Stop`), MCP server registration, full tool surface
- Level 1 and Level 2 conflict detection (local-only, no relay yet)
- CLI: `tap status`, `tap whois`, `tap conflicts`, `tap watch`, `tap log`
- Daemon distribution: signed binaries macOS / Linux / Windows; package manager artifacts
- Daemon test suite including chaos tests

**Ship criteria:** developer running 4 Claude Code agents in 4 worktrees on a real codebase reports zero false positives over a week and at least one prevented merge conflict.

### Phase 3 — Hosted relay, cross-developer awareness

**Goal:** multi-developer teams share awareness state and detect cross-developer conflicts.

**Deliverables:**
- Relay: edge tier, core tier, storage layer, deployment automation, observability stack
- Auth: GitHub OAuth Device Flow, JWT issuance, repo membership resolution, mTLS daemon connection
- Awareness state synchronization (`state.announce`, `state.subscribe`, `state.diff`)
- Cross-developer conflict detection (Levels 1 and 2)
- Daemon: relay connection management, awareness subscription, fallback to local-only on relay outage
- Web dashboard v1: live activity map, basic audit log view
- SLO instrumentation and alerting

**Ship criteria:** 5-developer team uses TAP in production for two weeks; awareness propagation P95 < 500 ms; documented case of cross-developer conflict caught before PR.

### Phase 4 — Messaging, consults, tasks, trust model

**Goal:** agents can ask each other questions and hand off tasks across developers, with full security model in force. Consults are the headline feature.

**Deliverables:**
- Messaging: `msg.send`, `msg.deliver`, `msg.ack`, `msg.error`, durable inbox
- **Consults: full `consult.*` taxonomy, lifecycle state machine, context bundling and resolution, transcript persistence, multi-party support**
- Task primitives: `task.handoff`, `task.accept`/`reject`, `task.update`, `task.complete`
- Trust graph: `trust.grant`, `trust.revoke`; UI in dashboard
- Approval gates: `approval.request`/`respond`; desktop notifications via daemon
- Sandboxed message handling: structured envelope, system-prompt injection-defense patterns documented and tested
- Policy engine: per-repo and per-developer policy with rate limits, scope rules, auto-approve lists
- Audit log with cryptographic chaining; admin console v1
- Anomaly detection on message volume and scope distribution

**Ship criteria:** documented scenario where two developers' agents collaborate on a feature via a consult without their humans manually copying context between them; security review of messaging path with no critical findings.

### Phase 5 — Semantic conflict detection, multi-editor support, dashboard v2

**Goal:** detection deep enough to be unambiguously valuable; ecosystem broad enough to be the default choice.

**Deliverables:**
- Level 3 semantic conflict detection: tree-sitter, symbol graph, cross-branch dependency analysis. Languages: Rust, TS, Go, Python, Java
- Level 4 resource conflict detection: ports, migrations, env vars
- Cursor adapter (MCP-based)
- Codex adapter (hooks + MCP)
- Aider adapter (upstream PR)
- Generic MCP adapter for long-tail editors
- Dashboard v2: conflict heatmap, agent timeline, advanced audit search, policy management UI
- Public conformance program

**Ship criteria:** semantic detection precision ≥ 90%, recall ≥ 75% on benchmark of real conflicts mined from public repos; three editors supported; one external community-built adapter certified.

### Phase 6 — Enterprise

**Goal:** defensible enterprise product.

**Deliverables:**
- SSO: SAML 2.0, OIDC, SCIM provisioning
- VPC / on-premises deployment: Helm charts, air-gapped install, license server
- Compliance: SOC 2 Type II, optional ISO 27001, GDPR endpoints, data residency controls
- Policy templates and bulk management; org-wide guardrails
- Compliance exports: SIEM-friendly streams (Splunk, Datadog, Elastic)
- Agent observability surface: per-agent activity reports for managers (with privacy controls)
- Incident response tooling: kill switch, agent quarantine, retroactive trust revocation, forensic export
- Customer success surfaces

**Ship criteria:** signed enterprise customer with on-premises deployment in production.

### Continuing concerns (parallel to all phases)

- Performance regression suite blocks relay deploys on SLO breach
- External pentest before Phase 4 ships; recurring annually after
- Protocol working group, public RFC process, conformance test additions
- Documentation treated as deliverable, not afterthought
- Community governance for protocol distinct from product

---

## 9. Working state

> **Update this section as work progresses. This is the agent's primary context for "what am I doing right now."**

### 9.1 Current phase

`Phase 1 — Protocol & foundations`

### 9.2 Current task

Phase 1 wire-format spec complete (2026-04-29): SPEC.md §6–§8 fully populated, eleven new CUE schemas, ~30 conformance fixtures including the sandboxing corpus, Phase 1 doc bundle stood up, RFC 0015 (MCP tool surface) drafted out of order. Foundation documentation system landed earlier the same day. Phase 1 scaffolding landed (2026-04-28). Next: install codegen toolchain locally and produce real bindings, wire doc lints in CI, validate the Phase 1 ship criterion with an external implementer.

### 9.3 Immediate next steps

**Done in this session (2026-04-29) — wire-format + RFC 0015:**

- ✅ Phase 1 wire-format spec finished. `protocol/SPEC.md` §6 (lifecycle) expanded with field tables, schema cross-refs, and examples. §7 (awareness) and §8 (conflict) replaced placeholders with full normative sections. Appendix A change log updated.
- ✅ Eleven new CUE schemas in `protocol/schemas/`: `common.cue` (shared `#Hunk`, `#DirtyFile`, `#AwarenessScope`, `#SubscriptionId`, `#ConflictLevel`, `#Confidence`, `#TtlSeconds`, `#Timestamp`, `#Intent`, `#FilePath`), `agent_heartbeat.cue`, `agent_deregister.cue`, `agent_disconnect.cue`, `state_announce.cue` (carries `#AgentAwarenessRecord`), `state_query.cue`, `state_subscribe.cue`, `state_diff.cue`, `conflict_check.cue` (carries `#ConflictReport`, `#IntendedWrite`, `#PeerRef`, `#HunkOverlap`), `conflict_declare.cue`, `conflict_release.cue`, `conflict_notify.cue`.
- ✅ ~30 conformance fixtures across the new schemas — every CUE definition gets at least one positive and one negative case. Negatives target real failure modes (inverted hunk ranges, path traversal, oversized TTLs, malformed declaration ids, confidence out of range, missing scope, empty required lists).
- ✅ Sandboxing fixture corpus at `protocol/conformance/fixtures/sandboxing/`: five negative fixtures (NUL byte, ANSI escape, RTL override, ASCII control char, length-bound bypass) and two accepted-but-dangerous positive fixtures (literal-text injection, fake-tool-result framing). README explains the schema-vs-consumer-layer split. Closes the Phase 1 deliverable from `docs/THREAT_MODEL.md` §5.3.
- ✅ Phase 1 doc bundle stood up at `docs/phases/phase-1/` from `_template/`: README (scope, ship criterion operationalized), test-plan, perf-budget, threat-model addendum, migration (N/A first phase), open-questions (5 entries: canonicalization rule, suite-version file, hermetic toolchains deferred to Phase 2, tap.dev needed for ship-criterion, A2A verification cadence), decisions, exit checklist.
- ✅ `docs/rfcs/0015-mcp-tool-surface.md` — out-of-order Phase 2 RFC authored in Phase 1. Specifies the daemon's MCP server contract: 11 v1.0 tools (state_announce, state_query, peers_on_file, conflict_check, conflict_declare, conflict_release, conflicts_pending, session_info, peers_list, policy_get, recent_activity) plus 12 reserved Phase 4 names. Covers transport (UDS / named pipe + UID check), discovery, schema validation, side-effect classification (`read_only` / `advisory` / `state_mutating`), the sandboxing-contract `peer_content_fields` declaration, error model, tool-surface versioning, alternatives (5), drawbacks, migration, security (STRIDE delta), 5 open questions.

**Done in prior session (2026-04-29) — foundation docs:**

- ✅ Foundation documentation system: doc taxonomy (six layers), per-phase doc spine (eight files), RFC numbering policy, YAML front-matter convention, one-fact-one-place rule, doc-dashboard / staleness gating. All described in `docs/DOCUMENTATION_PLAN.md`.
- ✅ Doc index `docs/README.md` — entry point with by-role guides and source-of-truth registry.
- ✅ Canonical glossary `docs/GLOSSARY.md` extracted from §10. §10 of this document is now a stub linking to the canonical glossary.
- ✅ Spec style guide `docs/SPEC_STYLE.md` — RFC 2119 vocabulary, snake_case method/field naming, error-code allocation, schema-prose-fixture coupling.
- ✅ Versioning policy `docs/VERSIONING.md` — promoted from `protocol/SPEC.md` §5; MAJOR/MINOR/PATCH semantics, negotiation algorithm, deprecation window, N-1 support, suite-version pinning.
- ✅ RFC process `docs/RFC_PROCESS.md` — lifecycle, required sections, reviewer rules, numbering ranges. Template at `docs/rfcs/0000-template.md`.
- ✅ Conformance policy `docs/CONFORMANCE.md` — implementation classes, runner contract, attestation format, trademark policy, dispute resolution.
- ✅ A2A mapping `docs/A2A_MAPPING.md` (draft) — conforming / extending / deviating taxonomy. `[verify]` markers for items requiring upstream A2A spec confirmation.
- ✅ Public roadmap `docs/ROADMAP.md` — phase-by-phase mirror of §8 for external readers.
- ✅ Risk register `docs/RISK_REGISTER.md` — 18 cross-phase risks (technical, security, market, organizational, legal/compliance) with severity, owner, mitigation, status.
- ✅ Templates: `docs/phases/_template/` (eight-file spine), `docs/runbooks/_template.md`, `docs/components/_template/` (ARCHITECTURE, CONFIG, OPERATING, SECURITY, INTERFACES).

**Done in prior session (2026-04-28):**

- ✅ Monorepo structure scaffolded: `protocol/`, `crates/tap-protocol/`, `pkg/protocol/`, `packages/tap-protocol/`, `tools/codegen/`, `docs/`, `.github/`.
- ✅ Bazel + bzlmod foundation: `MODULE.bazel`, `.bazelrc`, `.bazelversion` (7.4.1), root `BUILD.bazel`, `.gitignore`, `.gitattributes`, `.editorconfig`, `LICENSE` (Apache 2.0), `NOTICE`, `README.md`.
- ✅ Governance & community: `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1), `SECURITY.md`, `GOVERNANCE.md`, `ARCHITECTURE.md`, GitHub issue/PR templates, `dependabot.yml`.
- ✅ CI: `ci.yml` (Bazel build/test/conformance + codegen drift check), `codeql.yml`, `scorecard.yml`. Pre-commit config with buildifier, rustfmt, clippy, gofmt, prettier, cue fmt, addlicense, commitlint.
- ✅ Protocol scaffolding: `SPEC.md` skeleton with full table of contents and lifecycle messages section populated; CUE schemas for envelope, identity, `agent.register`. `cue.mod/module.cue` configured.
- ✅ Conformance harness: `conformance/README.md` documents fixture format (modeled on JSON Schema Test Suite); first fixtures for `agent.register` (valid request, valid response, missing required field, branch-traversal rejection) and envelope (wrong jsonrpc version, malformed trace_id).
- ✅ Codegen pipeline: `tools/codegen/generate.sh` orchestrates CUE → JSON Schema → typify (Rust) / json-schema-to-typescript (TS) / cue exp gengotypes (Go). Bazel `sh_binary` wraps it; `drift_check.sh` is the local test harness.
- ✅ Three binding packages scaffolded with hand-written envelope helpers (version negotiation, semver parsing) plus tests. Each has BUILD.bazel and native package manifest (Cargo.toml, go.mod, package.json).
- ✅ Per-language conformance test runners: `crates/tap-protocol/tests/conformance.rs`, `pkg/protocol/conformance_test.go`, `packages/tap-protocol/src/test/conformance.test.ts`. Currently exercise structural round-trip; per-schema typed assertions get added once codegen runs locally.
- ✅ `docs/THREAT_MODEL.md` covering assets, trust boundaries, adversaries, STRIDE-style decomposition, sandboxing of inbound agent messages (the "structured envelope, never raw prompt prepending" rule), supply chain, cryptographic primitives.

**Next (per the authorship order in `docs/DOCUMENTATION_PLAN.md` §9):**

1. **Install the codegen toolchain locally** (`cue`, `typify`, `json-schema-to-typescript`) and run `bazel run //tools/codegen:generate` to produce the first real bindings. Commit them. Verify `bazel test //...` is green across all three languages. Update the per-language conformance runners (`crates/tap-protocol/tests/conformance.rs`, `pkg/protocol/conformance_test.go`, `packages/tap-protocol/src/test/conformance.test.ts`) to execute the ~30 new fixtures added in this batch.
2. **Doc lints in CI.** Wire `markdownlint`, `vale`, and the custom `tools/doclint/` checks specified in `docs/DOCUMENTATION_PLAN.md` §10.1. Initially advisory on legacy doc paths per §11.
3. **Resolve the Phase 1 open questions** in `docs/phases/phase-1/open-questions.md`: pick a round-trip canonicalization rule (Q-1-001), land `protocol/conformance/VERSION` (Q-1-002), confirm the `tap.dev` provisioning question (Q-1-004), and verify the `[verify]` items in `docs/A2A_MAPPING.md` against the live A2A spec (Q-1-005).
4. **Author the next critical-path Phase 2 RFC: `rfcs/0030-claude-code-adapter.md`.** Consumes RFC 0015 and the daemon RFCs that come next. Defines hook contracts (`SessionStart`, `PreToolUse`, `PostToolUse`, `Stop`), MCP server registration with Claude Code, and the adapter-side conformance tests for the §3.7 sandboxing contract.
5. **Branch protection on `main`.** Configure once permissions allow: required signed commits, two-reviewer approval for `protocol/` and `tools/codegen/`, required CI checks, no force-push.
6. **Validate Phase 1 ship criterion:** hand the spec + schemas + conformance suite + foundation docs to an external engineer and confirm they can produce a passing client without reading TAP source. Operationalized in `docs/phases/phase-1/exit.md` §1.

### 9.4 Open questions

- **codegen toolchain hermeticity.** Phase 1 keeps `cue`, `typify`, `json2ts` as ambient host dependencies. Should we move to hermetic Bazel toolchains (`rules_rust` crate-universe for typify, `aspect_rules_js` for json2ts, `rules_oci` for cue) before Phase 2? Tradeoff: hermeticity vs. ramp-up cost. Lean toward yes by mid-Phase 2.
- **Conduct/security email aliases.** `conduct@tap.dev` and `security@tap.dev` are referenced in docs but not yet provisioned. Provision when domain is registered, or replace with GitHub-native flows (Security Advisories, GitHub-hosted CoC contact form).

### 9.5 Decision log

> Append-only record of decisions made during work. Each entry: date, decision, rationale, alternatives considered.

- **2026-04-28 — Build orchestrator: Bazel.** Chose Bazel over Make and `just` for the polyglot monorepo. Rationale: industry-standard for polyglot builds at scale (Google, Stripe, Pinterest, Uber), native reproducibility (mandated by §4.2), strong fit for the codegen pipeline's cross-language fan-out. Alternatives considered: Make (insufficient for codegen graph, weak Windows story), `just` (niche, ergonomic but not industry-standard), Buck2 (newer, smaller community), Nx/Turborepo (JS-first, wrong center of gravity), Pants/Earthly (niche). Cost: real ramp-up time and `BUILD.bazel` files in every directory.
- **2026-04-28 — Bzlmod, not legacy WORKSPACE.** Default in Bazel 8; legacy removed in Bazel 9. No reason to choose legacy for a new project.
- **2026-04-28 — Generated bindings committed, drift-checked.** Generated files under `**/generated/` are committed to the repo and checked for drift in CI (`bazel run //tools/codegen:generate && git diff --exit-code`). Rationale: §1.3 standards-aspirational posture demands external implementers can read source without installing Bazel + CUE. Tradeoff accepted: large diffs on schema changes, mitigated via `linguist-generated=true` in `.gitattributes`. Alternatives considered: build-only outputs (Bazel-pure but creates divergence between repo and published packages), generate-at-publish-time (more complex, marginal cleanliness gain).
- **2026-04-28 — Codegen tools.** Rust: `typify` (Oxide Computer; better Rust output than `quicktype`; ecosystem standard). TypeScript: `json-schema-to-typescript` (single-purpose, ~3M weekly downloads, ecosystem standard). Go: `cue exp gengotypes` (official CUE-team path; bypasses lossy JSON Schema hop). Asymmetry (Go skips JSON Schema) is noted; conformance suite is the safety net.
- **2026-04-28 — Conformance fixture format.** Plain JSON, modeled on the JSON Schema Test Suite format. Each fixture: `{name, description, schema_ref, data, expected_valid, expected_round_trip?, expected_error_code?}`. Alternatives rejected: YAML (extra parser dep), TOML (wrong shape), CUE-driven generation (ties conformance to CUE tooling).
- **2026-04-28 — Pre-commit framework.** `pre-commit` (pre-commit.com), the universal polyglot standard. Hooks: buildifier, rustfmt, clippy, gofmt, prettier, cue fmt, addlicense, commitlint, plus standard hygiene. Alternatives: husky (JS-only), lefthook (faster but less mature).
- **2026-04-28 — CI provider: GitHub Actions + CodeQL + OpenSSF Scorecard.** Universal for OSS-on-GitHub. Bazel integration via `bazel-contrib/setup-bazel`. Alternatives deferred: GitLab CI (Phase 6 enterprise concern at most).
- **2026-04-28 — License header tool: `addlicense`.** CNCF/Kubernetes standard. CI-blocking from day one. `license-eye` revisited if Phase 3's BUSL split makes multi-license complexity painful.
- **2026-04-28 — Conventional Commits, signed commits, OpenSSF Scorecard.** Adopted from day one. Enforced via commitlint + branch protection (forthcoming). Standard for serious OSS / security-adjacent projects.
- **2026-04-28 — Bazel remote cache deferred.** Local cache sufficient for Phase 1 build size. Add BuildBuddy free tier when CI builds exceed ~5 minutes (likely Phase 2 daemon work).
- **2026-04-28 — Bazel version pinned to 7.4.1.** Stable bzlmod, all rule ecosystems we need (rules_rust, rules_go, aspect_rules_ts) validated. Bumped via `.bazelversion` deliberately.
- **2026-04-28 — Rust MSRV 1.82, Go 1.23, Node 20.18 LTS.** Recent stable, well-supported by Bazel rule ecosystems.
- **2026-04-29 — Documentation taxonomy: six layers.** Foundation, Phase, RFC, Component, Runbook, Wire-format spec. Each layer has a defined location, lifecycle, and template. Specified in `docs/DOCUMENTATION_PLAN.md`. Rationale: end-to-end coverage across six phases requires a repeatable structure rather than ad-hoc per-phase documents. Alternatives rejected: single growing file (unscalable), free-form per-phase (inconsistent over time).
- **2026-04-29 — Phase doc spine.** Every phase produces the same eight files (README, test-plan, perf-budget, threat-model, migration, open-questions, decisions, exit). Templates at `docs/phases/_template/`. Phase exits gate on the spine being complete and on `last-reviewed` freshness. Same approach for components (`docs/components/_template/`) and runbooks (`docs/runbooks/_template.md`).
- **2026-04-29 — RFC numbering by phase.** RFCs use 4-digit prefixes; ranges pre-allocated to phases (Phase 1: 0001-0009, Phase 2: 0010-0099, Phase 3: 0100-0199, Phase 4: 0200-0299, Phase 5: 0300-0399, Phase 6: 0400-0499, continuing concerns: 0900-0999). Process specified in `docs/RFC_PROCESS.md`. Numbers reserved on RFC creation, never reused.
- **2026-04-29 — YAML front-matter on all new docs.** Schema: `status` (draft/accepted/implemented/superseded/withdrawn), `phase`, `owners`, `last-reviewed`, plus optional `supersedes`/`related`/RFC-specific fields. CI lints once `tools/doclint/` lands. Existing docs migrate the next time they are touched (no bulk-migration commit).
- **2026-04-29 — One-fact-one-place rule.** Each fact lives in exactly one document; other documents link. Source-of-truth registry in `docs/README.md`.
- **2026-04-29 — Glossary extracted from §10 to `docs/GLOSSARY.md`.** §10 of this document becomes a stub. Rationale: glossary is referenced from many other docs; centralization gives a stable URL and prevents drift. Same logic drove `docs/VERSIONING.md` (promoted from `protocol/SPEC.md` §5) and `docs/SPEC_STYLE.md` (the codified spec-authoring rules).
- **2026-04-29 — Conformance is binary at a given protocol version.** `docs/CONFORMANCE.md`. Per-class implementation requirements (daemon / relay / adapter / SDK), runner contract with a JSON output schema, attestation format, trademark policy gated on a current attestation, dispute resolution. Public registry deferred to Phase 5.
- **2026-04-29 — A2A mapping framework.** `docs/A2A_MAPPING.md` adopts a conforming / extending / deviating taxonomy. Verification of specific items against the live Google A2A spec is a Phase 1 follow-up; the document scaffolds the mapping with explicit `[verify]` markers for unverified claims. Drift-tracked as risk TR-004 in `docs/RISK_REGISTER.md`.
- **2026-04-29 — Risk register established.** `docs/RISK_REGISTER.md` with categories TR/SR/MR/OR/LR/CR, severity scale, append-only history. Initial seed of 18 cross-phase risks. Reviewed at every phase exit.
- **2026-04-29 — Phase 1 wire-format spec complete.** SPEC.md §6–§8 fully populated; eleven new CUE schemas; ~30 conformance fixtures; sandboxing corpus (Phase 1 deliverable from THREAT_MODEL §5.3). Per-phase open questions, decisions, and exit checklist tracked at `docs/phases/phase-1/`. Closes the Phase 1 spec deliverable from `project-context.md` §8 modulo the open questions logged in `phases/phase-1/open-questions.md`.
- **2026-04-29 — Wire-format design choices.** Lifecycle: `agent.disconnect.reason` is a closed enum (additions are MAJOR until v0.2 introduces a gracefully-ignore-unknown guarantee); `agent.heartbeat` carries a per-agent `sequence` for drop detection. Awareness: a single `#AgentAwarenessRecord` is reused across announce, query, subscribe, diff. Diffs use sequence-based resumption (`since_sequence`) with full-snapshot fallback when out of window. Conflict: `conflict.check` returns `level_reached` + `partial` flag, supporting "best-effort within latency budget" semantics. Free-text fields (`intent`, `detail`, `message`, `reason`) are bounded (≤ 256 chars) and either control-character-free (`#Intent`) or printable-ASCII-only (`detail`, `message`). Hunk ranges enforce `end_line >= start_line`. File paths reject `..` traversal. Conflict declarations bounded at 1-3600 s TTL.
- **2026-04-29 — Sandboxing corpus split: schema-layer vs. consumer-layer.** Negative fixtures (NUL, ANSI escape, RTL override, ASCII control, length bound) prove schema rejects smuggling vectors at parse time. Accepted-but-dangerous positive fixtures (literal "ignore prior instructions", fake-tool-result framing) lock in wire-level acceptance for legitimate text while the structured-envelope rule moves the defense to the consumer (adapter) layer. Adapter conformance tests in Phase 2 (Claude Code) and Phase 5 (others) verify the consumer-side defense.
- **2026-04-29 — RFC 0015 (MCP tool surface) authored out of order in Phase 1.** Specifies the contract every Phase 2 adapter and the daemon's MCP server depend on. Twelve v1.0 tools across awareness / conflict / introspection / policy / audit; twelve Phase 4 names reserved. Architectural choices: MCP over local Unix socket / named pipe with UID-checked socket permissions; per-tool side-effect classification (`read_only` / `advisory` / `state_mutating`); `peer_content_fields` declaration on every output schema that may carry peer-controlled text (the editor-boundary operationalization of THREAT_MODEL §5); tool-surface versioning independent from wire-protocol versioning. Five alternatives considered and rejected or deferred.
- **2026-04-29 — Pull-based notifications in v1.0; push deferred.** `tap_conflicts_pending` is a poll. MCP server-initiated messages are uneven across editors; defer to a MINOR tool-surface bump after Phase 2 confirms which editors support push. Recorded as Q-15-001.
- **2026-04-29 — Token-aware adapter conventions (RFC 0015 amendment).** Initial v1.0 design would have leaked ~100k+ tokens of TAP-derived content per 30-turn session on a 20-developer team — eager start-of-turn awareness dumps, full structured payloads, inline consult bundles. Amended RFC 0015 with three guiding principles: pull-not-push (auto-inject only a ≤30-token session-start banner; deeper pulls only when banner reports pending items), synthesize-not-serialize (every state tool gains a `format` parameter with `summary` default returning daemon-synthesized prose 5–10× cheaper than structured JSON), scope-tightly (subscription scope narrowed at register time; `tap_peers_on_file` filters by relevance). Concrete changes: §3.10 (nine binding adapter conventions), `tap_conflict_check` returns `{ "ok": true }` on no-conflict, `tap_conflicts_pending` defaults to digest mode with `_expand` companion, `format` parameter on `tap_state_query`/`tap_peers_on_file`/`tap_peers_list`/`tap_recent_activity`, lazy-bundle convention reserved binding for Phase 4 consult/message tools (§6.1) so consult bundles travel by handle and are fetched per-file via `tap_consult_bundle_get`. Per-session fixed overhead drops from ~135k tokens to ~2k; variable cost scales with actual cross-developer activity. Phase 2 conformance test of ≤100 tokens/turn TAP-derived content steady state. Resolves Phase 1 open question Q-1-006.

### 9.6 Deferred items

> Things noticed during work that are out of scope for the current phase but should not be forgotten.

- **Hermetic codegen toolchains.** Move `cue`, `typify`, `json2ts` from ambient host deps to Bazel-managed toolchains. Phase 2.
- **Bazel remote cache.** Add BuildBuddy free tier when CI build time exceeds ~5 min.
- **rules_rust crate-universe.** Wire Cargo dep resolution into Bazel proper instead of relying on Cargo at the Bazel boundary. Phase 2 once `tap-daemon` lands and depends on tokio, rustls, etc.
- **`tap.dev` domain.** Acquire and provision `security@tap.dev`, `conduct@tap.dev`, PGP key for security disclosures.
- **Branch protection on `main`.** Configure once repo is on GitHub: required signed commits, two-reviewer approval for `protocol/` and `tools/codegen/`, required CI checks, no force-push.
- **Public PGP key for security disclosures.** Generate and publish before first tagged release.
- **`SPEC.md` rendered HTML.** Phase 2 — render to HTML and host at `tap.dev/spec/v0.1/`.
- **Conformance fixtures for prompt-injection patterns.** Threat model §5.3 calls for negative test cases for documented injection patterns. Add to `protocol/conformance/fixtures/sandboxing/` once messaging/consult schemas land in Phase 4.

---

## 10. Glossary

The canonical glossary is [`docs/GLOSSARY.md`](docs/GLOSSARY.md). Every domain term used in TAP documentation, source code, and the wire protocol is defined there. Add new terms there in the same change that introduces them.

This section is retained as a stable section anchor; other documents that historically linked to `project-context.md#10-glossary` continue to land on this redirect.

---

## Appendix A — Working norms for agents on this project

When you (Claude Code, or another agent) are working inside the TAP repository:

1. **Read sections 1, 2, and 9 of this document at the start of every session.**
2. **Update section 9.3 (next steps), 9.5 (decision log), and 9.6 (deferred items) as you work.** Future sessions depend on your notes.
3. **Do not change section 2 (locked decisions) without explicit user approval.** Surface the proposal in 9.4 (open questions) instead.
4. **Per-component CLAUDE.md files exist in each subdirectory** with component-specific instructions (e.g. `crates/tap-daemon/CLAUDE.md` describes the daemon's internal architecture). Read those when working in that component.
5. **The protocol spec is the source of truth for wire format.** Code generation flows from CUE schemas; do not hand-edit generated bindings.
6. **Conformance tests gate every protocol change.** Update tests before changing the spec.
7. **Dogfood TAP on TAP.** Once Phase 2 ships, the project itself runs on TAP — your own coordination with parallel agents goes through the daemon you're building.