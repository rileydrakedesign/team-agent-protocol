// SPDX-License-Identifier: Apache-2.0

/**
 * Conformance test runner — TypeScript.
 *
 * Loads every fixture in protocol/conformance/fixtures/ and validates each
 * fixture's `data` against the JSON Schema named by `schema_ref`. Schema docs
 * live in protocol/schemas/_generated/<file>.json and are produced by
 * tools/codegen/generate.sh.
 *
 * Implements the runner contract specified in docs/CONFORMANCE.md §4: emits
 * the §4.1 JSON output (to stdout, and to $TAP_CONFORMANCE_REPORT if set) and
 * fails the test (exit 1 from `node --test`) if any fixture mismatch occurs.
 *
 * Fixture format documented in protocol/conformance/README.md.
 */

import { strict as assert } from "node:assert";
import { test } from "node:test";
import { readFileSync, readdirSync, statSync, writeFileSync, existsSync } from "node:fs";
import { join, extname, dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import Ajv2020 from "ajv/dist/2020.js";
import addFormats from "ajv-formats";

import { TAP_VERSION } from "../envelope.js";

interface Fixture {
  name: string;
  description: string;
  schema_ref: string;
  data: unknown;
  expected_valid: boolean;
  expected_round_trip?: boolean;
  expected_error_code?: number;
}

interface FixtureFailure {
  fixture_path: string;
  expected: string;
  actual: string;
  message: string;
}

interface Report {
  tap_version_target: string;
  suite_version: string;
  fixtures_total: number;
  fixtures_passed: number;
  fixtures_failed: number;
  fixtures_skipped: number;
  failures: FixtureFailure[];
}

function repoRoot(): string {
  // src/test/conformance.test.ts → ../../../../
  const here = dirname(fileURLToPath(import.meta.url));
  return resolve(here, "..", "..", "..", "..");
}

function fixturesRoot(): string {
  if (process.env.TAP_CONFORMANCE_FIXTURES) {
    return process.env.TAP_CONFORMANCE_FIXTURES;
  }
  return join(repoRoot(), "protocol", "conformance", "fixtures");
}

function schemasDocPath(): string {
  if (process.env.TAP_CONFORMANCE_SCHEMAS) {
    return process.env.TAP_CONFORMANCE_SCHEMAS;
  }
  return join(repoRoot(), "protocol", "schemas", "_generated", "all.json");
}

function suiteVersion(): string {
  const candidate = process.env.TAP_CONFORMANCE_VERSION_FILE
    ?? join(repoRoot(), "protocol", "conformance", "VERSION");
  try {
    return readFileSync(candidate, "utf8").trim();
  } catch {
    return "0.0.0";
  }
}

interface FixtureItem {
  path: string;
  fx: Fixture;
}

function loadFixtures(root: string): FixtureItem[] {
  const out: FixtureItem[] = [];
  walk(root, out);
  out.sort((a, b) => a.path.localeCompare(b.path));
  return out;
}

function walk(dir: string, out: FixtureItem[]): void {
  for (const entry of readdirSync(dir)) {
    const path = join(dir, entry);
    const s = statSync(path);
    if (s.isDirectory()) {
      walk(path, out);
    } else if (extname(path) === ".json") {
      const raw = readFileSync(path, "utf8");
      out.push({ path, fx: JSON.parse(raw) as Fixture });
    }
  }
}

function loadSchemaDoc(path: string): unknown | null {
  if (!existsSync(path)) return null;
  const raw = readFileSync(path, "utf8");
  return JSON.parse(raw);
}

function extractDefinition(schemaDoc: unknown, defName: string): Record<string, unknown> | null {
  if (typeof schemaDoc !== "object" || schemaDoc === null) return null;
  const doc = schemaDoc as Record<string, unknown>;
  const defs = doc["$defs"] as Record<string, unknown> | undefined;
  if (!defs) return null;
  const sub = defs[defName];
  if (typeof sub !== "object" || sub === null) return null;
  const clone: Record<string, unknown> = { ...(sub as Record<string, unknown>) };
  clone["$defs"] = defs;
  return clone;
}

test("conformance suite", () => {
  const fixtures = loadFixtures(fixturesRoot());
  const schemaDoc = loadSchemaDoc(schemasDocPath());

  const report: Report = {
    tap_version_target: TAP_VERSION,
    suite_version: suiteVersion(),
    fixtures_total: fixtures.length,
    fixtures_passed: 0,
    fixtures_failed: 0,
    fixtures_skipped: 0,
    failures: [],
  };

  const ajv = new Ajv2020({ strict: false, allErrors: true });
  // ajv-formats provides date-time, uri, etc. Some CUE-derived schemas may
  // emit `format: "uri"` etc.; without this the validator would silently pass.
  addFormats(ajv);

  for (const { path, fx } of fixtures) {
    const hashIdx = fx.schema_ref.indexOf("#");
    if (hashIdx < 1) {
      report.failures.push({
        fixture_path: path,
        expected: "schema_ref = file#Definition",
        actual: fx.schema_ref,
        message: "schema_ref missing '#' separator",
      });
      report.fixtures_failed++;
      continue;
    }
    const def = fx.schema_ref.slice(hashIdx + 1);

    if (schemaDoc === null) {
      report.fixtures_skipped++;
      continue;
    }

    const sub = extractDefinition(schemaDoc, def);
    if (!sub) {
      report.failures.push({
        fixture_path: path,
        expected: `definition ${def} present in $defs`,
        actual: "not found",
        message: `schema_ref ${fx.schema_ref} cannot be resolved`,
      });
      report.fixtures_failed++;
      continue;
    }

    let validate;
    try {
      validate = ajv.compile(sub);
    } catch (err) {
      report.failures.push({
        fixture_path: path,
        expected: "schema compiles",
        actual: String(err),
        message: "JSON Schema compile failed",
      });
      report.fixtures_failed++;
      continue;
    }

    const actualValid = validate(fx.data);

    if (actualValid !== fx.expected_valid) {
      report.failures.push({
        fixture_path: path,
        expected: `expected_valid = ${fx.expected_valid}`,
        actual: `actual_valid = ${actualValid}`,
        message: `validation outcome mismatch for ${fx.name}: ${fx.description}`,
      });
      report.fixtures_failed++;
      continue;
    }

    if (fx.expected_valid && fx.expected_round_trip !== false) {
      const serialized = JSON.stringify(fx.data);
      const reparsed = JSON.parse(serialized);
      try {
        assert.deepStrictEqual(reparsed, fx.data);
      } catch {
        report.failures.push({
          fixture_path: path,
          expected: "round-trip preserves value",
          actual: "value differs after re-serialize",
          message: `round-trip mismatch in ${fx.name}`,
        });
        report.fixtures_failed++;
        continue;
      }
    }

    // expected_error_code is informational at the runner layer in v0.1.
    void fx.expected_error_code;

    report.fixtures_passed++;
  }

  const out = JSON.stringify(report, null, 2);
  console.log(out);

  if (process.env.TAP_CONFORMANCE_REPORT) {
    writeFileSync(process.env.TAP_CONFORMANCE_REPORT, out);
  }

  assert.equal(
    report.fixtures_failed,
    0,
    `${report.fixtures_failed} fixture(s) failed; see JSON report above`,
  );
  assert.ok(report.fixtures_total > 0, `expected at least one fixture under ${fixturesRoot()}`);
});
