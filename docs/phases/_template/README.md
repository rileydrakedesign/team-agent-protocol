---
status: draft
phase: N
owners: ["@your-github-handle"]
last-reviewed: YYYY-MM-DD
---

# Phase N — Title

> **How to use this template.** Copy `docs/phases/_template/` to `docs/phases/phase-N/` and fill in every file. Do not delete files; if a file is not applicable, leave it in place with `N/A — <reason>`. Update front-matter, file names, and content. The doc spine is specified in [`../../DOCUMENTATION_PLAN.md`](../../DOCUMENTATION_PLAN.md) §3.

This document is the entry point for everything about Phase N. It links to the rest of the phase's doc bundle and to the relevant RFCs.

---

## 1. Goal

One sentence stating the phase's outcome. Should be testable, not aspirational.

> Example (Phase 2): A single developer running multiple Claude Code agents in worktrees gets Level 1 and Level 2 conflicts caught before write, on their own machine, without a hosted relay.

## 2. Scope

### 2.1 In scope

Bulleted list of deliverables. Each deliverable links to the RFC, component doc, or spec section that defines it.

- …
- …

### 2.2 Out of scope

What this phase deliberately does not include. Items here SHOULD link forward to the phase that addresses them.

- …
- …

## 3. Dependencies

What must be true before this phase can start, and what must be true before this phase can end.

### 3.1 Inputs from prior phases

- …

### 3.2 Outputs consumed by later phases

- …

## 4. Ship criterion

Restate the criterion from [`../../../project-context.md` §8](../../../project-context.md#8-phased-development-plan). Operationalize it in [`exit.md`](exit.md): who runs the test, how is the result captured, what artifact constitutes evidence.

## 5. Doc index for this phase

| Doc                                      | Purpose                                                                   |
| ---------------------------------------- | ------------------------------------------------------------------------- |
| [`README.md`](README.md)                 | This file.                                                                |
| [`test-plan.md`](test-plan.md)           | Coverage and gating tests.                                                |
| [`perf-budget.md`](perf-budget.md)       | Latency, memory, throughput targets.                                      |
| [`threat-model.md`](threat-model.md)     | Phase-specific delta to [`../../THREAT_MODEL.md`](../../THREAT_MODEL.md). |
| [`migration.md`](migration.md)           | What changes from the previous phase.                                     |
| [`open-questions.md`](open-questions.md) | Unresolved questions for this phase.                                      |
| [`decisions.md`](decisions.md)           | Append-only decision log for this phase.                                  |
| [`exit.md`](exit.md)                     | Ship-criterion checklist.                                                 |

## 6. RFCs

RFCs allocated to this phase per [`../../DOCUMENTATION_PLAN.md`](../../DOCUMENTATION_PLAN.md) §5. Update as RFCs land.

| Number | Title | Status                         |
| ------ | ----- | ------------------------------ |
| `NNNN` | …     | draft / accepted / implemented |

## 7. Component docs

Components introduced or modified in this phase. Each links to its `docs/components/<component>/` directory.

| Component | Path                            | Status                           |
| --------- | ------------------------------- | -------------------------------- |
| …         | `../../components/<component>/` | scaffolding / partial / complete |

## 8. Working notes

Free-form scratch space. May reference back to [`../../../project-context.md` §9](../../../project-context.md#9-working-state) when cross-phase context is needed.
