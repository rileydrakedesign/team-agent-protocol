---
status: draft
phase: continuing
owners: ["@your-github-handle"]
last-reviewed: YYYY-MM-DD
rfc_number: NNNN
title: "Short imperative title"
discussion_pr: ""
implementation_tracking: []
---

# RFC NNNN — Short imperative title

> **How to use this template.** Copy this file to `rfcs/NNNN-short-slug.md`, replacing `NNNN` with the next unused number from the range allocated to your phase (see [`../DOCUMENTATION_PLAN.md`](../DOCUMENTATION_PLAN.md) §5). Fill in front-matter and every required section. Required sections are marked **(required)**; optional sections may be removed if not needed but MUST be replaced with "N/A — <reason>" if they are removed for "not applicable" reasons in Migration / compatibility, Security considerations, or Drawbacks. See [`../RFC_PROCESS.md`](../RFC_PROCESS.md) for the full process.

---

## Summary (required)

One paragraph, plain English. What does this RFC propose? A reader who reads only this paragraph should know the proposal's shape and scope.

## Motivation (required)

Why now? What problem does this solve? What happens if we do nothing?

Be specific. Quantify where possible. Cite [`../GLOSSARY.md`](../GLOSSARY.md) terms rather than redefining them.

## Design (required)

The proposal itself. Concrete enough that an engineer can implement from it.

For protocol changes, include:

- New CUE schema definitions (or links to PRs).
- New method names and field tables.
- New error codes and their allocation.
- New conformance fixtures (or a list of fixtures to add).

For component changes, include:

- The interface contract.
- Data model.
- Algorithms (pseudocode or described procedurally).
- Performance budget impact, with numbers.

For documentation or process changes, include:

- The new convention.
- The migration path for existing artifacts.
- The CI enforcement strategy, if any.

Use diagrams when they reduce ambiguity. ASCII is preferred over images.

## Alternatives considered (required)

At least one credible alternative, with its trade-offs. Reject alternatives by argument, not by assertion.

## Drawbacks (required)

What does this proposal make worse? Every change has a cost; surface it.

If you genuinely believe there are no drawbacks, say so explicitly with the reasoning. Reviewers will challenge a "no drawbacks" claim.

## Unresolved questions (required)

Issues to resolve before acceptance, and issues deliberately deferred to a later RFC. Each item identifies a question and its resolution path: "decide before acceptance" or "track in `phases/phase-N/open-questions.md` and resolve later".

## Migration / compatibility (required)

What changes for existing implementations, operators, or users?

Cite the relevant rules in [`../VERSIONING.md`](../VERSIONING.md) (MAJOR/MINOR/PATCH classification) and [`../CONFORMANCE.md`](../CONFORMANCE.md) (claim implications) where applicable.

If "N/A", say so with a reason.

## Security considerations (required)

STRIDE-aligned analysis: which threats does this introduce, mitigate, or transfer?

Cross-reference [`../THREAT_MODEL.md`](../THREAT_MODEL.md) and the relevant phase threat-model addendum if applicable. New controls SHOULD be reflected in those documents in the same change.

If "N/A", say so with a reason. Be skeptical of "N/A" here.

---

## Prior art (optional)

References to similar designs in other systems. Cite by title + organization + URL in informative form.

## Future work (optional)

Non-binding gestures at where this might go. Distinct from "Unresolved questions" — future work is what we are deliberately not deciding now.

## Appendices (optional)

Long examples, full schemas, pseudocode that would crowd the Design section.

---

## Authoring checklist

Before opening the PR (delete this section once submitting; the items belong as commit-ready, not in the merged RFC):

- [ ] Front-matter complete.
- [ ] Number allocated from the correct phase range.
- [ ] All required sections present, no placeholder text remaining.
- [ ] At least one alternative discussed substantively.
- [ ] Drawbacks not silently elided.
- [ ] Migration and security sections honestly addressed (or "N/A" with a real reason).
- [ ] Linked from any existing RFC this supersedes; superseded RFC's `status` updated in the same PR.
- [ ] Cited terms exist in [`../GLOSSARY.md`](../GLOSSARY.md); new terms added there.
- [ ] If the RFC introduces a new convention or rule, the relevant foundation doc is updated in the same PR.
