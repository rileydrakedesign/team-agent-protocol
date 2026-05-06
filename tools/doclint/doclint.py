#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""TAP documentation linter.

Implements the checks specified in `docs/DOCUMENTATION_PLAN.md` §10.1:

  Implemented:
    - front-matter schema validation
    - stale `last-reviewed` (> 90 days)
    - broken relative markdown links
    - orphan docs (foundation tier not linked from `docs/README.md`)
    - RFC required sections (per `docs/rfcs/0000-template.md`)

  Deferred (see DOCUMENTATION_PLAN.md §10.1, marked TODO below):
    - undefined glossary terms used outside `docs/GLOSSARY.md`
      Reason: needs an explicit term-extraction policy. Adding without one
      either misses real misuse or generates noise. Tracked as a Phase 1
      follow-up RFC.
    - status changes without a corresponding `decisions.md` entry
      Reason: requires git-diff context or PR-level integration; cannot be
      checked from a single working-tree snapshot. Tracked for Phase 2.

  Legacy-path policy (DOCUMENTATION_PLAN.md §11): the six listed pre-existing
  files at `docs/CONTRIBUTING.md`, `docs/GOVERNANCE.md`, `docs/SECURITY.md`,
  `docs/THREAT_MODEL.md`, `docs/ARCHITECTURE.md`, `docs/CODE_OF_CONDUCT.md`
  are exempt from front-matter checks until migrated. All other checks apply.

Usage:
  python tools/doclint/doclint.py             # lint default paths
  python tools/doclint/doclint.py --json      # machine-readable output
  python tools/doclint/doclint.py path...     # lint specific files

Exit code is the number of errors (capped at 255). Warnings do not affect
the exit code.

