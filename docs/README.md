---
status: accepted
phase: continuing
owners: [@rileydrakedesign]
last-reviewed: 2026-04-29
---

# TAP Documentation Index

This directory is the entry point for everything written about TAP that is not source code. The single source of truth for project-level decisions remains [`../project-context.md`](../project-context.md); this index is the map.

If you are new to the project, read the documents in [Quick start](#quick-start) below in order. If you came here for a specific task, jump to the relevant section.

---

## Quick start

Read these in order on your first session.

1. [`../project-context.md`](../project-context.md) §1 — product thesis (why TAP exists)
2. [`../project-context.md`](../project-context.md) §2 — locked architectural decisions
3. [`../project-context.md`](../project-context.md) §9 — current phase and working state
4. [`GLOSSARY.md`](GLOSSARY.md) — every domain term used in the project
5. [`ROADMAP.md`](ROADMAP.md) — phase plan at a glance

For agents (Claude Code or otherwise) working in this repository, also read [`../project-context.md` Appendix A](../project-context.md#appendix-a--working-norms-for-agents-on-this-project).

---

## Documentation taxonomy

TAP documentation is organized into six layers. Every document belongs to exactly one layer.

| Layer | Where it lives | What it contains | Lifecycle |
|---|---|---|---|
| **Foundation** | `docs/*.md` (top level) | Cross-cutting rules, conventions, processes. Glossary, style guide, versioning policy, RFC process, conformance policy, roadmap, risk register, threat model, architecture overview. | Stable; revised through RFCs. |
| **Phase** | `docs/phases/phase-N/` | Per-phase scope, test plan, perf budget, threat-model addendum, decisions, open questions, exit checklist. | One bundle per phase, frozen at phase exit. |
| **RFC** | `docs/rfcs/NNNN-*.md` | One RFC per major design decision or component. Numbered, append-only, immutable after acceptance. | Draft → Discussion → Accepted → Implemented → Superseded. |
| **Component** | `docs/components/<component>/` | Per-component design, configuration reference, operating guide, security posture, interface contracts. | Lives with the component; updated as code changes. |
| **Runbook** | `docs/runbooks/*.md` | Operational procedures: install, deploy, recover, on-call. | Updated per incident or release. |
| **Wire-format spec** | `protocol/SPEC.md` + `protocol/schemas/*.cue` + `protocol/conformance/fixtures/*` | Normative protocol. CUE is authoritative; prose and fixtures are coupled. | Versioned per [`VERSIONING.md`](VERSIONING.md). |

Templates for the Phase, Component, and Runbook layers live at:

- [`phases/_template/`](phases/_template/)
- [`components/_template/`](components/_template/)
- [`runbooks/_template.md`](runbooks/_template.md)

Copy the template directory when starting a new phase or component.

---

## By role

### I am an agent (or human) starting work in this repo

1. Read the [Quick start](#quick-start).
2. Read [`../project-context.md`](../project-context.md) §9 for the current task.
3. Read the per-component `CLAUDE.md` if you are working inside a component subdirectory.
4. Update [`../project-context.md`](../project-context.md) §9.3, §9.5, §9.6 as you work, per Appendix A.

### I want to implement a TAP-conformant client

1. Read [`../protocol/SPEC.md`](../protocol/SPEC.md) — normative wire format.
2. Read [`SPEC_STYLE.md`](SPEC_STYLE.md) — vocabulary used in the spec.
3. Read [`VERSIONING.md`](VERSIONING.md) — version negotiation rules.
4. Run [`../protocol/conformance/`](../protocol/conformance/) — fixtures your client must pass.
5. Read [`CONFORMANCE.md`](CONFORMANCE.md) — how to claim conformance.

### I want to operate a TAP relay

1. Read [`../project-context.md` §5](../project-context.md#5-relay) — relay tier model.
2. Read [`components/relay/`](components/relay/) — per-component reference.
3. Read [`runbooks/`](runbooks/) — operational procedures.

### I want to propose a design change

1. Read [`RFC_PROCESS.md`](RFC_PROCESS.md).
2. Copy [`rfcs/0000-template.md`](rfcs/0000-template.md) to a new numbered file.
3. Open a pull request with the RFC; link to discussion in the issue tracker.

### I want to report or audit a security concern

1. Read [`SECURITY.md`](SECURITY.md) — disclosure policy.
2. Read [`THREAT_MODEL.md`](THREAT_MODEL.md) — current threat model.

### I want to contribute code or docs

1. Read [`CONTRIBUTING.md`](CONTRIBUTING.md).
2. Read [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).
3. Read [`GOVERNANCE.md`](GOVERNANCE.md) for review and merge policy.

---

## Document status conventions

Every document carries a YAML front-matter block:

```yaml
---
status: draft | accepted | implemented | superseded | withdrawn
phase: 1 | 2 | 3 | 4 | 5 | 6 | continuing
owners: [@github-handle, ...]
last-reviewed: YYYY-MM-DD
supersedes: docs/path-or-rfc.md   # optional
related: [docs/path.md, ...]      # optional
---
```

Status meanings:

- **draft** — under active authoring; not yet reviewed.
- **accepted** — reviewed and merged; binding.
- **implemented** — RFC whose code has shipped.
- **superseded** — replaced by a newer document; kept for history.
- **withdrawn** — abandoned without acceptance.

Documents older than 90 days without a `last-reviewed` bump are flagged stale by CI and block phase exits until refreshed.

---

## One-fact-one-place rule

Each fact lives in exactly one document. Other documents link to it; they never restate it. If you find yourself paraphrasing a rule, decision, or definition that already exists somewhere, link instead.

| Topic | Single source of truth |
|---|---|
| Glossary | [`GLOSSARY.md`](GLOSSARY.md) |
| Locked architectural decisions | [`../project-context.md` §2](../project-context.md#2-locked-architectural-decisions) |
| Service-level objectives | [`../project-context.md` §3.3](../project-context.md#33-service-level-objectives) |
| Wire format | [`../protocol/SPEC.md`](../protocol/SPEC.md) and [`../protocol/schemas/`](../protocol/schemas/) |
| Protocol versioning | [`VERSIONING.md`](VERSIONING.md) |
| Spec writing conventions | [`SPEC_STYLE.md`](SPEC_STYLE.md) |
| Conformance certification | [`CONFORMANCE.md`](CONFORMANCE.md) |
| RFC process | [`RFC_PROCESS.md`](RFC_PROCESS.md) |
| Threat model | [`THREAT_MODEL.md`](THREAT_MODEL.md) |
| Risk register | [`RISK_REGISTER.md`](RISK_REGISTER.md) |
| Phased plan | [`../project-context.md` §8](../project-context.md#8-phased-development-plan); [`ROADMAP.md`](ROADMAP.md) is the public mirror. |
| A2A conformance | [`A2A_MAPPING.md`](A2A_MAPPING.md) |
| Working state (current phase, task, decisions) | [`../project-context.md` §9](../project-context.md#9-working-state) |

---

## Index of foundation documents

| Document | Purpose |
|---|---|
| [`README.md`](README.md) | This file. The map. |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | High-level architecture entry point; defers to `project-context.md` §3–§7. |
| [`GLOSSARY.md`](GLOSSARY.md) | Canonical definitions. |
| [`SPEC_STYLE.md`](SPEC_STYLE.md) | Spec-writing conventions. |
| [`VERSIONING.md`](VERSIONING.md) | Protocol versioning policy. |
| [`RFC_PROCESS.md`](RFC_PROCESS.md) | RFC lifecycle and authoring rules. |
| [`CONFORMANCE.md`](CONFORMANCE.md) | Conformance claims and certification. |
| [`A2A_MAPPING.md`](A2A_MAPPING.md) | Mapping to Google Agent2Agent. |
| [`ROADMAP.md`](ROADMAP.md) | Public-facing roadmap. |
| [`RISK_REGISTER.md`](RISK_REGISTER.md) | Cross-phase risk log. |
| [`THREAT_MODEL.md`](THREAT_MODEL.md) | Project-wide threat model. |
| [`SECURITY.md`](SECURITY.md) | Security disclosure policy. |
| [`GOVERNANCE.md`](GOVERNANCE.md) | Steering and review governance. |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Contribution guidelines. |
| [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) | Community code of conduct. |
| [`DOCUMENTATION_PLAN.md`](DOCUMENTATION_PLAN.md) | How the documentation system itself is maintained. |

---

## Update policy

This index is updated whenever:

- A new top-level document is added under `docs/`.
- A document changes status (e.g., draft → accepted).
- A new component, phase, or RFC directory is created.
- A document is superseded or withdrawn.

Bump `last-reviewed` whenever you touch this file.
