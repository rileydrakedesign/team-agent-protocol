---
status: draft
phase: 1
owners: ["@rileydrakedesign"]
last-reviewed: 2026-05-04
---

# Phase 1 — Protocol & Foundations

This document is the entry point for everything about Phase 1. The phase landed scaffolding on 2026-04-28 and the documentation foundation on 2026-04-29. Codegen pipeline went green end-to-end on 2026-05-04 — all three reference runners (Rust, Go, TypeScript) pass 46/46 fixtures, and the codegen step is idempotent. Phase 1 itself is **in progress**; remaining gates: doc lints in CI, resolution of the remaining open questions ([`open-questions.md`](open-questions.md)), and external-implementer ship-criterion validation ([`exit.md`](exit.md) §1).

---

## 1. Goal

A stable TAP v0.1 wire-format specification, the schemas and fixtures that make it executable, and the cross-cutting documentation foundation that every later phase depends on.

## 2. Scope

### 2.1 In scope

- TAP v0.1 wire-format specification: lifecycle, awareness, conflict (`protocol/SPEC.md` §1–8 and §13).
- CUE schemas for every message in §6–8: [`../../../protocol/schemas/`](../../../protocol/schemas/).
- Conformance fixtures for every CUE schema, positive and negative: [`../../../protocol/conformance/fixtures/`](../../../protocol/conformance/fixtures/).
- Conformance test runners in Rust, Go, TypeScript: `crates/tap-protocol/tests/conformance.rs`, `pkg/protocol/conformance_test.go`, `packages/tap-protocol/src/test/conformance.test.ts`.
- Codegen pipeline: [`../../../tools/codegen/`](../../../tools/codegen/) producing Rust / Go / TypeScript bindings from CUE.
- Three SDK packages (Rust, Go, TypeScript) shipping the generated bindings + hand-written envelope helpers.
- Threat model: [`../../THREAT_MODEL.md`](../../THREAT_MODEL.md).
- Documentation foundation: [`../../README.md`](../../README.md), [`../../GLOSSARY.md`](../../GLOSSARY.md), [`../../SPEC_STYLE.md`](../../SPEC_STYLE.md), [`../../VERSIONING.md`](../../VERSIONING.md), [`../../RFC_PROCESS.md`](../../RFC_PROCESS.md), [`../../CONFORMANCE.md`](../../CONFORMANCE.md), [`../../A2A_MAPPING.md`](../../A2A_MAPPING.md), [`../../ROADMAP.md`](../../ROADMAP.md), [`../../RISK_REGISTER.md`](../../RISK_REGISTER.md), [`../../DOCUMENTATION_PLAN.md`](../../DOCUMENTATION_PLAN.md).
- Templates for phase, component, runbook, RFC layers.
- Repo scaffolding: Bazel + bzlmod, CI (Bazel build/test/conformance + drift check + CodeQL + Scorecard), pre-commit, governance docs.
- Prompt-injection negative-fixture corpus per [`../../THREAT_MODEL.md`](../../THREAT_MODEL.md) §5.3 (initial set; expanded in Phase 4).

### 2.2 Out of scope

