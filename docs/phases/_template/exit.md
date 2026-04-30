---
status: draft
phase: N
owners: [@your-github-handle]
last-reviewed: YYYY-MM-DD
---

# Phase N — Exit Checklist

Operationalizes the ship criterion from [`README.md`](README.md) §4 and [`../../../project-context.md` §8](../../../project-context.md#8-phased-development-plan). A phase is not complete until every box is checked, the evidence is linked, and the responsible owner has signed off.

This is a working document; check items off as they land.

---

## 1. Ship criterion

Restate verbatim from [`README.md`](README.md) §4. Operationalize each clause.

| Clause | Operationalization | Evidence | Owner | Done |
|---|---|---|---|---|
| … | Concrete, testable rendering. | Link to test, scenario, attestation. | @handle | ☐ |

---

## 2. Doc-bundle completeness

Every doc in the spine for this phase MUST be present and `accepted` (RFCs may be `implemented`).

- [ ] [`README.md`](README.md)
- [ ] [`test-plan.md`](test-plan.md)
- [ ] [`perf-budget.md`](perf-budget.md)
- [ ] [`threat-model.md`](threat-model.md)
- [ ] [`migration.md`](migration.md)
- [ ] [`open-questions.md`](open-questions.md) — open items resolved or explicitly deferred
- [ ] [`decisions.md`](decisions.md) — current
- [ ] [`exit.md`](exit.md) — this file

## 3. RFCs

All RFCs allocated to this phase are `accepted` or `implemented`.

| RFC | Status |
|---|---|
| … | … |

## 4. Component docs

Every component touched by this phase has a complete `docs/components/<component>/` bundle.

| Component | Docs complete |
|---|---|
| … | ☐ |

## 5. Wire-format spec

If the phase touches the wire format:

- [ ] `protocol/SPEC.md` sections updated.
- [ ] `protocol/schemas/` files in place.
- [ ] `protocol/conformance/fixtures/` cover every new schema with at least one positive and one negative case.
- [ ] All three reference bindings (Rust, Go, TypeScript) regenerate without drift.
- [ ] Conformance suite passes in all three reference bindings.

## 6. Tests

- [ ] Unit, integration, conformance: green.
- [ ] Performance: meets [`perf-budget.md`](perf-budget.md).
- [ ] Chaos: catalog from [`test-plan.md`](test-plan.md) executed.
- [ ] Security: negative fixtures pass; dependency audit clean.
- [ ] End-to-end: ship-criterion scenarios pass.

## 7. Operations

- [ ] Runbooks under `docs/runbooks/` updated for any new operational surface.
- [ ] SLO instrumentation deployed.
- [ ] Alerts wired and tested.
- [ ] On-call rotation covers any new component (Phase 3+).

## 8. Security

- [ ] Threat-model addendum [`threat-model.md`](threat-model.md) reviewed and merged.
- [ ] [`../../THREAT_MODEL.md`](../../THREAT_MODEL.md) §8 (Open issues) reflects what is closed, what remains.
- [ ] Pen-test report (if required for this phase) has no critical findings.

## 9. Documentation freshness

- [ ] No doc in this phase has `last-reviewed` older than 90 days as of the exit date.
- [ ] [`../../README.md`](../../README.md) doc index updated to reflect this phase's docs.
- [ ] [`../../../project-context.md` §9](../../../project-context.md#9-working-state) reflects phase completion and the next phase's starting state.

## 10. Sign-off

| Role | Name | Date |
|---|---|---|
| Phase lead | @handle | YYYY-MM-DD |
| Security reviewer | @handle | YYYY-MM-DD |
| Spec maintainer | @handle | YYYY-MM-DD |
| Operator (Phase 3+) | @handle | YYYY-MM-DD |
