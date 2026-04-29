#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Local drift check. CI runs the same command directly; this is the
# `bazel test` entrypoint for contributors who want the same gate locally.

set -euo pipefail

REPO_ROOT="${BUILD_WORKSPACE_DIRECTORY:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "${REPO_ROOT}"

bazel run //tools/codegen:generate

if ! git diff --exit-code; then
  echo "::error::Generated bindings drifted. Run 'bazel run //tools/codegen:generate' and commit the result." >&2
  exit 1
fi

echo "✓ no drift"
