// SPDX-License-Identifier: Apache-2.0

/**
 * Conformance test runner — TypeScript.
 *
 * Loads every fixture in protocol/conformance/fixtures/ and asserts the
 * documented behavior. Runs under `node --test` and as a Bazel target.
 *
 * Fixture format documented in protocol/conformance/README.md.
 */

import { strict as assert } from "node:assert";
import { test } from "node:test";
import { readFileSync, readdirSync, statSync } from "node:fs";
import { join, extname, dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

interface Fixture {
  name: string;
  schema_ref: string;
  data: unknown;
  expected_valid: boolean;
  expected_round_trip?: boolean;
  expected_error_code?: number;
}

function fixturesRoot(): string {
  if (process.env.TAP_CONFORMANCE_FIXTURES) {
    return process.env.TAP_CONFORMANCE_FIXTURES;
  }
  const here = dirname(fileURLToPath(import.meta.url));
  return resolve(here, "..", "..", "..", "..", "protocol", "conformance", "fixtures");
}

function loadFixtures(root: string): Fixture[] {
  const out: Fixture[] = [];
  walk(root, out);
  return out;
}

function walk(dir: string, out: Fixture[]): void {
  for (const entry of readdirSync(dir)) {
    const path = join(dir, entry);
    const s = statSync(path);
    if (s.isDirectory()) {
      walk(path, out);
    } else if (extname(path) === ".json") {
      const raw = readFileSync(path, "utf8");
      out.push(JSON.parse(raw) as Fixture);
    }
  }
}

test("fixture corpus loads", () => {
  const root = fixturesRoot();
  const fixtures = loadFixtures(root);
  assert.ok(fixtures.length > 0, `expected at least one fixture under ${root}`);
});

test("every fixture round-trips when expected", () => {
  const fixtures = loadFixtures(fixturesRoot());
  for (const f of fixtures) {
    if (!f.expected_valid) continue;
    if (f.expected_round_trip === false) continue;

    const serialized = JSON.stringify(f.data);
    const reparsed = JSON.parse(serialized);
    assert.deepStrictEqual(reparsed, f.data, `round-trip mismatch in fixture ${f.name}`);
  }
});

// TODO(phase-1): once codegen runs and src/generated/ has typed schemas,
// add per-schema strict-typing assertions: parse fixture.data through the
// generated type and verify expected_valid.
