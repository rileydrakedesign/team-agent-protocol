# @tap/protocol (TypeScript)

TypeScript bindings for the [TAP — Team Agent Protocol](https://github.com/tap-dev/tap).

```bash
pnpm add @tap/protocol
```

## What's in here

- Generated wire types in `src/generated/all.ts` (one module containing every TAP message and shared type, produced by `json-schema-to-typescript`).
- Hand-written envelope helpers (version negotiation, trace_id handling).
- Conformance test runner that validates every fixture under `protocol/conformance/fixtures/` against the JSON Schema produced from `protocol/schemas/*.cue`. 46/46 passing as of 2026-05-04.

## Status

Phase 1 draft. The wire format is not yet stable; this package tracks `protocol/SPEC.md` v0.1.0-draft.

## Generated code

Files under `src/generated/` are produced by `tools/codegen/generate.sh`. Do not hand-edit. Schema changes go in `protocol/schemas/*.cue`; running the codegen driver refreshes this directory. See [`../../tools/codegen/README.md`](../../tools/codegen/README.md) for the pipeline overview.

## Running the conformance suite

```bash
pnpm install
pnpm --filter @tap/protocol build
pnpm --filter @tap/protocol test
```

A Bazel `js_test` target is deferred until `aspect_rules_js`'s `npm_translate_lock` lands in `MODULE.bazel`; until then the suite runs via the script above and via the dedicated CI `typescript` job.

## License

Apache 2.0. See the root `LICENSE` file.
