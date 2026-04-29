# @tap/protocol (TypeScript)

TypeScript bindings for the [TAP — Team Agent Protocol](https://github.com/tap-dev/tap).

```bash
pnpm add @tap/protocol
```

## What's in here

- Generated wire types from `protocol/schemas/*.cue` (under `src/generated/`).
- Hand-written envelope helpers (version negotiation, trace_id handling).

## Status

Phase 1 draft. The wire format is not yet stable; this package tracks `protocol/SPEC.md` v0.1.0-draft.

## Generated code

Files under `src/generated/` are produced by `tools/codegen/generate.sh`. Do not hand-edit. Schema changes go in `protocol/schemas/*.cue`.

## License

Apache 2.0. See the root `LICENSE` file.
