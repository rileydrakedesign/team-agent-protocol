---
status: accepted
phase: continuing
owners: [@rileydrakedesign]
last-reviewed: 2026-04-29
---

# TAP RFC Process

This document specifies how design decisions enter the TAP project. Anything that materially changes the protocol, an architectural decision, a component contract, or a documentation convention goes through an RFC.

The process is deliberately lightweight. It is not a gate against ideas; it is a way to keep them legible and reviewable by people who are not in the room.

---

## 1. When to write an RFC

You SHOULD open an RFC for any of:

- A new method, field, or error code in the wire protocol.
- A change to a [locked decision](../project-context.md#2-locked-architectural-decisions).
- A new component or a major redesign of an existing one.
- A new documentation convention or change to an existing one.
- A new operational policy (release, security, deprecation, governance).
- A change to the conformance suite that adds, removes, or alters required tests.

You do not need an RFC for:

- Bug fixes that do not change documented behavior.
- Internal refactors that do not change interfaces.
- Adding test coverage to existing behavior.
- Documentation typo fixes or link repairs.
- Adding fixtures that exercise already-specified behavior (that is a PATCH, per [`VERSIONING.md`](VERSIONING.md) §2.2).

When in doubt, ask in an issue first. Cheaper to clarify than to discard.

---

## 2. Lifecycle

```
                ┌────────────┐
                │   Draft    │   author writes; not yet open for review
                └─────┬──────┘
                      │  PR opened
                ┌─────▼──────┐
                │ Discussion │   open PR; structured review
                └─────┬──────┘
                      │  reviewers converge
                ┌─────▼──────────┐
                │ Final Comment  │   ≥7 days, no new substantive concerns
                │    Period      │
                └─────┬──────────┘
                      │  merge
                ┌─────▼──────┐                ┌──────────┐
                │  Accepted  │ ─────────────▶ │ Withdrawn│   author abandons before acceptance
                └─────┬──────┘                └──────────┘
                      │  code ships
                ┌─────▼──────────┐
                │  Implemented   │   referenced from working state
                └─────┬──────────┘
                      │  later RFC supersedes
                ┌─────▼──────────┐
                │  Superseded    │   kept for history; new RFC linked
                └────────────────┘
```

State is recorded in the RFC's front-matter `status` field.

---

## 3. Authoring

### 3.1 Start from the template

Copy [`rfcs/0000-template.md`](rfcs/0000-template.md) to a new file. Pick a number from the range allocated to the relevant phase per [`DOCUMENTATION_PLAN.md`](DOCUMENTATION_PLAN.md) §5.

Name files `NNNN-short-slug.md` where the slug uses lowercase ASCII and dashes. Example: `0015-mcp-tool-surface.md`.

### 3.2 Number allocation

Allocate the lowest unused number in the relevant phase range. Reserve the number by opening an empty placeholder commit in your working branch with just the front-matter and title; this prevents collisions when multiple authors work in parallel.

### 3.3 Required sections

Every RFC MUST contain these sections in this order:

1. **Summary** — one paragraph, plain English, what the RFC proposes.
2. **Motivation** — why now, what problem this solves, what happens if we do nothing.
3. **Design** — the proposal itself. Concrete enough that an engineer can implement from it.
4. **Alternatives considered** — at least one credible alternative with its trade-offs.
5. **Drawbacks** — what this proposal makes worse.
6. **Unresolved questions** — open issues to resolve before acceptance, plus issues deliberately deferred.
7. **Migration / compatibility** — what changes for existing implementations or operators. "N/A" with reason if none.
8. **Security considerations** — STRIDE-aligned threats this introduces or mitigates. "N/A" with reason if none.

Optional sections:

- **Prior art** — references to similar designs in other systems.
- **Future work** — non-binding gestures at where this might go.
- **Appendices** — long examples, schemas, pseudocode.

### 3.4 Front-matter

Every RFC MUST carry the front-matter block from [`README.md`](README.md). Additional RFC-specific fields:

```yaml
---
status: draft | discussion | fcp | accepted | implemented | superseded | withdrawn
phase: 1 | 2 | 3 | 4 | 5 | 6 | continuing
owners: [@github-handle]
last-reviewed: 2026-04-29
rfc_number: 0015
title: "MCP tool surface"
discussion_pr: "https://github.com/.../pull/N"  # filled in when PR opens
implementation_tracking: ["#N", "#M"]            # filled in on acceptance
supersedes: rfcs/NNNN-old.md                     # if applicable
superseded_by: rfcs/NNNN-new.md                  # filled in if/when superseded
---
```

`fcp` is the Final Comment Period status.

---

## 4. Review

### 4.1 Reviewers

Two reviewers are required for any RFC. For RFCs touching the wire protocol or [`tools/codegen/`](../tools/codegen/), branch protection requires that at least one reviewer have commit access to those directories (see [`GOVERNANCE.md`](GOVERNANCE.md) and `../project-context.md` §9.6 deferred items for the protected-paths config).

### 4.2 Discussion venue

Discussion happens on the GitHub pull request that introduces the RFC file. Long-form arguments belong in PR comments where they can be referenced; chat-room discussion is allowed but MUST be summarized back into the PR before merge.

### 4.3 Final comment period

When reviewers have converged on a proposal, the author or a maintainer announces FCP by changing `status` to `fcp` and posting a comment. FCP lasts at least 7 calendar days.

If a substantive concern is raised during FCP, the FCP timer resets after the concern is resolved or explicitly deferred.

### 4.4 Acceptance

The PR merges with `status: accepted` once FCP closes without remaining concerns. The merge commit is the moment of acceptance. Once accepted, the RFC's design section is effectively immutable; further changes to the design require a new RFC that supersedes the old one.

### 4.5 Withdrawal

An author MAY withdraw an unmerged RFC at any time. Set `status: withdrawn`, leave a brief explanation, and merge the PR. Withdrawn RFCs remain in the repository for history.

---

## 5. After acceptance

### 5.1 Implementation tracking

Acceptance does not require implementation. Implementation tracking is via GitHub issues linked from the `implementation_tracking` front-matter field.

### 5.2 Implemented status

When the implementation lands, update the RFC's `status` to `implemented` in a small follow-up PR. This change is non-substantive and does not require RFC review.

### 5.3 Superseding

A new RFC may supersede an accepted or implemented RFC. The new RFC sets `supersedes:`; the old RFC is updated in the same change to set `status: superseded` and `superseded_by:`.

Superseded RFCs are kept in place. Do not delete.

---

## 6. Numbering

Allocation by phase per [`DOCUMENTATION_PLAN.md`](DOCUMENTATION_PLAN.md) §5:

| Range | Phase |
|---|---|
| 0000 | Template |
| 0001–0009 | Phase 1 |
| 0010–0099 | Phase 2 |
| 0100–0199 | Phase 3 |
| 0200–0299 | Phase 4 |
| 0300–0399 | Phase 5 |
| 0400–0499 | Phase 6 |
| 0900–0999 | Continuing concerns |

If a range is exhausted, allocate the next adjacent unused range and update [`DOCUMENTATION_PLAN.md`](DOCUMENTATION_PLAN.md) and this document in the same RFC.

The RFC index is `rfcs/README.md`, generated from front-matter when the first non-template RFC merges.

---

## 7. Light-weight RFCs

Some changes warrant an RFC but do not need every section. The author MAY drop sections by writing "N/A" with a one-line reason. Reviewers SHOULD challenge "N/A" on Migration, Security, or Drawbacks if the change has any plausible such concern.

---

## 8. Anti-patterns

- **RFC after implementation.** Acceptable only as documentation of a fait accompli, and only when the implementation is small and reversible. Otherwise, write the RFC first.
- **RFC for a feature flag.** A feature flag is not a design decision; the thing the flag controls is. Write the RFC for the underlying change.
- **Multiple unrelated proposals in one RFC.** Split. Cross-link.
- **Open-ended exploration disguised as RFC.** Use a discussion issue first; promote to RFC when there is a concrete proposal.

---

## 9. Examples

The first non-template RFCs land in Phase 1. Future contributors should consult them as worked examples, in this order:

- `rfcs/0001-codegen-pipeline.md` (small, contained)
- `rfcs/0015-mcp-tool-surface.md` (large, concrete contract)
- `rfcs/0201-consults-design.md` (large, design-heavy)

Each is referenced as it lands.

---

## 10. Amendments

This document is itself an RFC-managed artifact. Amendments via RFC `0901-rfc-process-update.md` (or successor numbers in the `0900` range).

Trivial fixes (typos, broken links) may bypass the RFC process.
