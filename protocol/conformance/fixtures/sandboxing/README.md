---
status: draft
phase: 1
owners: [@rileydrakedesign]
last-reviewed: 2026-04-29
---

# Sandboxing fixture corpus

These fixtures exercise the schema-level controls that defend against the prompt-injection patterns documented in [`../../../docs/THREAT_MODEL.md`](../../../docs/THREAT_MODEL.md) §5.3.

The Phase 1 corpus focuses on what the **schema layer** can reject without ambiguity:

- Control characters (NUL, ANSI escape sequences, zero-width whitespace) in free-text fields.
- Unicode formatting characters that affect rendering (right-to-left override, byte-order mark).
- Length-bound bypass.
- Path traversal in file-path fields.

It also includes positive fixtures for content that the schema accepts but **consumers MUST NOT interpolate** into agent prompts. These fixtures are part of the contract a conformant implementation MUST satisfy: it accepts the message at the wire level (so legitimate uses are not broken) and treats it as opaque structured data (so injection attempts via legitimate-looking text reach a UI element, not a system prompt).

Phase 4 expands this corpus to cover messaging and consult content, where the attack surface is significantly larger. See [`../../../docs/phases/phase-1/test-plan.md`](../../../docs/phases/phase-1/test-plan.md) §4 for the Phase 1 set and [`../../../docs/THREAT_MODEL.md`](../../../docs/THREAT_MODEL.md) §5 for the underlying control.

## Fixture categories

| Fixture prefix             | Means                                                                                                                   |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `negative_*`               | Schema MUST reject; an attacker's smuggling attempt is contained at parse time.                                         |
| `accepted_but_dangerous_*` | Schema accepts; positive fixture with `notes` documenting that consumers MUST NOT interpolate the content into prompts. |

## References

- [`../../../docs/THREAT_MODEL.md`](../../../docs/THREAT_MODEL.md) §5
- [`../../../docs/CONFORMANCE.md`](../../../docs/CONFORMANCE.md) §1
- [`../../../docs/phases/phase-1/threat-model.md`](../../../docs/phases/phase-1/threat-model.md)
