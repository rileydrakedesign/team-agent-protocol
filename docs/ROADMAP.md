---
status: accepted
phase: continuing
owners: ["@rileydrakedesign"]
last-reviewed: 2026-04-29
---

# TAP Roadmap

This is the public-facing roadmap for the Team Agent Protocol. The canonical source for the phased plan is [`../project-context.md` §8](../project-context.md#8-phased-development-plan). This document mirrors that plan in a form suitable for external readers.

No fixed dates. Phases ship when their ship criteria are met.

Current phase, current task, and most recent decisions are in [`../project-context.md` §9](../project-context.md#9-working-state).

---

## At a glance

| #   | Phase                                                   | Headline outcome                                                                                                        | Status       |
| --- | ------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- | ------------ |
| 1   | Protocol & foundations                                  | A stable v0.1 spec an external implementer can build against.                                                           | In progress. |
| 2   | Daemon, local conflict detection, Claude Code adapter   | A single developer running multiple agents in worktrees has Level 1 + 2 conflicts caught before write.                  | Not started. |
| 3   | Hosted relay, cross-developer awareness                 | Multi-developer teams share awareness state and detect cross-developer conflicts.                                       | Not started. |
| 4   | Messaging, consults, tasks, trust model                 | Agents on different developers' machines can consult each other, with full security model in force. _Headline feature._ | Not started. |
| 5   | Semantic conflict detection, multi-editor, dashboard v2 | Detection deep enough to be unambiguously valuable; ecosystem broad enough to be a default choice.                      | Not started. |
| 6   | Enterprise                                              | Defensible enterprise product (SSO, on-prem, compliance).                                                               | Not started. |

---

## Phase 1 — Protocol & foundations

**Goal.** A stable protocol specification and the scaffolding to maintain it.

**What ships.**

- TAP v0.1 specification (formal, normative).
- CUE schemas; generated bindings in Rust, Go, TypeScript.
- Conformance test suite.
- Repository scaffolding, CI/CD, governance docs, threat model.

**Ship criterion.** An external implementer can read the spec and produce a conformant client without consulting source code.

---

## Phase 2 — Daemon, local conflict detection, Claude Code adapter

**Goal.** A single developer running multiple agents in worktrees gets Level 1 and Level 2 conflicts caught before write, on their own machine, without a hosted relay.

**What ships.**

- Local daemon: git state engine, hunk diff tracker, awareness cache, MCP server, agent router, policy engine, outbound queue, telemetry.
- Claude Code adapter: hook scripts, MCP server registration, tool surface.
- Level 1 (file) and Level 2 (hunk) conflict detection (local-only).
- CLI: `tap status`, `tap whois`, `tap conflicts`, `tap watch`, `tap log`.
- Signed binaries for macOS / Linux / Windows.

**Ship criterion.** A developer running 4 Claude Code agents in 4 worktrees on a real codebase reports zero false positives over a week and at least one prevented merge conflict.

---

## Phase 3 — Hosted relay, cross-developer awareness

**Goal.** Multi-developer teams share awareness state in real time and detect cross-developer conflicts.

**What ships.**

- Relay: edge tier, core tier, storage layer (Postgres, Redis, NATS, S3), deployment automation, observability stack.
- Identity: GitHub OAuth Device Flow, JWT issuance, repo membership resolution, mTLS daemon connection.
- Awareness state synchronization.
- Cross-developer conflict detection (Levels 1 and 2, daemon ↔ relay).
- Web dashboard v1: live activity map, basic audit log view.

**Ship criterion.** A 5-developer team uses TAP in production for two weeks; awareness propagation P95 under 500 ms; documented case of a cross-developer conflict caught before PR.

---

## Phase 4 — Messaging, consults, tasks, trust model

**Goal.** Agents on different developers' machines can ask each other questions, hand off tasks, and collaborate — with the full security model (scopes, trust graph, approval gates, policy, audit) in force.

**What ships.**

- Messaging primitives.
- Consults: stateful, multi-turn, multi-party, with lifecycle, transcripts, summarization, observation.
- Task primitives: handoff, accept/reject, update, complete.
- Trust graph and signed mutations.
- Approval gates with desktop-notification UX.
- Sandboxed message handling enforcing the structured-envelope rule.
- Policy engine (rate limits, scope checks, auto-approve, redaction).
- Audit log with cryptographic chaining; admin console v1.

**Ship criterion.** A documented scenario where two developers' agents collaborate on a feature via a consult without their humans manually copying context between them. External security review of the messaging path with no critical findings.

---

## Phase 5 — Semantic conflict detection, multi-editor, dashboard v2

**Goal.** Detection deep enough to be unambiguously valuable. Ecosystem broad enough to be a default choice across editors.

**What ships.**

- Level 3 semantic conflict detection: tree-sitter symbol graph, cross-branch dependency analysis. Languages at launch: Rust, TypeScript, Go, Python, Java.
- Level 4 resource detection: ports, migrations, environment variables.
- Cursor adapter (MCP-based).
- Codex adapter (hooks + MCP).
- Aider adapter (upstream PR).
- Generic MCP adapter for long-tail editors.
- Dashboard v2: conflict heatmap, agent timeline, advanced audit search, policy management UI.
- Public conformance program (registry, badges, certification process).

**Ship criterion.** Semantic detection precision ≥ 90%, recall ≥ 75% on a benchmark of real conflicts mined from public repos. Three editors supported. One external community-built adapter certified.

---

## Phase 6 — Enterprise

**Goal.** A defensible enterprise product.

**What ships.**

- SSO: SAML 2.0, OIDC, SCIM provisioning.
- VPC and on-premises deployment: Helm charts, air-gapped install, license server.
- Compliance: SOC 2 Type II, optional ISO 27001, GDPR endpoints, data-residency controls.
- Policy templates and bulk management; org-wide guardrails.
- Compliance exports: SIEM-friendly streams (Splunk, Datadog, Elastic).
- Per-agent activity reports for managers (with privacy controls).
- Incident response tooling: kill switch, agent quarantine, retroactive trust revocation, forensic export.

**Ship criterion.** A signed enterprise customer with on-premises deployment in production.

---

## Continuing concerns

These run in parallel to all phases and are not gated by any single one:

- A performance regression suite that blocks relay deploys on SLO breach.
- An external pentest before Phase 4 ships; recurring annually thereafter.
- A protocol working group with a public RFC process (per [`RFC_PROCESS.md`](RFC_PROCESS.md)) and ongoing additions to the conformance test suite.
- Documentation as a deliverable, not an afterthought.
- Community governance for the protocol distinct from the product.

---

## How to track progress

- **Current phase and task:** [`../project-context.md` §9.1, §9.2](../project-context.md#9-working-state).
- **Decisions:** [`../project-context.md` §9.5](../project-context.md#95-decision-log) and per-phase `decisions.md`.
- **Risks:** [`RISK_REGISTER.md`](RISK_REGISTER.md).
- **RFCs:** [`rfcs/`](rfcs/).

For external observers without commit access, the most useful entry point is [`../project-context.md` §9](../project-context.md#9-working-state) plus the [`rfcs/`](rfcs/) index once it is populated.
