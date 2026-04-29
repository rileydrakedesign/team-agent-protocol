// SPDX-License-Identifier: Apache-2.0

/**
 * Hand-written envelope helpers. Wire shape itself is generated; this module
 * adds construction conveniences, version negotiation, and trace_id handling.
 */

/** Current TAP protocol version this binding implements. */
export const TAP_VERSION = "0.1.0";

/**
 * Returns the highest TAP version supported by both peers, or `null` if the
 * major versions are incompatible.
 */
export function negotiateVersion(theirs: string, ours: string): string | null {
  const t = parseSemver(theirs);
  const o = parseSemver(ours);
  if (!t || !o || t.major !== o.major) return null;
  return versionLess(theirs, ours) ? theirs : ours;
}

interface Semver {
  major: number;
  minor: number;
  patch: number;
}

function parseSemver(v: string): Semver | null {
  const core = v.split(/[-+]/, 1)[0]!;
  const parts = core.split(".");
  if (parts.length !== 3) return null;
  const [maj, min, pat] = parts.map((p) => Number.parseInt(p, 10));
  if ([maj, min, pat].some((n) => Number.isNaN(n) || n === undefined)) return null;
  return { major: maj!, minor: min!, patch: pat! };
}

function versionLess(a: string, b: string): boolean {
  const ap = parseSemver(a)!;
  const bp = parseSemver(b)!;
  if (ap.major !== bp.major) return ap.major < bp.major;
  if (ap.minor !== bp.minor) return ap.minor < bp.minor;
  return ap.patch < bp.patch;
}
