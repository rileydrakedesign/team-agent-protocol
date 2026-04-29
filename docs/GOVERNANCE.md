# Governance

TAP aspires to be an IETF-track standard, not a single-vendor product. Governance reflects that ambition: protocol decisions are made under an open, documented process distinct from product-implementation decisions.

This document is a placeholder for Phase 1. It will be ratified and expanded as the project takes on external maintainers.

## Project structure

TAP is governed in three layers:

1. **Protocol working group.** Custodians of the TAP specification, CUE schemas, and conformance suite. Decisions follow a documented RFC process with public review periods. Conformance test additions are subject to the same review. Initial composition: project founders. Open to external maintainers as the protocol stabilizes.

2. **Implementation maintainers.** Each component (daemon, relay, adapters, SDKs, dashboards) has a maintainer team responsible for its codebase. Maintainers may make implementation decisions without working-group review provided they do not alter the wire protocol or break conformance.

3. **Steering body.** A small group responsible for cross-cutting concerns: licensing, trademark, security, code-of-conduct enforcement appeals, and resolution of disputes between the working group and maintainers. Phase 1 steering is held by the founding maintainers.

## Decision making

- **Lazy consensus** for routine changes: a PR with one reviewer approval and passing CI may be merged after a brief review window.
- **Working-group RFC** for protocol changes: written proposal, public review period of at least 14 days, working-group vote, recorded decision in `project-context.md` §9.5.
- **Steering decision** for cross-cutting concerns: minuted, published, and recorded in §9.5.

## Locked architectural decisions

[`project-context.md`](../project-context.md) §2 lists architectural decisions that are frozen unless explicitly overturned. Contributors should not relitigate these in PRs; surface concerns in §9.4 (open questions) and route through the working group instead.

## Trademark

"TAP", "Team Agent Protocol", and any associated marks remain controlled by the project's steering body. Use of the marks in derivative implementations follows the conformance program: only implementations that pass the public conformance test suite may use the marks in their product name.

## Funding and sponsorship

If and when the project accepts financial sponsorship or grant funding, sources, amounts, and any obligations attached will be disclosed publicly in this document.

## Amending this document

This document is amended by steering decision after public discussion of at least 30 days. The amendment history is recorded in git.
