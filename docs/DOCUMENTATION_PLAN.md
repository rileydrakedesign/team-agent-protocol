---
status: accepted
phase: continuing
owners: [@rileydrakedesign]
last-reviewed: 2026-04-29
---

# TAP Documentation Plan

This document specifies how TAP's documentation is structured, written, reviewed, and kept consistent across the six development phases. It is the meta-document: it does not describe the system itself; it describes how the system is documented.

The goal is not to produce more documentation. The goal is to make the documentation a coherent, queryable, low-maintenance asset — so that any contributor (human or agent) can pick up any phase, find what they need, and trust what they read.

---

## 1. Principles

1. **One fact, one place.** Each fact lives in exactly one document. Other documents link. If you find yourself paraphrasing, link instead.
2. **Same shape every phase.** Every phase produces the same set of doc types in the same paths. Consistency is repetition.
3. **Templates are checked into the repo.** Copying a template directory is the standard way to start a phase, component, or runbook.
4. **CI enforces what it can.** Doc lints, drift checks, and template-conformance checks run on every PR.
5. **Docs are deliverables.** A phase does not exit until its doc bundle is complete. See [`README.md`](README.md) "Document status conventions" and `../project-context.md` §8 ship criteria.
6. **Existing docs are migrated incrementally.** Pre-existing documents under `docs/` predate this plan. They are migrated to the conventions below the next time they are touched, not as a separate sweep.

---

## 2. The documentation taxonomy

Six layers, fully described in [`README.md`](README.md). In short:

| Layer | Path | Cadence |
|---|---|---|
| Foundation | `docs/*.md` | Stable. Revised through RFCs. |
| Phase | `docs/phases/phase-N/` | One bundle per phase. Frozen at phase exit. |
| RFC | `docs/rfcs/NNNN-*.md` | One per design decision. Append-only after acceptance. |
| Component | `docs/components/<component>/` | Lives with the code. Updated as code changes. |
| Runbook | `docs/runbooks/*.md` | Updated per incident or release. |
| Wire-format spec | `protocol/SPEC.md`, `protocol/schemas/`, `protocol/conformance/` | Versioned per [`VERSIONING.md`](VERSIONING.md). |

---

## 3. The phase doc spine

Every phase produces this exact set of documents. Same names, same locations.

```
docs/phases/phase-N/
├── README.md              # phase scope, ship criteria, doc index for this phase
├── test-plan.md           # unit, integration, conformance, chaos, perf, security
├── perf-budget.md         # latency budget, memory ceiling, throughput floor
├── threat-model.md        # phase-specific delta to docs/THREAT_MODEL.md
├── migration.md           # what changes from previous phase
├── open-questions.md      # phase-scoped open questions
├── decisions.md           # phase-scoped append-only decision log
└── exit.md                # operationalized ship criterion
```

A phase that does not need one of these documents (e.g., Phase 1 has no migration story) still includes the file with content "N/A — <reason>".

Templates: [`phases/_template/`](phases/_template/).

---

## 4. The component doc set

Every major component produces this exact set:

```
docs/components/<component>/
├── ARCHITECTURE.md        # internal design
├── CONFIG.md              # configuration reference
├── OPERATING.md           # how to run it
├── SECURITY.md            # component-specific security posture
└── INTERFACES.md          # contracts at component boundaries
```

Components include: `daemon`, `relay`, `dashboard`, `admin-console`, `cli`, and one directory per adapter (`adapters/claude-code/`, `adapters/cursor/`, etc.).

A component's per-language `CLAUDE.md` (per `../project-context.md` Appendix A) lives in the source-code subdirectory (e.g., `crates/tap-daemon/CLAUDE.md`), not in `docs/components/`. The two are complementary: `docs/components/<component>/` is for humans; `crates/.../CLAUDE.md` is for agents working on the code.

Templates: [`components/_template/`](components/_template/).

---

## 5. RFC numbering

RFCs are numbered with a 4-digit zero-padded prefix. Numbers are allocated by phase:

| Range | Phase |
|---|---|
| `0000` | Template (reserved) |
| `0001`–`0009` | Phase 1 — Protocol & foundations |
| `0010`–`0099` | Phase 2 — Daemon, local conflict, Claude Code adapter |
| `0100`–`0199` | Phase 3 — Hosted relay, cross-developer awareness |
| `0200`–`0299` | Phase 4 — Messaging, consults, tasks, trust |
| `0300`–`0399` | Phase 5 — Semantic detection, multi-editor, dashboard v2 |
| `0400`–`0499` | Phase 6 — Enterprise |
| `0900`–`0999` | Continuing concerns (cross-phase: perf, security program, governance) |

Numbers are reserved on RFC creation, never reused, never re-allocated to a different phase. If a phase exhausts its range, the next adjacent unused range is allocated and noted in [`RFC_PROCESS.md`](RFC_PROCESS.md).

