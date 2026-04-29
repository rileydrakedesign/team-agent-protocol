# TAP Conformance Suite

A conformant TAP implementation MUST pass every fixture in this directory. The suite is part of the protocol specification (see [`../SPEC.md`](../SPEC.md) §14) and is consumed by per-language test runners under `crates/tap-protocol/tests/`, `pkg/protocol/conformance_test.go`, and `packages/tap-protocol/tests/`.

## Layout

```
conformance/
├── README.md                     this file
├── fixtures/
│   ├── envelope/                 envelope-level cases
│   │   ├── valid_request.json
│   │   ├── invalid_missing_jsonrpc.json
│   │   └── ...
│   ├── agent_register/           agent.register request/response cases
│   ├── agent_heartbeat/
│   └── ...
└── BUILD.bazel
```

Each subdirectory under `fixtures/` corresponds to a method or schema and contains one JSON file per fixture.

## Fixture format

Each fixture is a JSON object with the following shape:

```json
{
  "$schema": "https://tap.dev/conformance/v1.json",
  "name": "agent.register valid request",
  "description": "A well-formed agent.register request with all required fields.",
  "schema_ref": "agent_register#AgentRegisterRequest",
  "data": {
    "jsonrpc": "2.0",
    "tap_version": "0.1.0",
    "trace_id": "0af7651916cd43dd8448eb211c80319c",
    "id": "1",
    "method": "agent.register",
    "params": {
      "developer_id": "rileydrake",
      "agent_id": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
      "machine_id": "fedcba9876543210fedcba9876543210",
      "editor": "claude-code",
      "session_id": "550e8400-e29b-41d4-a716-446655440000",
      "repo": "https://github.com/tap-dev/tap.git",
      "branch": "main",
      "worktree": "/Users/rileydrake/dev/team-agent-protocol",
      "capabilities": ["edit", "search", "shell"]
    }
  },
  "expected_valid": true,
  "expected_round_trip": true
}
```

### Fields

| Field | Type | Required | Meaning |
|---|---|---|---|
| `$schema` | URL | yes | Pin to the conformance fixture schema version. |
| `name` | string | yes | Human-readable. Used in test runner output. |
| `description` | string | yes | One-sentence summary of what the fixture exercises. |
| `schema_ref` | string | yes | `<schema_file>#<DefinitionName>` referencing a CUE schema. |
| `data` | object \| string | yes | The message under test. JSON object for valid messages; raw string permitted for parse-error fixtures. |
| `expected_valid` | boolean | yes | Whether `data` should validate against `schema_ref`. |
| `expected_round_trip` | boolean | no, default `true` | Whether parse → serialize should produce byte-identical output. |
| `expected_error_code` | integer | no | When `expected_valid` is `false`, the canonical error code (see SPEC §13). |
| `notes` | string | no | Implementation guidance, references to spec sections. |

## Per-language test runner contract

Each implementation language exposes a binary or test entry point that:

1. Loads every `*.json` file under `fixtures/`.
2. For each fixture, parses `data` as the type identified by `schema_ref`.
3. Asserts:
   - Parse success matches `expected_valid`.
   - For valid fixtures: serializing back produces the original bytes when `expected_round_trip` is `true`.
   - For invalid fixtures with `expected_error_code` set: the parse error maps to the documented code.
4. Exits non-zero if any assertion fails. Output should identify the failing fixture by `name`.

## Adding a fixture

1. Add the JSON file under the relevant subdirectory.
2. If exercising a new schema, ensure `schema_ref` resolves to a definition in `protocol/schemas/`.
3. Run the conformance suite: `bazel test //protocol/conformance/...`.
4. All three language runners must pass.

## Coverage targets

Phase 1 covers:

- Envelope: well-formed request, response, notification, error response.
- Envelope: missing `jsonrpc`, missing `tap_version`, malformed `trace_id`, wrong `jsonrpc` version.
- `agent.register`: valid request and response; missing required field for each field; out-of-range values for each constrained field.
- `agent.heartbeat`: valid notification; presence/absence of optional state delta.
- `agent.deregister`: valid notification.
- `agent.disconnect`: valid server-initiated notification with each documented reason code.

Coverage expands with each subsequent phase.
