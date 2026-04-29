---
status: draft
phase: 1
owners: [@rileydrakedesign]
last-reviewed: 2026-04-29
---

# Phase 1 — Open Questions

Phase 1 open questions. Append-only. When a question is resolved, mark it `resolved` and link to the decision in [`decisions.md`](decisions.md) or to a merged RFC; do not delete.

Cross-phase open questions live in [`../../../project-context.md` §9.4](../../../project-context.md#94-open-questions) and in [`../../RISK_REGISTER.md`](../../RISK_REGISTER.md).

---

## Open

### Q-1-001 — Round-trip canonicalization rule

**Status:** open
**Raised:** 2026-04-29 by @rileydrakedesign

**Question.** [`../../CONFORMANCE.md`](../../CONFORMANCE.md) §4.1 mentions canonicalization for `expected_round_trip: true` fixtures. The exact canonicalization (key order? whitespace? Unicode normalization?) is unspecified. What rule do we adopt?

**Why it matters.** Without a canonicalization rule, round-trip fixtures can pass in one runner and fail in another for trivially equivalent JSON.

**Discussion.** Options:
- JCS (RFC 8785, JSON Canonicalization Scheme) — formal, widely supported, slightly opinionated about numbers.
- Sorted-keys + UTF-8 + no insignificant whitespace — simple, less formal.
- Defer to each runner using a stable serializer (status quo) — works in practice; risky as runners diverge.

Lean toward JCS for its formal grounding, accepting the small import-cost in each language.

**Resolution.** TBD — decide before Phase 1 exit. Tracked as a Phase 1 follow-up RFC in the `0001`–`0009` range.

### Q-1-002 — Conformance suite version file

**Status:** open
**Raised:** 2026-04-29 by @rileydrakedesign

**Question.** [`../../VERSIONING.md`](../../VERSIONING.md) §5 specifies that `protocol/conformance/VERSION` carries the suite version. The file does not yet exist. When does it land, and what is its content format?

**Why it matters.** Conformance attestations cite the suite version per [`../../CONFORMANCE.md`](../../CONFORMANCE.md) §5; without the file, attestations have nothing concrete to cite.

**Resolution.** TBD — land before Phase 1 exit. Plain text, single line: `0.1.0` (or current version).

### Q-1-003 — Hermetic codegen toolchain

**Status:** deferred to Phase 2
**Raised:** 2026-04-29 by @rileydrakedesign
**Deferred to:** Phase 2

**Question.** Should `cue`, `typify`, `json2ts` be promoted from ambient host dependencies to hermetic Bazel toolchains within Phase 1, or deferred to Phase 2?

**Why it matters.** Risk TR-001. Drift between contributor toolchains can produce different generated bindings.

**Resolution.** Deferred per [`../../../project-context.md` §9.4](../../../project-context.md#94-open-questions). Phase 2 promotes the toolchains.

### Q-1-004 — `tap.dev` provisioning before Phase 1 exit

**Status:** open
**Raised:** 2026-04-29 by @rileydrakedesign

**Question.** Phase 1's ship criterion involves an external implementer producing a conformant client. Does the external implementer need a domain-resolved spec URL (`tap.dev/spec/v0.1/`) to do so, or is the GitHub-hosted markdown sufficient?

**Why it matters.** If a domain is required, [`../../../project-context.md` §9.6](../../../project-context.md#96-deferred-items) deferred-domain-acquisition becomes a Phase 1 blocker.

**Discussion.** GitHub-hosted markdown is sufficient for a competent implementer; the spec is plain text. Domain acquisition is a positioning concern but not a technical one. Lean toward "no" — `tap.dev` is a Phase 5 (public conformance program) concern.

**Resolution.** TBD — confirm before Phase 1 exit.

### Q-1-005 — A2A conformance verification cadence

**Status:** open
**Raised:** 2026-04-29 by @rileydrakedesign

**Question.** [`../../A2A_MAPPING.md`](../../A2A_MAPPING.md) carries `[verify]` markers on items needing confirmation against the live A2A spec. When are those verified?

**Why it matters.** Phase 1 ship criterion is "external implementer produces a conformant client." If TAP's A2A claim is overstated, the claim is itself non-conformant.

**Discussion.** Doing the verification now blocks Phase 1 until A2A's spec stabilizes; doing it later risks shipping a misleading mapping. A reasonable middle path: verify what's verifiable now, leave `[verify]` on items that depend on A2A spec sections still in flux, and re-check before Phase 1 exit.

**Resolution.** TBD — verify in a follow-up PR before Phase 1 exit; risk TR-004 in [`../../RISK_REGISTER.md`](../../RISK_REGISTER.md) tracks ongoing drift.

## Resolved

(none yet)

## Deferred

### Q-1-003 — Hermetic codegen toolchain (deferred to Phase 2)

(see Open above for full text — kept here only as a navigation anchor)