The RFC index is `docs/rfcs/README.md` (created when the first non-template RFC lands).

---

## 6. Front-matter

Every `.md` file under `docs/` (and the per-phase, per-component, per-RFC subdirectories) carries a YAML front-matter block. See [`README.md`](README.md) §"Document status conventions" for the schema.

The minimum required fields:

```yaml
---
status: draft | accepted | implemented | superseded | withdrawn
phase: 1 | 2 | 3 | 4 | 5 | 6 | continuing
owners: [@github-handle, ...]
last-reviewed: YYYY-MM-DD
---
```

CI rejects PRs that:

- add a doc without front-matter
- change a doc's content without bumping `last-reviewed`
- mark a doc `accepted` without an associated RFC reference (where applicable)

---

## 7. Cross-references

- Use relative paths.
- Link to documents by their canonical path under `docs/` (or `protocol/` for the wire spec).
- Link to project-context.md sections by `../project-context.md#<anchor>`.
- Link to specific lines of source code by `../path/to/file.ext#L<n>` only in informative text; never in normative.
- Never embed external URLs in normative text where the URL might rot. If an external standard is referenced, cite it by document name + version + organization (e.g., "RFC 6455"), and put the URL in a sibling informative footnote.

---

## 8. Spec-style discipline

The protocol specification at [`../protocol/SPEC.md`](../protocol/SPEC.md) is the most-stylized document in the project. It follows additional rules in [`SPEC_STYLE.md`](SPEC_STYLE.md):

- RFC 2119 keywords used precisely.
- Wire-format facts live in CUE; the prose is summary.
- Every fixture has a positive and a negative case.
- Error codes allocated from the registry; never reused.

Other documents inherit a relaxed version of the same conventions. Use MUST/SHOULD/MAY only when the document is stating a binding rule.

---

## 9. Authorship order

The full authorship plan is enumerated in `../project-context.md` §9.3 and in this answer's parent thread. The summary:

1. **Foundation docs** (this batch) — written first.
2. **Phase 1 spec completion** — finish `protocol/SPEC.md` §6–8 and matching schemas/fixtures.
3. **MCP tool surface RFC + Claude Code adapter RFC** — out of order with Phase 2, written next, because every adapter and every Phase 2 component depends on these contracts.
4. **Full Phase 2 spine and component RFCs.**
5. **Phase 4 consults design RFC** — out of order, in parallel with Phase 3, because consults are the riskiest design and inform message-routing decisions in the relay.
6. **Phase 3, 4, 5, 6 spines** in order.

---

## 10. Consistency mechanisms

The following are CI-enforced where feasible; manual review covers the rest.

### 10.1 Doc lints (CI)

- `markdownlint` with project rules in `.markdownlint.yaml`.
- `vale` with the TAP style file at `docs/.vale.ini` enforcing RFC 2119 vocabulary.
- A custom linter at `tools/doclint/` (Phase 1 follow-up) that:
  - rejects undefined glossary terms used outside `docs/GLOSSARY.md`
  - rejects orphan docs (no inbound link from `docs/README.md`)
  - rejects RFCs without required sections (per `docs/rfcs/0000-template.md`)
  - rejects relative links to nonexistent files
  - rejects status changes without a corresponding `decisions.md` entry
  - flags docs whose `last-reviewed` is older than 90 days
  - flags front-matter that fails schema validation

### 10.2 Spec ↔ schema ↔ fixture coupling (CI)

- Every section of `protocol/SPEC.md` that introduces a message MUST reference the CUE schema that backs it.
- Every CUE schema MUST have at least one positive and one negative fixture.
- The conformance runner MUST execute every fixture.

A drift check runs `bazel run //tools/codegen:generate && git diff --exit-code` on every PR.

### 10.3 Phase exit gating

A phase cannot be marked complete until `docs/phases/phase-N/exit.md` is fully checked. The checklist references every doc in the spine.

### 10.4 Doc dashboard

A generated artifact (CI-published) lists every doc, its status, owner, and `last-reviewed` date. Stale = older than 90 days. Stale docs block phase exits until refreshed.

---

## 11. Migrating existing docs

`CONTRIBUTING.md`, `GOVERNANCE.md`, `SECURITY.md`, `THREAT_MODEL.md`, `ARCHITECTURE.md`, `CODE_OF_CONDUCT.md` predate this plan and lack YAML front-matter. They are migrated as follows:

1. The next change to any of those files MUST add front-matter.
2. CI's front-matter check is initially advisory for these six paths and becomes blocking once all six are migrated.
3. Migration progress is tracked in `../project-context.md` §9.6 (deferred items).

No bulk-migration commit. The point of the rule is to keep migration cost amortized, not to manufacture work.

---

## 12. When this plan changes

This document is amended through the RFC process. Numbering: RFC `0900`-series (continuing concerns).

Trivial fixes (typos, broken links) may be made directly. Anything affecting structure, naming conventions, or CI policy goes through an RFC.
