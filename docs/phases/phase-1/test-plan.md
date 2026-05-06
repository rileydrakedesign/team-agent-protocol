---
status: draft
phase: 1
owners: ["@rileydrakedesign"]
last-reviewed: 2026-04-29
---

# Phase 1 — Test Plan

Phase 1 is a specification phase. It ships no daemon, no relay, no adapter — only a wire-format spec, the schemas that back it, the fixtures that exercise it, and the SDK bindings + helpers that prove it codegens cleanly. The test plan is correspondingly narrow but strict.

---

## 1. Test taxonomy

| Category            | What it covers                                                                                                          | Where it lives                                                                                              | CI gate   |
| ------------------- | ----------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- | --------- |
| Schema validation   | Every CUE schema validates and parses.                                                                                  | [`../../../protocol/schemas/`](../../../protocol/schemas/), `cue vet` step in CI.                           | Blocking. |
| Unit                | Hand-written envelope helpers (semver parse, version negotiation, trace_id handling).                                   | `crates/tap-protocol/src/`, `pkg/protocol/`, `packages/tap-protocol/src/`.                                  | Blocking. |
| Conformance         | Every CUE definition has at least one positive and one negative fixture; all three reference runners execute the suite. | [`../../../protocol/conformance/fixtures/`](../../../protocol/conformance/fixtures/), per-language runners. | Blocking. |
| Drift               | Generated bindings match the committed copy.                                                                            | [`../../../tools/codegen/drift_check.sh`](../../../tools/codegen/drift_check.sh), CI.                       | Blocking. |
| Sandboxing fixtures | Negative fixtures for documented prompt-injection patterns.                                                             | [`../../../protocol/conformance/fixtures/sandboxing/`](../../../protocol/conformance/fixtures/sandboxing/). | Blocking. |
| Documentation       | Markdown lints; broken-link check; front-matter schema check.                                                           | `tools/doclint/` (deferred from Phase 1; advisory until landed).                                            | Advisory. |

There are no performance tests, chaos tests, integration tests, or end-to-end tests in Phase 1. Those land in Phase 2 onwards as soon as there is something running to test.

## 2. Coverage targets

| Component               | Unit  | Notes                                      |
| ----------------------- | ----- | ------------------------------------------ |
| `crates/tap-protocol`   | ≥ 90% | Small surface; no excuse for low coverage. |
| `pkg/protocol`          | ≥ 90% | Same.                                      |
| `packages/tap-protocol` | ≥ 90% | Same.                                      |

Coverage measured per language (`cargo llvm-cov`, `go test -cover`, `vitest --coverage`). Lines and branches both apply.

## 3. Conformance fixtures

The Phase 1 fixture set covers every CUE definition introduced in `protocol/schemas/`. As each method's schema is committed, fixtures land alongside it in the same PR per [`../../SPEC_STYLE.md`](../../SPEC_STYLE.md) §7.

Required fixture coverage at phase exit:

| Schema                                    | Positive     | Negative | Notes                                                |
| ----------------------------------------- | ------------ | -------- | ---------------------------------------------------- |
| `envelope.cue#Envelope`                   | ≥ 1          | ≥ 2      | wrong jsonrpc, malformed trace_id, others as needed. |
| `agent_register.cue#AgentRegisterRequest` | ≥ 1          | ≥ 2      |                                                      |
| `agent_register.cue#AgentRegisterResult`  | ≥ 1          | ≥ 1      |                                                      |
| `agent_heartbeat.cue`                     | ≥ 1          | ≥ 1      |                                                      |
| `agent_deregister.cue`                    | ≥ 1          | ≥ 1      |                                                      |
| `agent_disconnect.cue`                    | ≥ 1          | ≥ 1      |                                                      |
| `state_announce.cue`                      | ≥ 1          | ≥ 1      |                                                      |
| `state_query.cue`                         | ≥ 1 + result | ≥ 1      |                                                      |
| `state_subscribe.cue`                     | ≥ 1 + result | ≥ 1      |                                                      |
| `state_diff.cue`                          | ≥ 1          | ≥ 1      |                                                      |
| `conflict_check.cue`                      | ≥ 1 + result | ≥ 1      |                                                      |
| `conflict_declare.cue`                    | ≥ 1 + result | ≥ 1      |                                                      |
| `conflict_release.cue`                    | ≥ 1          | ≥ 1      |                                                      |
| `conflict_notify.cue`                     | ≥ 1          | ≥ 1      |                                                      |

## 4. Sandboxing corpus

Per [`../../THREAT_MODEL.md`](../../THREAT_MODEL.md) §5.3 the conformance suite includes negative fixtures for prompt-injection patterns. Initial set (expanded in Phase 4 when messaging/consult schemas land):

| Pattern                                                    | Fixture                                     | Phase 1 status    |
| ---------------------------------------------------------- | ------------------------------------------- | ----------------- |
| Literal "ignore prior instructions" in inbound text fields | `sandboxing/inbound_ignore_prior.json`      | Required at exit. |
| Role-play prompts                                          | `sandboxing/inbound_roleplay.json`          | Required at exit. |
| Fake tool-result framing                                   | `sandboxing/inbound_fake_tool_result.json`  | Required at exit. |
| Smuggled markdown control chars                            | `sandboxing/inbound_smuggled_markdown.json` | Required at exit. |
| Smuggled control tokens                                    | `sandboxing/inbound_smuggled_control.json`  | Required at exit. |

These fixtures target message schemas that exist in v0.1 (e.g., `agent.register.params.capabilities[]`, `state.announce.intent`, `conflict.notify.message`) — any free-text field that could be used to attempt injection.

## 5. Drift check

CI runs `bazel run //tools/codegen:generate && git diff --exit-code` on every PR. Failure means the committed bindings drifted from regeneration. Resolution: run codegen locally, commit the diff.

This gate also fails if the codegen tooling itself produces non-deterministic output. Such cases are tracked as bugs against the corresponding tool.

## 6. Conformance runner per-language

Each runner MUST:

1. Discover every fixture under `protocol/conformance/fixtures/`.
2. For each, validate `data` against the named `schema_ref`.
3. Compare the validation outcome to `expected_valid`.
4. Where `expected_round_trip` is `true`, deserialize → re-serialize and confirm canonical equivalence (the canonicalization rule is itself a Phase 1 follow-up; until specified, runners use a stable JSON serializer and compare normalized output).
5. Where `expected_error_code` is set, check that the produced error code matches.
6. Emit the JSON output schema in [`../../CONFORMANCE.md`](../../CONFORMANCE.md) §4.1.
7. Exit `0` on full pass, `1` on any failure, `2` on runner error.

## 7. Test ownership

| Category            | Owner                                  |
| ------------------- | -------------------------------------- |
| Schema validation   | Spec maintainers.                      |
| Unit                | Per-package author.                    |
| Conformance         | Spec maintainers.                      |
| Drift               | Codegen owner.                         |
| Sandboxing fixtures | Spec maintainers + threat-model owner. |
| Documentation lints | Documentation owner (TBD).             |

## 8. Gating

- **Per-PR.** Schema validation, unit, conformance (in all three reference bindings), drift, sandboxing — all blocking.
- **Pre-merge to `main`.** All of the above plus CodeQL and OpenSSF Scorecard.
- **Phase exit.** All categories above plus the ship-criterion check from [`exit.md`](exit.md).
