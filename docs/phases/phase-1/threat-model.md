---
status: draft
phase: 1
owners: [@rileydrakedesign]
last-reviewed: 2026-04-29
---

# Phase 1 — Threat Model Addendum

Phase 1 introduces the wire-format specification and the codegen / conformance pipeline. The runtime attack surface is empty (no daemon, no relay, no adapter). The supply-chain and documentation attack surfaces, however, become operative in Phase 1 and must be modeled.

The project-wide threat model is at [`../../THREAT_MODEL.md`](../../THREAT_MODEL.md). This document is the Phase 1 delta.

---

## 1. New assets

| Asset | Why it matters |
|---|---|
| The wire-format specification (`protocol/SPEC.md`, `protocol/schemas/`). | Implementers depend on this as ground truth. A tampered or ambiguous spec causes silent divergence. |
| The conformance suite. | A conformant claim is meaningful only if the suite is itself trustworthy. |
| Generated bindings (committed in repo + published to crates.io / npm / pkg.go.dev once Phase 1 ships). | Consumed by every TAP implementation. Subverted bindings would propagate broadly. |
| Codegen toolchain (`cue`, `typify`, `json2ts`). | Compile-time supply-chain entry point. |

## 2. New trust boundaries

| Boundary | Other side | Auth | Integrity |
|---|---|---|---|
| Maintainer ↔ `main` branch | GitHub | Maintainer credential. | Branch protection (deferred per [`../../../project-context.md` §9.6](../../../project-context.md#96-deferred-items)). Signed commits required. |
| Codegen tool ↔ committed bindings | Local developer / CI runner | None at file-system layer. | Drift check on every PR; pinned tool versions. |
| Spec author ↔ implementer | Out-of-band | None. | Spec is plaintext + schemas + fixtures; review via PR. |

No daemon, relay, or adapter trust boundaries operate in Phase 1.

## 3. New adversaries

The project-wide adversary list applies. Phase 1-specific:

| Adversary | Capability | Motivation |
|---|---|---|
| Compromised codegen tool author / maintainer | Ships a malicious release of `typify`, `json2ts`, or `cue`. | Inject backdoors into bindings. |
| Compromised maintainer account | Merges malicious changes to `protocol/` or `tools/codegen/`. | Subvert spec or codegen output. |
| Spec ambiguity adversary | Submits PRs that render the spec ambiguous in implementer-favorable ways. | Cause silent divergence between implementations to enable later attacks. |

## 4. STRIDE delta

### 4.1 Spoofing

| Threat | Control |
|---|---|
| Forged commit on `main`. | Branch protection requires signed commits ([`../../../project-context.md` §9.6](../../../project-context.md#96-deferred-items)). |
| Spoofed conformance attestation. | [`../../CONFORMANCE.md`](../../CONFORMANCE.md) §5 attestation references the source revision; §8 dispute process exists. |

### 4.2 Tampering

| Threat | Control |
|---|---|
| Modified codegen tool injects code into generated bindings. | Pinned tool versions. CI drift check. Phase 2 hermetic toolchains (deferred). |
| Modified release artifacts. | Reproducible builds; signed binaries (Phase 2 deliverable; not yet active). Transparency log for releases (Phase 2). |
| Conformance fixture deliberately weakened. | PR review; fixtures are plain JSON and inspected per [`../../SPEC_STYLE.md`](../../SPEC_STYLE.md) §7. |

### 4.3 Repudiation

| Threat | Control |
|---|---|
| Maintainer denies a destructive merge. | Git history with signed commits. |

### 4.4 Information disclosure

No new information-disclosure threats in Phase 1; the spec and schemas are public artifacts by design.

### 4.5 Denial of service

| Threat | Control |
|---|---|
| Schema-validation amplification through pathological inputs. | Strict CUE validation; oversize inputs rejected before parse. Phase 1 conformance fixtures include known-pathological negatives. |

### 4.6 Elevation of privilege

| Threat | Control |
|---|---|
| Cross-developer prompt injection through fields specified in v0.1 (e.g., `state.announce.intent`, `agent.register.params.capabilities[]`). | The structured-envelope sandboxing rule per [`../../THREAT_MODEL.md`](../../THREAT_MODEL.md) §5 is mandatory at any consumer of these fields. Phase 1 conformance suite includes the initial sandboxing-fixture corpus per [`test-plan.md`](test-plan.md) §4. |

## 5. Resolved threats

None — no project-wide open threats are closed in Phase 1.

## 6. Required tests

- Conformance fixtures for every schema (positive + negative).
- Sandboxing-fixture corpus per [`test-plan.md`](test-plan.md) §4.
- Drift check.

## 7. Open issues

Promoted to [`../../THREAT_MODEL.md`](../../THREAT_MODEL.md) §8 at phase exit:

- The canonicalization rule for round-trip fixtures is unspecified. Until set, ambiguity in serializer behavior could mask round-trip failures. → Phase 1 follow-up.
- Hermetic codegen toolchains. → Phase 2 deliverable.

## 8. Pen-test scope

N/A — Phase 4 is the first phase that triggers an external pen-test per [`../../../project-context.md` §8](../../../project-context.md#8-phased-development-plan).

## 9. References

- [`../../THREAT_MODEL.md`](../../THREAT_MODEL.md)
- [`../../RISK_REGISTER.md`](../../RISK_REGISTER.md) — risks SR-001 (cross-dev prompt injection), SR-003 (compromised codegen), SR-004 (compromised maintainer) are sourced from this phase's threat surface.
- [`../../CONFORMANCE.md`](../../CONFORMANCE.md) §8 — dispute process for false conformance claims.
