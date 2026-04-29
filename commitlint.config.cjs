// SPDX-License-Identifier: Apache-2.0

/**
 * commitlint config for TAP.
 *
 * Conventional Commits with project-specific scopes. See docs/CONTRIBUTING.md.
 */
module.exports = {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "header-max-length": [2, "always", 100],
    "scope-enum": [
      2,
      "always",
      [
        "protocol",
        "schemas",
        "conformance",
        "codegen",
        "daemon",
        "cli",
        "relay-edge",
        "relay-core",
        "relay-worker",
        "claude-code",
        "cursor",
        "codex",
        "aider",
        "web",
        "admin",
        "deploy",
        "docs",
        "ci",
        "deps",
        "release",
      ],
    ],
    "subject-case": [2, "never", ["pascal-case", "upper-case"]],
  },
};
