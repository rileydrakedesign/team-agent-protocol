---
status: draft
phase: N
owners: ["@your-github-handle"]
last-reviewed: YYYY-MM-DD
---

# Phase N — Performance Budget

This document specifies the performance constraints for Phase N. Every constraint here ties back to a project-level SLO at [`../../../project-context.md` §3.3](../../../project-context.md#33-service-level-objectives) or a phase-specific decision recorded in [`decisions.md`](decisions.md).

A phase cannot exit if any budget here is unmet.

---

## 1. Operation budgets

For each operation introduced or affected by this phase, a budget. Latency at P50 and P95; memory ceiling; throughput floor where applicable.

| Operation | P50 | P95 | Memory | Throughput | Notes |
| --------- | --- | --- | ------ | ---------- | ----- |
| …         | …   | …   | …      | …          | …     |

Cross-reference each operation to its SLO ancestor. Tightening the budget is allowed; loosening it requires a decision-log entry and an update to [`../../../project-context.md` §3.3](../../../project-context.md#33-service-level-objectives) if applicable.

---

## 2. Resource budgets

Steady-state resource use of components introduced this phase.

| Component | CPU (steady) | Memory (steady) | Disk | Network |
| --------- | ------------ | --------------- | ---- | ------- |
| …         | …            | …               | …    | …       |

---

## 3. Latency budget breakdown

For end-to-end SLOs, decompose into per-hop budgets so component owners know what their share is.

> Example (Phase 3 cross-developer conflict check):
>
> - Originating daemon local cache lookup: 5 ms
> - Daemon → relay WSS round-trip: 30 ms
> - Relay routing + state lookup: 20 ms
> - Relay → recipient daemon push: 30 ms
> - Recipient daemon evaluation: 5 ms
> - Total P95: 90 ms (budget: 100 ms)

Document each leg.

---

## 4. Measurement

### 4.1 Instrumentation

Every operation in §1 MUST be instrumented for latency, memory, and (where relevant) throughput. Implementation lives in `<component>/observability/` or equivalent.

### 4.2 Benchmarks

Reproducible benchmarks live at `<component>/tests/perf/`. Baselines are stored in `tests/perf/baselines/` and updated by an explicit PR (never automatically).

### 4.3 Regression gate

CI runs benchmarks on every PR touching the relevant component and fails on a regression of more than 5% from the rolling 7-day baseline.

---

## 5. Known-acceptable trade-offs

Trade-offs deliberately accepted for this phase. Each entry includes the reason and the phase that addresses it (if any).

- …

---

## 6. Future tightening

Budgets to tighten in a later phase, with the criterion that triggers the tightening.

- …
