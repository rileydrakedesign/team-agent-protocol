<!--
Thanks for contributing to TAP. Before opening, please verify:
- [ ] Your commit messages follow Conventional Commits (commitlint will check).
- [ ] Pre-commit hooks pass locally (`pre-commit run --all-files`).
- [ ] `bazel test //...` passes locally.
- [ ] If you changed CUE schemas, you ran `bazel run //tools/codegen:generate` and committed regenerated bindings.
- [ ] If you changed the wire protocol, you updated `protocol/SPEC.md` and added/updated conformance fixtures.
-->

## Summary

<!-- What changed and why. Reference the issue or RFC this addresses. -->

## Type of change

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Protocol change (requires working-group review per `docs/GOVERNANCE.md`)
- [ ] Documentation only

## Affected components

<!-- e.g. protocol, daemon, relay-core, claude-code-adapter, codegen, web -->

## Testing

<!-- How was this verified? Conformance fixtures added? Manual reproduction steps? -->

## Checklist

- [ ] Conformance suite still passes
- [ ] License headers present on new files
- [ ] No hand-edits to files under `**/generated/`
- [ ] `project-context.md` §9.5 updated if a locked decision is being changed (requires explicit user approval first)
