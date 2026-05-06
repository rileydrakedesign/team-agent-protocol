# Codegen pipeline

This directory owns the path from CUE schemas to language bindings:

```text
protocol/schemas/*.cue
        │  (codegen_export.cue exposes the canonical wire-format
        │   definitions as concrete fields under `CodegenRoot` so
        │   `cue def --out=jsonschema -e CodegenRoot` can emit them
        │   as a single document with `$defs`)
        │
        ├── cue def --out=jsonschema -e CodegenRoot ──►  protocol/schemas/_generated/all.json
        │              │
        │              │  (Python post-processing normalizes CUE's
        │              │   `#Foo` $defs keys and `%23Foo` URL-encoded
        │              │   $refs to plain `Foo`, which downstream tools
        │              │   and JSON Schema validators expect.)
        │              │
        │              ├──►  cargo-typify                 ──►  crates/tap-protocol/src/generated/all.rs
        │              └──►  json-schema-to-typescript    ──►  packages/tap-protocol/src/generated/all.ts
        │
        └── cue exp gengotypes  ──►  pkg/protocol/generated/types.go
```

Generated files are committed (see `project-context.md` §9.5). CI runs `bazel run //tools/codegen:generate && git diff --exit-code` to detect drift. The pipeline is idempotent — running it twice in a row produces byte-identical output.

## Why one combined JSON Schema, not per-file

CUE schemas in `package schemas` reference each other across files (e.g. `agent_register.cue` uses `identity#DeveloperId`). Per-file `cue export` cannot resolve those cross-file `$ref`s, and the CUE CLI's expression parser cannot bind to `#Foo` references directly.

The pipeline emits a single `_generated/all.json` keyed by `$defs` and indexed by definition name (no `#` prefix after post-processing). Each conformance runner looks up `$defs[<DefinitionName>]` per fixture's `schema_ref`. The structural intent of `<file>#<DefinitionName>` is preserved in fixtures as documentation.

## Why three different tools

| Path                     | Tool                                                                                | Why this choice                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| ------------------------ | ----------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| CUE → JSON Schema        | `cue def --out=jsonschema`                                                          | Native CUE export. JSON Schema is the lingua franca for downstream codegen tooling.                                                                                                                                                                                                                                                                                                                                                                                               |
| JSON Schema → Rust       | [`cargo-typify`](https://github.com/oxidecomputer/typify)                           | Higher-quality Rust output than alternatives; produced by Oxide Computer; becoming the ecosystem standard. CLI is published as `cargo-typify`. **Currently disabled** — v0.6.2 panics on the TAP schemas' `allOf+not` patterns from `#FilePath`/`#BranchName` and on the type-narrowing `allOf` for `#LineNumber`/`#TtlSeconds`. The Rust runner validates via JSON Schema directly, so generated Rust types are not on Phase 1's critical path. Tracked as a deferred follow-up. |
| JSON Schema → TypeScript | [`json-schema-to-typescript`](https://github.com/bcherny/json-schema-to-typescript) | Single-purpose, ~3M weekly downloads, ecosystem standard.                                                                                                                                                                                                                                                                                                                                                                                                                         |
| CUE → Go                 | `cue exp gengotypes`                                                                | Official CUE-team path; bypasses the lossy JSON Schema hop. Emits one combined `cue_types_gen.go`; the script relocates it to `pkg/protocol/generated/types.go` and rewrites the `package` declaration.                                                                                                                                                                                                                                                                           |

The asymmetry (Go bypasses JSON Schema) means Go output could diverge from Rust/TS for edge-case CUE features. The conformance suite is the safety net — if all three runners pass against the same fixtures, divergence is bounded to behavior conformance does not cover.

## Running locally

```bash
bazel run //tools/codegen:generate
```

This regenerates everything under `**/generated/` and `protocol/schemas/_generated/`. After a CUE schema change, run this and commit the result alongside the schema change.

## Required host tools

The driver script expects these on `PATH`:

- `cue` (≥ 0.10) — install via Homebrew (`brew install cue`) or [from releases](https://github.com/cue-lang/cue/releases). Tested with v0.16.1.
- `cargo` plus `cargo-typify` — `cargo install cargo-typify --locked` (invoked by the script as `cargo typify`).
- `json-schema-to-typescript` — `pnpm install -g json-schema-to-typescript` (provides the `json2ts` binary).
- `python3` — used for the JSON Schema post-processing step.

Phase 1 keeps these as ambient dependencies. Hermetic toolchain registration via Bazel rules will land in Phase 2.

## Adding a new schema

1. Add `protocol/schemas/<name>.cue`.
2. Add an entry to `protocol/schemas/codegen_export.cue` exposing every public definition the new file introduces (e.g., `MyMessage: #MyMessage`).
3. Run `bazel run //tools/codegen:generate`.
4. Add fixtures under `protocol/conformance/fixtures/<name>/` and run the per-language conformance suites (see [`../../protocol/conformance/README.md`](../../protocol/conformance/README.md)).
5. Commit the regenerated bindings alongside the schema and fixtures.

## CUE-to-JSON-Schema gotchas (learned the hard way)

These came up during the first end-to-end codegen run on 2026-05-04 and are documented here so the next contributor doesn't repeat the discovery. Full context in `docs/phases/phase-1/decisions.md`.

- **`{...}` exports as `{"const": {}}`**, not "any object". For an open struct that should accept any shape, use `[string]: _` instead.
- **Cross-field comparisons** like `end_line >= start_line` cannot be expressed in JSON Schema. CUE will panic with "bad argument to unary comparison" on export. Lift the constraint to the consumer (daemon) and document in spec text.
- **`\0` is not a NUL escape** in Rust's `regex` crate (or in standard JSON Schema). Use `\x00`.
- **Bounded repetitions ≥ 1000** like `{0,1023}` are rejected by Go's `regexp` (RE2). Cap at `{0,999}` or use `+` / `*`.
- **JSON Schema `$ref` siblings** behave differently across drafts. Draft-7 ignores them; 2019-09+ apply them. The runners explicitly compile against draft-2020-12 so derived schemas' tightening constraints (`required`, `properties`, `pattern`) actually layer onto the inherited base schema. The `jsonschema` Rust crate requires the `draft202012` feature flag.
- **CUE files starting with `_`** are excluded from the package — leading underscore means "this file is a build artifact, not part of the package."

## Validating the pipeline

```bash
# Full regeneration + per-language conformance runs.
bazel run //tools/codegen:generate

# Rust (cargo because Bazel doesn't yet wire crate-universe).
( cd crates/tap-protocol && cargo test --test conformance )

# Go.
( cd pkg/protocol && go test -run TestConformanceSuite )

# TypeScript.
pnpm --filter @tap/protocol test
```

If any runner fails, the codegen produced something that diverges from the schema. Fix the schema or the codegen pipeline — never hand-edit generated files.
