---
status: draft
phase: 1
owners: ["@rileydrakedesign"]
last-reviewed: 2026-05-04
---

# Phase 1 — Exit Checklist

Operationalizes the ship criterion from [`README.md`](README.md) §4 and [`../../../project-context.md` §8](../../../project-context.md#8-phased-development-plan). Phase 1 is not complete until every box is checked.

> _Restated ship criterion:_ an external implementer can read the spec and produce a conformant client without consulting source code.

---

## 1. Ship-criterion operationalization

| Clause                                                            | Operationalization                                                                                                                                                                                                               | Evidence                                                                                                           | Owner             | Done |
| ----------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ | ----------------- | ---- |
| External implementer can read the spec without consulting source. | Hand a clean checkout of `protocol/SPEC.md`, `protocol/schemas/`, `protocol/conformance/`, and the foundation docs to a third-party engineer with no TAP context. They report whether they could understand the spec end-to-end. | Implementer report committed to `docs/phases/phase-1/external-implementer-report-<handle>.md`.                     | @rileydrakedesign | ☐    |
| The implementer produces a conformant client.                     | The third-party implementation passes every fixture in `protocol/conformance/fixtures/`.                                                                                                                                         | Conformance attestation per [`../../CONFORMANCE.md`](../../CONFORMANCE.md) §5, linked from the implementer report. | @rileydrakedesign | ☐    |
| The implementer does so "without consulting source code."         | The implementer attests in their report that they did not read TAP daemon, relay, or SDK source while implementing.                                                                                                              | Statement in the implementer report.                                                                               | @rileydrakedesign | ☐    |

## 2. Doc-bundle completeness

- [x] [`README.md`](README.md)
- [x] [`test-plan.md`](test-plan.md)
- [x] [`perf-budget.md`](perf-budget.md)
- [x] [`threat-model.md`](threat-model.md)
- [x] [`migration.md`](migration.md) (N/A by reason)
- [x] [`open-questions.md`](open-questions.md) — open items resolved or explicitly deferred
- [x] [`decisions.md`](decisions.md) — current
- [x] [`exit.md`](exit.md) — this file

## 3. Foundation docs

All foundation docs are `accepted`:

- [x] [`../../README.md`](../../README.md)
- [x] [`../../GLOSSARY.md`](../../GLOSSARY.md)
- [x] [`../../SPEC_STYLE.md`](../../SPEC_STYLE.md)
- [x] [`../../VERSIONING.md`](../../VERSIONING.md)
- [x] [`../../RFC_PROCESS.md`](../../RFC_PROCESS.md)
- [x] [`../../CONFORMANCE.md`](../../CONFORMANCE.md)
- [x] [`../../A2A_MAPPING.md`](../../A2A_MAPPING.md) (draft acceptable until `[verify]` items resolve before exit)
- [x] [`../../ROADMAP.md`](../../ROADMAP.md)
- [x] [`../../RISK_REGISTER.md`](../../RISK_REGISTER.md)
- [x] [`../../THREAT_MODEL.md`](../../THREAT_MODEL.md)
- [x] [`../../DOCUMENTATION_PLAN.md`](../../DOCUMENTATION_PLAN.md)

## 4. RFCs

Phase 1 RFCs (range `0001`–`0009`):

- [ ] `rfcs/0001-codegen-pipeline.md` — accepted.
- [ ] `rfcs/0002-conformance-runner-contract.md` — accepted.

Phase 2 RFCs authored out of order in Phase 1 (informational, not gating):

- [ ] `rfcs/0015-mcp-tool-surface.md` — draft acceptable for Phase 1 exit.

## 5. Wire-format spec

- [x] `protocol/SPEC.md` §1–8 fully populated; §9–12 placeholders explicitly marked Phase 4.
- [x] CUE schemas in `protocol/schemas/` exist for every method in §6–8.
- [ ] Conformance fixtures cover every CUE definition with at least one positive and one negative case (per [`test-plan.md`](test-plan.md) §3) — 5 response-type definitions still missing negatives (deferred follow-up).
- [x] Sandboxing fixture corpus present (per [`test-plan.md`](test-plan.md) §4).
- [x] All three reference bindings regenerate without drift (`bazel run //tools/codegen:generate` is idempotent).
- [x] Conformance suite passes in all three reference bindings — Rust 46/46, Go 46/46, TypeScript 46/46.
- [x] `protocol/conformance/VERSION` exists.
- [x] `protocol/SPEC.md` Appendix A change log up to date.

## 6. Tests

- [ ] Schema validation green (`cue vet` step in CI).
- [ ] Unit tests green in all three SDKs at the §2 coverage targets.
- [ ] Conformance suite green in all three runners.
- [ ] Drift check green.
- [ ] Sandboxing fixtures green.
- [ ] CodeQL clean.
- [ ] OpenSSF Scorecard ≥ 7.0.

## 7. Operations

- [ ] Branch protection on `main` configured (signed commits, two-reviewer for `protocol/` and `tools/codegen/`, required CI checks). Tracked in [`../../../project-context.md` §9.6](../../../project-context.md#96-deferred-items).
- [x] CI doc dashboard publishes (per [`../../DOCUMENTATION_PLAN.md`](../../DOCUMENTATION_PLAN.md) §10.4) — `tools/doclint/doclint.py --dashboard` runs in the `doc-lints` CI job and uploads `doc-dashboard.md` as a build artifact.

## 8. Security

- [x] Threat-model addendum [`threat-model.md`](threat-model.md) merged.
- [ ] [`../../THREAT_MODEL.md`](../../THREAT_MODEL.md) §8 (Open issues) reflects Phase 1 closures and remaining items.
- [ ] Sandboxing-fixture corpus exercising every documented prompt-injection pattern from [`../../THREAT_MODEL.md`](../../THREAT_MODEL.md) §5.3.
- N/A — pen-test required only at Phase 4 exit.

## 9. Documentation freshness

- [ ] No doc in this phase has `last-reviewed` older than 90 days as of the exit date.
- [ ] [`../../README.md`](../../README.md) doc index updated.
- [ ] [`../../../project-context.md` §9](../../../project-context.md#9-working-state) reflects Phase 1 completion and Phase 2's starting state.

## 10. Sign-off

| Role              | Name              | Date       |
| ----------------- | ----------------- | ---------- |
| Phase lead        | @rileydrakedesign | YYYY-MM-DD |
| Spec maintainer   | @rileydrakedesign | YYYY-MM-DD |
| Security reviewer | TBD               | YYYY-MM-DD |

(Operator and dashboard sign-off rows added in Phase 3.)
