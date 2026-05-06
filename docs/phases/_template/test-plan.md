---
status: draft
phase: N
owners: ["@your-github-handle"]
last-reviewed: YYYY-MM-DD
---

# Phase N — Test Plan

This document defines what "tested" means for Phase N. It enumerates every category of test, the coverage target, the owning component, and the CI gate (if any).

A phase does not exit until every category here has its target met; see [`exit.md`](exit.md).

---

## 1. Test taxonomy

| Category    | What it covers                                                           | Where it lives                                                                 | CI gate                 |
| ----------- | ------------------------------------------------------------------------ | ------------------------------------------------------------------------------ | ----------------------- |
| Unit        | Individual functions, modules.                                           | Adjacent to source.                                                            | Blocking.               |
| Integration | Component-level behavior across modules.                                 | `<component>/tests/integration/`.                                              | Blocking.               |
| Conformance | Wire-format spec compliance.                                             | [`../../../protocol/conformance/`](../../../protocol/conformance/).            | Blocking.               |
| Performance | SLO regression checks.                                                   | `<component>/tests/perf/`.                                                     | Blocking on regression. |
| Chaos       | Crash safety, partition tolerance, resource exhaustion.                  | `<component>/tests/chaos/`.                                                    | Phase exit.             |
| Security    | Negative-fixture / abuse-pattern coverage.                               | `<component>/tests/security/` and `protocol/conformance/fixtures/sandboxing/`. | Blocking.               |
| End-to-end  | Full-stack scenario tests representative of the ship-criterion scenario. | `tests/e2e/phase-N/`.                                                          | Phase exit.             |

---

## 2. Coverage targets

| Component | Unit  | Integration | Comments |
| --------- | ----- | ----------- | -------- |
| …         | ≥ 80% | ≥ 60%       | …        |

Coverage is measured per language tool (`cargo llvm-cov` for Rust, `go test -cover` for Go, `vitest --coverage` for TS). The target applies to lines and to branches.

---

## 3. Conformance fixtures

List the fixture additions this phase requires.

| Path                                                   | Type                | Purpose |
| ------------------------------------------------------ | ------------------- | ------- |
| `protocol/conformance/fixtures/<category>/<name>.json` | positive / negative | …       |

Fixture authoring rules: [`../../SPEC_STYLE.md`](../../SPEC_STYLE.md) §7.

---

## 4. Performance scenarios

Each scenario has a name, an SLO target (from [`perf-budget.md`](perf-budget.md)), and a measurement procedure.

| Scenario | SLO     | Measurement   |
| -------- | ------- | ------------- |
| …        | P95 ≤ … | Bench at `…`. |

CI fails if a scenario regresses by more than 5% relative to the rolling baseline.

---

## 5. Chaos catalog

Failure injections this phase MUST tolerate.

- …

For each: pre-condition, fault, expected behavior, recovery time bound.

---

## 6. Security tests

- Negative fixtures from [`../../THREAT_MODEL.md`](../../THREAT_MODEL.md) §5 (sandboxing) MUST pass.
- Fuzz testing of envelope parsing (where applicable).
- Dependency audit clean (`cargo audit`, `govulncheck`, `pnpm audit`).

---

## 7. End-to-end scenarios

The scenarios that operationalize the [`README.md`](README.md) §4 ship criterion.

- …

---

## 8. Test ownership

Each test category names an owner who is responsible for keeping it green.

| Category    | Owner                 |
| ----------- | --------------------- |
| Unit        | Per-component author. |
| Integration | …                     |
| Conformance | Spec maintainers.     |
| Performance | …                     |
| Chaos       | …                     |
| Security    | …                     |
| End-to-end  | Phase lead.           |

---

## 9. Gating

Tests gate the following events:

- **Per-PR.** Unit, integration, conformance, security, fast performance smoke. Blocking.
- **Pre-merge to main.** All of the above plus full performance regression. Blocking on regression.
- **Phase exit.** All categories including chaos and end-to-end. Phase exit checklist in [`exit.md`](exit.md).
