---
status: accepted
phase: continuing
owners: [@rileydrakedesign]
last-reviewed: 2026-04-29
---

# TAP Risk Register

Cross-phase risk log. Risks that are scoped to a single phase live in that phase's `phases/phase-N/threat-model.md` and `phases/phase-N/open-questions.md`. This register is for risks whose horizon is the whole project.

Each risk has:

- **ID** — stable, never reused. Format: `<CATEGORY>-<NUMBER>`. Categories: `TR` (technical), `SR` (security), `MR` (market), `OR` (organizational), `LR` (legal), `CR` (compliance).
- **Description.**
- **Severity** — Low / Medium / High / Critical. Defined in §1.
- **Likelihood** — Low / Medium / High.
- **Owner.**
- **Mitigation** — what we plan to do about it.
- **Status** — Open / Mitigating / Accepted / Resolved.
- **Last reviewed** — YYYY-MM-DD.

When a risk is resolved, it stays in the register with `status: resolved` for history. Never delete.

---

## 1. Severity scale

| Severity | Definition |
|---|---|
| Critical | Materializing the risk would cause project failure, prolonged outage, or loss of user trust at scale. |
| High | Materializing the risk would cause a missed phase, a public security incident, or significant reputational harm. |
| Medium | Materializing the risk would cause measurable delay, partial loss of users, or remediable harm. |
| Low | Materializing the risk would be inconvenient but easily remediated. |

---

## 2. Active risks

### 2.1 Technical

