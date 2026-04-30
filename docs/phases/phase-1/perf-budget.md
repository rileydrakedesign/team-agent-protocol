---
status: draft
phase: 1
owners: [@rileydrakedesign]
last-reviewed: 2026-04-29
---

# Phase 1 — Performance Budget

Phase 1 ships no runtime components. The only operations with a measurable cost are codegen, schema validation, and the per-language conformance runners, all of which are developer-time tooling rather than runtime hot paths.

The project-level SLOs at [`../../../project-context.md` §3.3](../../../project-context.md#33-service-level-objectives) become operative in Phase 2 (sub-50 ms local conflict check) and Phase 3 (sub-100 ms cross-developer conflict check, sub-500 ms awareness propagation). Phase 1's perf-budget is intentionally narrow.

---

## 1. Tooling budgets

These are developer-experience targets, not contracts.

| Operation | Target | Measurement |
|---|---|---|
| `bazel run //tools/codegen:generate` (cold) | ≤ 60 s | wall-clock on commodity laptop. |
| `bazel run //tools/codegen:generate` (warm) | ≤ 5 s | wall-clock with Bazel cache populated. |
| `bazel test //...` (full) | ≤ 90 s in CI | GitHub Actions ubuntu-latest runner. |
| Conformance runner (per language) | ≤ 2 s | full suite on local machine. |

If `bazel test //...` exceeds 5 minutes in CI, the deferred BuildBuddy remote-cache item in [`../../../project-context.md` §9.6](../../../project-context.md#96-deferred-items) is promoted from deferred to active.

## 2. Resource budgets

Phase 1 has no steady-state runtime resource consumption to budget. Codegen and tests run on demand and exit.

## 3. Latency-budget breakdown

N/A — no end-to-end SLOs apply in Phase 1.

## 4. Measurement

CI publishes wall-clock job durations. There is no perf-regression gate in Phase 1. The gate becomes operative in Phase 2 once there is a runtime hot path to measure.

## 5. Known-acceptable trade-offs

- The `cue exp gengotypes` path is slower per-run than `typify` or `json-schema-to-typescript` on cold cache. Trade-off accepted; the asymmetry is documented in [`../../../project-context.md` §9.5](../../../project-context.md#95-decision-log).

## 6. Future tightening

No tightening planned for Phase 1. Phase 2 perf budgets are stricter (sub-50 ms PreToolUse hook) and live in `docs/phases/phase-2/perf-budget.md` once Phase 2 doc bundle stands up.