Dependencies: PyYAML. Install with `pip install pyyaml` (the only third-
party dep beyond stdlib).
"""

from __future__ import annotations

import argparse
import datetime
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable
from urllib.parse import urlparse, unquote

import yaml


# ---- Configuration ---------------------------------------------------------


REPO_ROOT = Path(__file__).resolve().parents[2]

DEFAULT_LINT_PATHS = (
    REPO_ROOT / "docs",
    REPO_ROOT / "protocol" / "SPEC.md",
    REPO_ROOT / "project-context.md",
    REPO_ROOT / "README.md",
)

LEGACY_PATHS = frozenset(
    REPO_ROOT / p
    for p in (
        "docs/ARCHITECTURE.md",
        "docs/CODE_OF_CONDUCT.md",
        "docs/CONTRIBUTING.md",
        "docs/GOVERNANCE.md",
        "docs/SECURITY.md",
        "docs/THREAT_MODEL.md",
    )
)

# Top-level files exempt from front-matter (not under docs/, not foundation
# layer per DOCUMENTATION_PLAN.md §2).
EXEMPT_FROM_FRONTMATTER = frozenset(
    REPO_ROOT / p
    for p in (
        "README.md",
        "project-context.md",
        "protocol/SPEC.md",
    )
)

SKIP_DIR_NAMES = frozenset(
    {"_template", "generated", "_generated", "node_modules", "vendor", "target"}
)
SKIP_FILES = frozenset(
    REPO_ROOT / p
    for p in (
        "docs/rfcs/0000-template.md",
        "docs/runbooks/_template.md",
    )
)

VALID_STATUS = frozenset(
    {"draft", "discussion", "fcp", "accepted", "implemented", "superseded", "withdrawn"}
)
VALID_PHASE_VALUES = frozenset({1, 2, 3, 4, 5, 6, "continuing"})

STALE_DAYS = 90

# Per `docs/rfcs/0000-template.md`. Headings are matched case-insensitively
# at H2 (`## `) level.
REQUIRED_RFC_SECTIONS = (
    "summary",
    "motivation",
    "design",
    "alternatives considered",
    "drawbacks",
    "unresolved questions",
    "migration / compatibility",
    "security considerations",
)

# Foundation-tier documents that must be reachable from `docs/README.md`'s
# Index of foundation documents table. Subdirectories (phases/, rfcs/,
# components/, runbooks/) are tracked separately.
FOUNDATION_DOCS_DIR = REPO_ROOT / "docs"


# ---- Data model ------------------------------------------------------------


@dataclass
class Finding:
    """One lint result."""

    path: Path
    line: int
    severity: str  # "error" or "warning"
    code: str
    message: str

    def to_dict(self) -> dict:
        return {
            "path": str(self.path.relative_to(REPO_ROOT)),
            "line": self.line,
            "severity": self.severity,
            "code": self.code,
            "message": self.message,
        }


@dataclass
class DocFile:
    """Parsed representation of a single markdown doc."""

    path: Path
    text: str
    frontmatter: dict | None
    frontmatter_error: str | None
    body_offset: int  # line where body starts (1-indexed)
    h2_headings: list[str] = field(default_factory=list)


# ---- Parsing ---------------------------------------------------------------


_FRONTMATTER_PATTERN = re.compile(r"\A---\r?\n(.*?)\r?\n---\r?\n", re.DOTALL)
_LINK_PATTERN = re.compile(r"\[(?:[^\[\]]|\[[^\]]*\])*\]\(([^)]+)\)")
_AUTOLINK_PATTERN = re.compile(r"<([^>]+)>")
_FENCE_LINE_PATTERN = re.compile(r"^\s*```")
# Match a single-line inline code span. Markdown allows `code`, ``code``, etc.
# We mask the contents (replace with spaces) before scanning for links so
# example snippets like `` `[label](target)` `` aren't treated as real links.
_CODE_SPAN_PATTERN = re.compile(r"(`+)([^\n]*?)\1")


def _mask_code_spans(line: str) -> str:
    """Replace inline-code-span content with spaces so link-detection skips it."""
    def _replace(m: re.Match[str]) -> str:
        return m.group(1) + (" " * len(m.group(2))) + m.group(1)
    return _CODE_SPAN_PATTERN.sub(_replace, line)


def parse_doc(path: Path) -> DocFile:
    text = path.read_text(encoding="utf-8")
    fm: dict | None = None
    fm_error: str | None = None
    body_offset = 1

    m = _FRONTMATTER_PATTERN.match(text)
    if m:
        body_offset = text.count("\n", 0, m.end()) + 1
        try:
            parsed = yaml.safe_load(m.group(1))
            if isinstance(parsed, dict):
                fm = parsed
            elif parsed is None:
                fm = {}
            else:
                fm_error = f"front-matter is not a YAML mapping (got {type(parsed).__name__})"
        except yaml.YAMLError as exc:
            fm_error = f"YAML parse error: {exc}"

    h2 = _extract_h2_headings(text, body_offset)

    return DocFile(
        path=path,
        text=text,
        frontmatter=fm,
        frontmatter_error=fm_error,
        body_offset=body_offset,
        h2_headings=h2,
    )


def _extract_h2_headings(text: str, body_offset: int) -> list[str]:
    """Return the lowercased text of every `## ` heading outside fenced code."""
    headings: list[str] = []
    in_fence = False
    for raw in text.splitlines()[body_offset - 1 :]:
        if _FENCE_LINE_PATTERN.match(raw):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        if raw.startswith("## ") and not raw.startswith("### "):
            heading_text = raw[3:].strip()
            heading_text = re.sub(r"^[\d.]+\s+", "", heading_text)
            heading_text = re.sub(r"[`*_]", "", heading_text)
            headings.append(heading_text.lower())
    return headings


def iter_doc_paths(roots: Iterable[Path]) -> list[Path]:
    """Walk roots and return every .md file, applying skip rules."""
    found: set[Path] = set()
    for root in roots:
        if root.is_file() and root.suffix == ".md":
            if not _should_skip(root):
                found.add(root)
            continue
        if not root.is_dir():
            continue
        for p in root.rglob("*.md"):
            if not _should_skip(p):
                found.add(p)
    return sorted(found)


def _should_skip(path: Path) -> bool:
    if path in SKIP_FILES:
        return True
    parts = set(path.parts)
    return bool(parts & SKIP_DIR_NAMES)


# ---- Checks ----------------------------------------------------------------


def check_frontmatter_schema(doc: DocFile) -> list[Finding]:
    """Front-matter presence + schema (DOCUMENTATION_PLAN.md §6)."""
    findings: list[Finding] = []
    is_legacy = doc.path in LEGACY_PATHS
    is_exempt = doc.path in EXEMPT_FROM_FRONTMATTER

    if doc.frontmatter_error:
        findings.append(
            Finding(
                doc.path,
                1,
                "error",
                "FM001",
                f"front-matter parse failed: {doc.frontmatter_error}",
            )
        )
        return findings

    if doc.frontmatter is None:
        if is_legacy:
            findings.append(
                Finding(
                    doc.path,
                    1,
                    "warning",
                    "FM002",
                    "missing YAML front-matter (legacy path; advisory until migrated per DOCUMENTATION_PLAN.md §11)",
                )
            )
            return findings
        if is_exempt:
            return findings
        findings.append(
            Finding(
                doc.path,
                1,
                "error",
                "FM002",
                "missing required YAML front-matter (DOCUMENTATION_PLAN.md §6)",
            )
        )
        return findings

    fm = doc.frontmatter

    severity = "warning" if is_legacy else "error"

    status = fm.get("status")
    if status is None:
        findings.append(
            Finding(doc.path, 1, severity, "FM003", "front-matter missing required field `status`")
        )
    elif status not in VALID_STATUS:
        findings.append(
            Finding(
                doc.path,
                1,
                severity,
                "FM004",
                f"front-matter `status` must be one of {sorted(VALID_STATUS)}; got {status!r}",
            )
        )

    phase = fm.get("phase")
    if phase is None:
        findings.append(
            Finding(doc.path, 1, severity, "FM005", "front-matter missing required field `phase`")
        )
    elif phase not in VALID_PHASE_VALUES:
        findings.append(
            Finding(
                doc.path,
                1,
                severity,
                "FM006",
                f"front-matter `phase` must be 1-6 or 'continuing'; got {phase!r}",
            )
        )

    owners = fm.get("owners")
    if owners is None:
        findings.append(
            Finding(doc.path, 1, severity, "FM007", "front-matter missing required field `owners`")
        )
    elif not isinstance(owners, list) or not owners:
        findings.append(
            Finding(
                doc.path,
                1,
                severity,
                "FM008",
                "front-matter `owners` must be a non-empty list of GitHub handles",
            )
        )
    else:
        for owner in owners:
            if not isinstance(owner, str) or not owner.startswith("@"):
                findings.append(
                    Finding(
                        doc.path,
                        1,
                        severity,
                        "FM009",
                        f"owner {owner!r} must be a string starting with '@'",
                    )
                )

    last_reviewed = fm.get("last-reviewed")
    if last_reviewed is None:
        findings.append(
            Finding(
                doc.path, 1, severity, "FM010", "front-matter missing required field `last-reviewed`"
            )
        )
    else:
        if isinstance(last_reviewed, datetime.date):
            pass  # YAML auto-parses YYYY-MM-DD into date.
        elif isinstance(last_reviewed, str):
            try:
                datetime.date.fromisoformat(last_reviewed)
            except ValueError:
                findings.append(
                    Finding(
                        doc.path,
                        1,
                        severity,
                        "FM011",
                        f"`last-reviewed` must be YYYY-MM-DD; got {last_reviewed!r}",
                    )
                )
        else:
            findings.append(
                Finding(
                    doc.path,
                    1,
                    severity,
                    "FM011",
                    f"`last-reviewed` must be YYYY-MM-DD; got {last_reviewed!r}",
                )
            )

    return findings


def check_stale(doc: DocFile, today: datetime.date) -> list[Finding]:
    """Flag docs whose `last-reviewed` is older than STALE_DAYS days."""
    if not doc.frontmatter:
        return []
    lr = doc.frontmatter.get("last-reviewed")
    if isinstance(lr, datetime.date):
        date = lr
    elif isinstance(lr, str):
        try:
            date = datetime.date.fromisoformat(lr)
        except ValueError:
            return []
    else:
        return []
    age = (today - date).days
    if age > STALE_DAYS:
        return [
            Finding(
                doc.path,
                1,
                "warning",
                "FM020",
                f"`last-reviewed` is {age} days old (> {STALE_DAYS}); refresh and bump the date",
            )
        ]
    return []


def check_links(doc: DocFile, all_docs: dict[Path, DocFile]) -> list[Finding]:
    """Flag relative markdown links whose target file does not exist."""
    findings: list[Finding] = []
    in_fence = False
    for line_no, raw in enumerate(doc.text.splitlines(), start=1):
        if _FENCE_LINE_PATTERN.match(raw):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        if line_no < doc.body_offset:
            continue
        scan = _mask_code_spans(raw)
        for m in _LINK_PATTERN.finditer(scan):
            target = m.group(1).strip()
            if not target or _is_external(target):
                continue
            target_no_anchor = target.split("#", 1)[0].split("?", 1)[0]
            target_no_anchor = unquote(target_no_anchor).strip()
            if not target_no_anchor:
                continue
            resolved = (doc.path.parent / target_no_anchor).resolve()
            if not resolved.exists():
                findings.append(
                    Finding(
                        doc.path,
                        line_no,
                        "error",
                        "LK001",
                        f"broken relative link: target {target_no_anchor!r} resolves to {_relpath(resolved)} which does not exist",
                    )
                )
    return findings


def _is_external(target: str) -> bool:
    parsed = urlparse(target)
    if parsed.scheme in ("http", "https", "mailto", "ftp", "tel"):
        return True
    if target.startswith("#"):
        return True
    return False


def _relpath(p: Path) -> str:
    try:
        return str(p.relative_to(REPO_ROOT))
    except ValueError:
        return str(p)


def check_orphans(all_docs: dict[Path, DocFile]) -> list[Finding]:
    """Flag foundation docs not linked from docs/README.md.

    A foundation doc is any `.md` directly under `docs/` (not in a subdirectory).
    Templates and the index file itself are excluded.
    """
    findings: list[Finding] = []
    index_path = REPO_ROOT / "docs" / "README.md"
    if index_path not in all_docs:
        return []

    index_text = all_docs[index_path].text
    linked_targets: set[Path] = set()
    for m in _LINK_PATTERN.finditer(index_text):
        target = m.group(1).split("#", 1)[0].split("?", 1)[0].strip()
        if not target or _is_external(target):
            continue
        try:
            resolved = (index_path.parent / unquote(target)).resolve()
            linked_targets.add(resolved)
        except OSError:
            continue

    for path, doc in all_docs.items():
        if path == index_path:
            continue
        if path.parent != REPO_ROOT / "docs":
            continue  # Foundation tier is the top docs/ directory only.
        if path in linked_targets:
            continue
        findings.append(
            Finding(
                path,
                1,
                "error",
                "OR001",
                f"foundation doc not linked from docs/README.md (DOCUMENTATION_PLAN.md §1 one-fact-one-place)",
            )
        )
    return findings


def check_rfc_sections(doc: DocFile) -> list[Finding]:
    """Verify every accepted/implemented RFC has the eight required sections."""
    try:
        rel = str(doc.path.relative_to(REPO_ROOT))
    except ValueError:
        return []
    if not rel.startswith("docs/rfcs/"):
        return []
    if doc.path.name == "0000-template.md":
        return []
    if not doc.frontmatter:
        return []  # Schema check already flagged this.
    status = doc.frontmatter.get("status")
    # Required-section check applies once an RFC enters discussion or later.
    if status not in {"discussion", "fcp", "accepted", "implemented", "superseded"}:
        return []

    findings: list[Finding] = []
    have = set(doc.h2_headings)
    for required in REQUIRED_RFC_SECTIONS:
        if not any(required in h for h in have):
            findings.append(
                Finding(
                    doc.path,
                    1,
                    "error",
                    "RFC001",
                    f"RFC missing required section '{required.title()}' (per docs/rfcs/0000-template.md)",
                )
            )
    return findings


# ---- Orchestration ---------------------------------------------------------


def lint(paths: Iterable[Path], today: datetime.date) -> list[Finding]:
    doc_paths = iter_doc_paths(paths)
    docs: dict[Path, DocFile] = {}
    for p in doc_paths:
        try:
            docs[p] = parse_doc(p)
        except OSError as exc:
            print(f"warning: could not read {p}: {exc}", file=sys.stderr)

    findings: list[Finding] = []
    for doc in docs.values():
        findings.extend(check_frontmatter_schema(doc))
        findings.extend(check_stale(doc, today))
        findings.extend(check_links(doc, docs))
        findings.extend(check_rfc_sections(doc))
    findings.extend(check_orphans(docs))
    findings.sort(key=lambda f: (str(f.path), f.line, f.code))
    return findings


def emit_dashboard(roots: Iterable[Path], today: datetime.date) -> str:
    """Generate the doc dashboard from DOCUMENTATION_PLAN.md §10.4.

    A markdown document listing every doc, its status, owner(s), and
    `last-reviewed` age. Stale (>90d) entries are flagged.
    """
    out: list[str] = [
        "# TAP Documentation Dashboard",
        "",
        f"Generated {today.isoformat()}. Stale threshold: {STALE_DAYS} days. Stale rows are flagged ⚠.",
        "",
        "| Path | Status | Phase | Owners | Last reviewed | |",
        "|---|---|---|---|---|---|",
    ]
    for p in iter_doc_paths(roots):
        doc = parse_doc(p)
        rel = _relpath(p)
        fm = doc.frontmatter or {}
        status = str(fm.get("status", "—"))
        phase = str(fm.get("phase", "—"))
        owners = fm.get("owners") or []
        owners_str = ", ".join(o for o in owners if isinstance(o, str)) or "—"

        lr = fm.get("last-reviewed")
        lr_date: datetime.date | None = None
        if isinstance(lr, datetime.date):
            lr_date = lr
        elif isinstance(lr, str):
            try:
                lr_date = datetime.date.fromisoformat(lr)
            except ValueError:
                lr_date = None

        if lr_date is not None:
            age = (today - lr_date).days
            lr_display = f"{lr_date.isoformat()} ({age}d)"
            flag = "⚠" if age > STALE_DAYS else ""
        else:
            lr_display = "—"
            flag = "—" if not fm else ""

        out.append(f"| `{rel}` | {status} | {phase} | {owners_str} | {lr_display} | {flag} |")
    out.append("")
    return "\n".join(out)


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Lint TAP documentation for the rules in docs/DOCUMENTATION_PLAN.md.",
    )
    parser.add_argument(
        "paths",
        nargs="*",
        help="Files or directories to lint. Defaults to docs/, protocol/SPEC.md, project-context.md, README.md.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit findings as a single JSON document.",
    )
    parser.add_argument(
        "--dashboard",
        action="store_true",
        help="Emit the doc dashboard (DOCUMENTATION_PLAN.md §10.4) instead of running checks.",
    )
    parser.add_argument(
        "--today",
        default=None,
        help="Override the date used for staleness comparison (YYYY-MM-DD). For tests.",
    )
    args = parser.parse_args(argv)

    if args.paths:
        roots = [Path(p).resolve() for p in args.paths]
    else:
        roots = list(DEFAULT_LINT_PATHS)

    today = (
        datetime.date.fromisoformat(args.today) if args.today else datetime.date.today()
    )

    if args.dashboard:
        sys.stdout.write(emit_dashboard(roots, today))
        return 0

    findings = lint(roots, today)

    errors = [f for f in findings if f.severity == "error"]
    warnings = [f for f in findings if f.severity == "warning"]

    if args.json:
        print(
            json.dumps(
                {
                    "errors": len(errors),
                    "warnings": len(warnings),
                    "findings": [f.to_dict() for f in findings],
                },
                indent=2,
            )
        )
    else:
        for f in findings:
            color = "\033[31m" if f.severity == "error" else "\033[33m"
            print(
                f"{_relpath(f.path)}:{f.line}: {color}{f.severity}\033[0m {f.code} {f.message}"
            )
        print(
            f"\n{len(errors)} error(s), {len(warnings)} warning(s) in {sum(1 for _ in iter_doc_paths(roots))} file(s).",
            file=sys.stderr,
        )

    return min(len(errors), 255)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
