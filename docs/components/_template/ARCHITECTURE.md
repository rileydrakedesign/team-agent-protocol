---
status: draft
phase: N
owners: ["@your-github-handle"]
last-reviewed: YYYY-MM-DD
component: <component-name>
---

# `<component>` — Architecture

> **How to use this template.** Copy `docs/components/_template/` to `docs/components/<component>/`. Fill in every file. Update front-matter `component:` field. Templates use angle-bracket placeholders; remove all of them when authoring. Do not delete files; if a file is not applicable, leave it in place with `N/A — <reason>`.

This document describes the internal architecture of `<component>`. It is the entry point for engineers working on the component.

---

## 1. Purpose

What does `<component>` do? One paragraph. Tie back to a project-level concern via [`../../../project-context.md`](../../../project-context.md) and [`../../GLOSSARY.md`](../../GLOSSARY.md) terms.

## 2. Boundaries

What is in this component. What is not. What other components it depends on. What other components depend on it.

| Side  | Component | Transport | Contract                         |
| ----- | --------- | --------- | -------------------------------- |
| Above | …         | …         | [`INTERFACES.md`](INTERFACES.md) |
| Below | …         | …         | …                                |
| Peer  | …         | …         | …                                |

## 3. Internal structure

Modules and their responsibilities. Use ASCII diagrams in preference to images.

```
<component>
├── module-a/    purpose
├── module-b/    purpose
└── module-c/    purpose
```

## 4. Lifecycle

Startup, steady state, shutdown.

- **Startup.** What happens, in what order, with what failure modes.
- **Steady state.** What is the component continuously doing.
- **Shutdown.** Clean shutdown sequence and guarantees.

## 5. State

Where the component holds state, durable or in-memory.

| Store | Schema | Durability | Owner module |
| ----- | ------ | ---------- | ------------ |
| …     | …      | …          | …            |

## 6. Concurrency model

Threads, async runtimes, locks, queues. Where the component blocks. Where it parallelizes.

## 7. Failure modes

For each plausible failure: what fails, what the component does, what users observe.

| Failure | Behavior | Recovery |
| ------- | -------- | -------- |
| …       | …        | …        |

## 8. Observability

How operators see what the component is doing. Cross-link to the metrics catalog in `OBSERVABILITY.md` (component-level) or [`OPERATING.md`](OPERATING.md).

## 9. Performance

Reference [`../../phases/phase-N/perf-budget.md`](../../phases/) for the binding budget. Discuss the architectural choices that meet that budget.

## 10. Security

Cross-link [`SECURITY.md`](SECURITY.md). The architecture-level summary lives here; the threat-table-level detail lives there.

## 11. Open questions

Component-level open questions. Move to the phase's `open-questions.md` if cross-component.

## 12. Related

- [`CONFIG.md`](CONFIG.md) — configuration reference.
- [`OPERATING.md`](OPERATING.md) — how to run it.
- [`SECURITY.md`](SECURITY.md) — security posture.
- [`INTERFACES.md`](INTERFACES.md) — boundary contracts.
- RFCs: …
