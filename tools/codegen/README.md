# Codegen pipeline

This directory owns the path from CUE schemas to language bindings:

```
protocol/schemas/*.cue
        │
        ├── cue export --out=jsonschema  ──►  protocol/schemas/_generated/*.json
        │                                            │
        │                                            ├──►  typify                       ──►  crates/tap-protocol/src/generated/
        │                                            └──►  json-schema-to-typescript    ──►  packages/tap-protocol/src/generated/
        │
        └── cue exp gengotypes                                                            ──►  pkg/protocol/generated/
```

Generated files are committed (see `project-context.md` §9.5). CI runs `bazel run //tools/codegen:generate && git diff --exit-code` to detect drift.

## Why three different tools

| Path | Tool | Why this choice |
|---|---|---|
| CUE → JSON Schema | `cue export --out=jsonschema` | Native CUE export. JSON Schema is the lingua franca for downstream codegen tooling. |
| JSON Schema → Rust | [`typify`](https://github.com/oxidecomputer/typify) | Higher-quality Rust output than alternatives; produced by Oxide Computer; becoming the ecosystem standard. |
| JSON Schema → TypeScript | [`json-schema-to-typescript`](https://github.com/bcherny/json-schema-to-typescript) | Single-purpose, ~3M weekly downloads, ecosystem standard. |
| CUE → Go | `cue exp gengotypes` | Official CUE-team path; bypasses the lossy JSON Schema hop. |

The asymmetry (Go bypasses JSON Schema) means Go output could diverge from Rust/TS for edge-case CUE features. The conformance suite is the safety net — if all three runners pass against the same fixtures, divergence is bounded to behavior conformance does not cover.

## Running locally

```bash
bazel run //tools/codegen:generate
```

This regenerates everything under `**/generated/` directories. After a CUE schema change, run this and commit the result alongside the schema change.

## Required tools

The driver script expects these on `PATH`:

- `cue` (≥ 0.10) — install via Homebrew (`brew install cue`) or [from releases](https://github.com/cue-lang/cue/releases)
- `typify` — `cargo install typify-cli`
- `json-schema-to-typescript` — `pnpm install -g json-schema-to-typescript`

Phase 1 keeps these as ambient dependencies. Hermetic toolchain registration via Bazel rules will land once the driver is stable.

## Adding a new schema

1. Add `protocol/schemas/<name>.cue`.
2. List it in `tools/codegen/generate.sh` under the `SCHEMAS=` array.
3. Run `bazel run //tools/codegen:generate`.
4. Commit the regenerated bindings alongside the schema.

## Validating the pipeline

```bash
bazel run //tools/codegen:generate
bazel test //protocol/conformance/...
```

If any of the three language conformance suites fails, the codegen produced something that diverges from the schema. Fix the schema or the codegen rules — never hand-edit generated files.