- The local daemon implementation. → Phase 2.
- Any editor adapter. → Phase 2 (Claude Code), Phase 5 (others).
- The hosted relay. → Phase 3.
- Messaging, consults, tasks, trust, policy wire format. → Phase 4 (`SPEC.md` §9–12 are placeholders in v0.1).
- Level 3 / Level 4 conflict detection. → Phase 5.
- Hermetic codegen toolchains. → tracked in [`../../../project-context.md` §9.6](../../../project-context.md#96-deferred-items); deferred to Phase 2.

## 3. Dependencies

### 3.1 Inputs from prior phases

None. Phase 1 is the first phase.

### 3.2 Outputs consumed by later phases

- Phase 2 daemon implements the wire-format surface specified here.
- Phase 2 Claude Code adapter consumes the lifecycle and awareness contracts.
- Phase 3 relay implements the relay-side semantics for every Phase 1 method.
- Every later phase extends the spec under the conventions in [`../../SPEC_STYLE.md`](../../SPEC_STYLE.md).

## 4. Ship criterion

> An external implementer can read the spec and produce a conformant client without consulting source code.

Operationalized in [`exit.md`](exit.md). Concretely: a third-party engineer, given only `protocol/SPEC.md`, `protocol/schemas/`, `protocol/conformance/`, [`../../GLOSSARY.md`](../../GLOSSARY.md), [`../../SPEC_STYLE.md`](../../SPEC_STYLE.md), [`../../VERSIONING.md`](../../VERSIONING.md), and [`../../CONFORMANCE.md`](../../CONFORMANCE.md), can:

1. Read the spec end-to-end without external clarification.
2. Produce an implementation that passes every conformance fixture.
3. Submit a conformance attestation per [`../../CONFORMANCE.md`](../../CONFORMANCE.md) §5.

## 5. Doc index for this phase

| Doc                                      | Purpose                                        |
| ---------------------------------------- | ---------------------------------------------- |
| [`README.md`](README.md)                 | This file.                                     |
| [`test-plan.md`](test-plan.md)           | Coverage and gating tests for Phase 1.         |
| [`perf-budget.md`](perf-budget.md)       | Phase 1 performance budgets.                   |
| [`threat-model.md`](threat-model.md)     | Phase 1 threat-model addendum.                 |
| [`migration.md`](migration.md)           | Migration / compatibility (N/A — first phase). |
| [`open-questions.md`](open-questions.md) | Phase 1 open questions.                        |
| [`decisions.md`](decisions.md)           | Phase 1 decision log.                          |
| [`exit.md`](exit.md)                     | Phase 1 exit checklist.                        |

## 6. RFCs

Phase 1 RFC range: `0001`–`0009`.

| Number | Title                       | Status                                                                                                                     |
| ------ | --------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `0001` | Codegen pipeline            | Draft (deferred — current `tools/codegen/generate.sh` plus `drift_check.sh` are functional; RFC formalizes and documents). |
| `0002` | Conformance runner contract | Draft (deferred — see [`../../CONFORMANCE.md`](../../CONFORMANCE.md) §4 for the binding contract).                         |

Out-of-order RFCs authored in Phase 1 for Phase 2's critical path:

| Number | Title            | Status              |
| ------ | ---------------- | ------------------- |
| `0015` | MCP tool surface | Draft (in progress) |

## 7. Component docs

Phase 1 introduces the three reference SDK packages but no operational components. Component docs for Phase 2's daemon are authored in Phase 2.

| Component                   | Path                                                                 | Status                                                                                                    |
| --------------------------- | -------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `tap-protocol` (Rust)       | [`../../../crates/tap-protocol/`](../../../crates/tap-protocol/)     | hand-written helpers + conformance runner green (46/46); generated types stubbed pending cargo-typify fix |
| `tap-protocol` (Go)         | [`../../../pkg/protocol/`](../../../pkg/protocol/)                   | hand-written helpers + generated `types.go` (518 lines) + conformance runner green (46/46)                |
| `tap-protocol` (TypeScript) | [`../../../packages/tap-protocol/`](../../../packages/tap-protocol/) | hand-written helpers + generated `all.ts` + conformance runner green (46/46)                              |

Each ships generated bindings + hand-written envelope helpers + a conformance test runner. SDK component docs (`docs/components/sdk/...`) are deferred until Phase 2 produces a stable API surface.

## 8. Working notes

The phase has two parallel tracks:

- **Spec track.** Wire-format prose, schemas, fixtures, codegen pipeline, and per-language conformance runners — all green as of 2026-05-04. Two follow-ups remain deferred (cargo-typify panic on certain `allOf+not` patterns, rules_rust crate-universe wiring) — both ergonomics, neither blocks conformance.
- **Foundation track.** Land the documentation system every later phase will follow. Substantially complete as of 2026-04-29.

Phase 2 work is unblocked once the spec track ships its lifecycle / awareness / conflict surface; Phase 2 RFCs are authored in parallel out of order (see §6). The full authorship order is in [`../../DOCUMENTATION_PLAN.md`](../../DOCUMENTATION_PLAN.md) §9.
