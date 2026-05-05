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

**Status:** resolved
**Raised:** 2026-04-29 by @rileydrakedesign
**Resolved:** 2026-04-29 (see [`decisions.md`](decisions.md))

**Question.** [`../../VERSIONING.md`](../../VERSIONING.md) §5 specifies that `protocol/conformance/VERSION` carries the suite version. The file does not yet exist. When does it land, and what is its content format?

**Why it matters.** Conformance attestations cite the suite version per [`../../CONFORMANCE.md`](../../CONFORMANCE.md) §5; without the file, attestations have nothing concrete to cite.

**Resolution.** Landed as part of the codegen-pipeline pre-flight batch on 2026-04-29. Format is plain text, single line, trailing newline. Initial content: `0.1.0`. Conformance runners read it from `protocol/conformance/VERSION` and surface it as `suite_version` in the [`../../CONFORMANCE.md`](../../CONFORMANCE.md) §4.1 JSON output.

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

### Q-1-006 — Token budget for TAP-derived agent context

**Status:** resolved
**Raised:** 2026-04-29 by @rileydrakedesign
**Resolved:** 2026-04-29 by @rileydrakedesign (via RFC 0015 §3.10 amendment)

**Question.** RFC 0015 v1.0 as initially written would inject ~100k+ tokens of TAP-derived content over a 30-turn session on a 20-developer team (4-6k tokens of awareness state per start-of-turn pull × 30 turns). On Sonnet's 200k-token context window this is a non-starter; even on Opus's 1M window it is wasteful. How is the token cost bounded?

**Why it matters.** TAP's whole value proposition collapses if running it makes every agent session noticeably slower or more expensive. A "team coordination layer" that doubles the input-token bill per turn is dead on arrival.

**Discussion.** Cost audit per surface:
- Auto-injected `tap_state_query` at start of each turn (full team blob): ~135k tokens / session.
- `PreToolUse` no-conflict reply (60 tokens × 50 writes): ~3,000 tokens / session.
- Conflict-case reply (rare): ~1,200 tokens / session.
- Consult bundle inlined (if eager-fetched): 5,000–50,000 tokens per consult — catastrophic.

Three optimization principles drive the resolution: pull-not-push (don't auto-inject what can be queried), synthesize-not-serialize (daemon-rendered prose 5-10× cheaper than structured JSON), scope-tightly (filter to relevant slice before surfacing).

**Resolution.** RFC 0015 amended with binding token-aware conventions:
- §3.10 (new): nine binding rules — pull-not-push default, ≤ 30-token session-start banner, `format` parameter on every state tool with `summary` default, minimal `{ ok: true }` payload on no-conflict `tap_conflict_check`, digest mode by default for pending queues, narrow subscription scope at register time, compactable: true on informational results, recommended ≤ 5,000-token per-session budget, Phase 2 conformance test of ≤ 100 tokens/turn TAP-derived content in steady state.
- §4.2/§4.3/§5.2/§5.4 propagate `format` parameter.
- §4.4 minimal-payload no-conflict form.
- §4.7 `tap_conflicts_pending` digest mode + `tap_conflicts_pending_expand` companion.
- §6.1 lazy-bundle convention binding for Phase 4 consult/message tools: bundles travel by handle with daemon-synthesized summary, fetched lazily via `tap_consult_bundle_get` and `tap_consult_bundle_manifest`.

After amendments, fixed overhead drops to ~2,000 tokens per session; variable cost scales with the agent's *actual cross-developer activity*, not with team size or activity level. A 30-turn session with no cross-developer activity uses ~250 tokens of TAP-derived content; a 30-turn session with one mid-session consult and three lazily fetched files uses ~5,000.

## Resolved

### Q-1-002 — Conformance suite version file (resolved 2026-04-29)

(see Open above for full text — kept here only as a navigation anchor)

### Q-1-006 — Token budget for TAP-derived agent context (resolved 2026-04-29)

(see Open above for full text — kept here only as a navigation anchor)

## Deferred

### Q-1-003 — Hermetic codegen toolchain (deferred to Phase 2)

(see Open above for full text — kept here only as a navigation anchor)
