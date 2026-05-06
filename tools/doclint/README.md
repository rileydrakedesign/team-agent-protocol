<!--
status: accepted
phase: continuing
owners: ["@rileydrakedesign"]
last-reviewed: 2026-05-04
-->

# tools/doclint

Custom linter for TAP documentation. Implements the checks specified in
[`docs/DOCUMENTATION_PLAN.md`](../../docs/DOCUMENTATION_PLAN.md) §10.1.

## Run

```bash
pip install pyyaml
python tools/doclint/doclint.py            # lint default paths
python tools/doclint/doclint.py --json     # machine-readable output
python tools/doclint/doclint.py path/...   # lint specific files
python tools/doclint/doclint.py --dashboard > doc-dashboard.md
```

Exit code is the number of `error`-severity findings (capped at 255).
Warnings do not affect the exit code.

## Checks

| Code            | Severity        | What it checks                                                                                                                                                                          |
| --------------- | --------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `FM001`         | error           | YAML front-matter parses                                                                                                                                                                |
| `FM002`         | error / warning | YAML front-matter is present (warning on legacy paths per DOCUMENTATION_PLAN.md §11)                                                                                                    |
| `FM003`–`FM011` | error / warning | Front-matter required-field schema (`status`, `phase`, `owners`, `last-reviewed`)                                                                                                       |
| `FM020`         | warning         | `last-reviewed` is older than 90 days                                                                                                                                                   |
| `LK001`         | error           | Relative markdown link target does not exist on disk                                                                                                                                    |
| `OR001`         | error           | Foundation-tier doc not linked from `docs/README.md`                                                                                                                                    |
| `RFC001`        | error           | RFC missing one of the required H2 sections (Summary, Motivation, Design, Alternatives considered, Drawbacks, Unresolved questions, Migration / compatibility, Security considerations) |

Two checks listed in DOCUMENTATION_PLAN.md §10.1 are deferred:

- **Undefined glossary terms** — needs an explicit term-extraction policy (RFC 0001-range follow-up).
- **Status changes without a `decisions.md` entry** — needs git-diff or PR-level integration (Phase 2).

The deferred checks are documented inline in `doclint.py` so future work has clear pickup points.

## Skip rules

The linter skips:

- `docs/phases/_template/`, `docs/components/_template/`, `docs/runbooks/_template.md`, `docs/rfcs/0000-template.md` — placeholders.
- `**/generated/**`, `**/_generated/**` — codegen output.
- `node_modules/`, `vendor/`, `target/`, `bazel-*/`.
- `protocol/conformance/` — JSON fixtures, not markdown.

## Adding a new check

Add a function `check_<name>(doc: DocFile) -> list[Finding]` (or `check_<name>(all_docs: dict[Path, DocFile]) -> list[Finding]` if cross-file), wire it into `lint()`, allocate a code in a new prefix, and add a row to the table above.