| ID | Description | Severity | Likelihood | Owner | Mitigation | Status | Last reviewed |
|---|---|---|---|---|---|---|---|
| TR-001 | **Codegen toolchain non-hermeticity.** Phase 1 keeps `cue`, `typify`, `json2ts` as ambient host deps. Drift between contributor toolchains can produce different generated bindings. | Medium | Medium | @rileydrakedesign | Move codegen to hermetic Bazel toolchains by mid-Phase 2. Tracked in [`../project-context.md` §9.6](../project-context.md#96-deferred-items). | Mitigating | 2026-04-29 |
| TR-002 | **Sub-50 ms PreToolUse SLO on Windows.** The local-cache conflict-check budget assumes named-pipe IPC and FS-watcher behavior comparable to Linux/macOS. Windows performance is unverified. | Medium | Medium | TBD (Phase 2) | Add a Windows perf bench to the Phase 2 test plan. Re-evaluate the SLO if the bench shows the budget is not achievable. | Open | 2026-04-29 |
| TR-003 | **Tree-sitter query coverage for symbol graph.** Level 3 detection assumes high-quality queries for five languages at Phase 5 launch. Query quality in long-tail languages (especially Java, Python typing) may not meet the precision/recall ship criterion. | High | Medium | TBD (Phase 5) | Build the benchmark corpus before query work begins, so coverage is measurable from day one. Phase 5 ship criterion already gates on it. | Open | 2026-04-29 |
| TR-004 | **A2A drift.** TAP claims conformance with Google A2A. A2A is an external standard not under TAP's control; breaking changes in A2A force TAP changes. | Medium | Medium | @rileydrakedesign | [`A2A_MAPPING.md`](A2A_MAPPING.md) is re-checked on every A2A spec release and before any TAP MAJOR bump. | Mitigating | 2026-04-29 |
| TR-005 | **MCP evolution.** TAP's adapter surface depends on each editor's MCP implementation. MCP is young and may evolve. | Medium | Medium | TBD (Phase 2 / Phase 5) | Adapters are thin and editor-specific; per-editor breakage does not propagate to the protocol. The adapter `INTERFACES.md` documents assumed MCP behaviors. | Open | 2026-04-29 |
| TR-006 | **Bus factor.** Single primary maintainer at project genesis. Loss of the maintainer in early phases is non-recoverable without effort. | High | Low | @rileydrakedesign | Document everything in `docs/` (this whole effort). Recruit a second primary maintainer before Phase 3 ships. Tracked in [`GOVERNANCE.md`](GOVERNANCE.md). | Mitigating | 2026-04-29 |

### 2.2 Security

| ID | Description | Severity | Likelihood | Owner | Mitigation | Status | Last reviewed |
|---|---|---|---|---|---|---|---|
| SR-001 | **Cross-developer prompt injection.** A compromised or malicious peer agent could steer a recipient agent via crafted message content. | Critical | Medium | @rileydrakedesign | The structured-envelope sandboxing rule per [`THREAT_MODEL.md`](THREAT_MODEL.md) §5. Mandatory negative-fixture corpus in the conformance suite (open Phase 1 deliverable). External pentest before Phase 4 ships. | Mitigating | 2026-04-29 |
| SR-002 | **Audit log tampering.** Without anchor commits at a defined cadence, an attacker with relay storage access could rewrite the chain. | High | Low | TBD (Phase 4) | Phase 4 RFC `rfcs/0208-audit-log.md` specifies anchor cadence and verification. Until then, treat audit log as integrity-protected only at relay-process boundary. | Open | 2026-04-29 |
| SR-003 | **Compromised codegen tool.** A malicious version of `typify`, `json2ts`, or `cue` would inject backdoors into generated bindings, which are committed and shipped in SDK packages. | High | Low | @rileydrakedesign | Pinned tool versions in `MODULE.bazel`. Hermetic toolchains are mitigation TR-001. CI drift check ensures tampering with the generated output is detected on every PR. | Mitigating | 2026-04-29 |
| SR-004 | **Compromised maintainer account.** A maintainer account takeover could merge unsafe changes to `protocol/` or `tools/codegen/`. | High | Low | @rileydrakedesign | Branch protection on `main` requiring signed commits, two-reviewer approval for protected paths. Tracked in [`../project-context.md` §9.6](../project-context.md#96-deferred-items). | Open | 2026-04-29 |
| SR-005 | **Supply-chain compromise (Dependabot bumps).** Automated dependency bumps could introduce malicious code if upstream is compromised. | Medium | Low | @rileydrakedesign | OpenSSF Scorecard report on every push. Dependabot security alerts blocking on CI. Manual review before merging anything that touches `tools/codegen/` or `protocol/`. | Mitigating | 2026-04-29 |
| SR-006 | **Direct agent-to-agent connection added by a community adapter.** TAP's threat model assumes all cross-developer traffic flows through the relay; an adapter that bypasses the relay would defeat audit, policy, and sandboxing. | High | Low | TBD (Phase 5) | Conformance suite enforces relay-routed communication. Trademark policy forbids "TAP-conformant" claims for adapters that bypass the relay. | Open | 2026-04-29 |

### 2.3 Market

| ID | Description | Severity | Likelihood | Owner | Mitigation | Status | Last reviewed |
|---|---|---|---|---|---|---|---|
| MR-001 | **Editor adapter pace.** Editors (Cursor, Codex, Aider) iterate quickly; their MCP/hook surfaces shift; our adapters lag. | Medium | High | TBD (Phase 5) | Adapters are thin, editor-specific, kept out of the protocol. A generic MCP adapter at Phase 5 reduces pressure on per-editor adapters. | Mitigating | 2026-04-29 |
| MR-002 | **A first-party "team agents" feature from Anthropic / Microsoft / Google.** A vendor could add cross-developer agent coordination native to their platform, bypassing the need for a protocol. | High | Medium | @rileydrakedesign | The standards-aspirational positioning per [`../project-context.md` §1.3](../project-context.md#13-positioning) makes TAP an attractive substrate even for vendors. Active engagement with the A2A working group reduces the surprise factor. | Open | 2026-04-29 |
| MR-003 | **Editor-native conflict detection.** Editors could ship single-machine multi-agent conflict detection internally, reducing TAP's value at the team boundary. | Medium | Medium | @rileydrakedesign | TAP's value proposition is at the team boundary, not the within-machine boundary, per [`../project-context.md` §1.4](../project-context.md#14-non-goals). The non-goal is explicit. Cross-developer consults remain TAP's headline differentiator regardless of editor capability. | Open | 2026-04-29 |

### 2.4 Organizational

| ID | Description | Severity | Likelihood | Owner | Mitigation | Status | Last reviewed |
|---|---|---|---|---|---|---|---|
| OR-001 | **`tap.dev` domain not registered.** `security@tap.dev`, `conduct@tap.dev`, and the public spec hosting URL are referenced in docs but not yet provisioned. | Low | High | @rileydrakedesign | Acquire the domain and provision the addresses. Tracked in [`../project-context.md` §9.6](../project-context.md#96-deferred-items). Until then, in-repo GitHub-native flows are used. | Mitigating | 2026-04-29 |
| OR-002 | **Branch protection not yet configured.** `main` does not yet require signed commits, two-reviewer approval for protected paths, or required CI checks. | Medium | High | @rileydrakedesign | Configure when repo is on GitHub. Tracked in [`../project-context.md` §9.6](../project-context.md#96-deferred-items). | Open | 2026-04-29 |
| OR-003 | **No public PGP key for security disclosures.** [`SECURITY.md`](SECURITY.md) references a key not yet generated. | Low | Medium | @rileydrakedesign | Generate and publish before first tagged release. | Open | 2026-04-29 |
| OR-004 | **Documentation rot.** Six phases of documentation and a 90-day staleness rule create a non-trivial review load. | Medium | Medium | @rileydrakedesign | The doc dashboard per [`DOCUMENTATION_PLAN.md`](DOCUMENTATION_PLAN.md) §10.4 surfaces stale docs. Phase exits gate on doc freshness. The one-fact-one-place rule reduces total document count. | Mitigating | 2026-04-29 |
| OR-005 | **Conduct/security email aliases not provisioned.** Same as OR-001 in effect; tracked separately because it has a distinct mitigation path (provision aliases vs. acquire domain). | Low | High | @rileydrakedesign | Tracked in [`../project-context.md` §9.4](../project-context.md#94-open-questions). | Mitigating | 2026-04-29 |

### 2.5 Legal / compliance

| ID | Description | Severity | Likelihood | Owner | Mitigation | Status | Last reviewed |
|---|---|---|---|---|---|---|---|
| LR-001 | **License-model contention.** Apache 2.0 protocol + BSL 1.1 relay is uncommon. Misperception by potential contributors could deter contribution. | Medium | Low | @rileydrakedesign | [`README.md`](../README.md) and [`GOVERNANCE.md`](GOVERNANCE.md) explain the split clearly. The 4-year Apache conversion of BSL 1.1 is locked. | Mitigating | 2026-04-29 |
| CR-001 | **GDPR compliance for awareness state.** Awareness state contains developer identifiers and activity records. Enterprise EU customers will require a documented GDPR posture. | Medium | High | TBD (Phase 6) | Phase 6 deliverable: GDPR endpoints (DSAR, deletion, portability) and `docs/compliance/GDPR_ENDPOINTS.md`. | Open | 2026-04-29 |
| CR-002 | **SOC 2 audit scope.** Hosted relay enterprise plan promises SOC 2 Type II. Audit cost and timeline can become a Phase 6 schedule risk. | High | Medium | TBD (Phase 6) | Begin SOC 2 Type I scoping during Phase 4 to compress the Phase 6 timeline. | Open | 2026-04-29 |

---

## 3. Resolved risks

(none yet)

---

## 4. Update procedure

- New risks are added by RFC or by direct PR if the risk surfaces from operational experience.
- Severity, likelihood, or mitigation changes require a brief note in the relevant phase's `decisions.md` or in [`../project-context.md` §9.5](../project-context.md#95-decision-log) for cross-phase changes.
- The whole register is reviewed at every phase exit. Bump `last-reviewed` per row.

---

## 5. References

- [`THREAT_MODEL.md`](THREAT_MODEL.md) — adversary-oriented security model. Risks here are project-management-facing; the threat model is engineering-facing.
- [`../project-context.md` §9.4, §9.6](../project-context.md#94-open-questions) — open questions and deferred items, which feed into this register when they grow into named risks.
- [`A2A_MAPPING.md`](A2A_MAPPING.md) — sources risk TR-004.
- [`SECURITY.md`](SECURITY.md) — disclosure policy.
