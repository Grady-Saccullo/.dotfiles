#!/usr/bin/env python3
"""Rule checker for spec/ and for references from code (see spec/README.md and
spec/repository/documentation.md). This script is the single definition of a
"forbidden reference"; skills and reviewers call it instead of inventing greps.

Modes
  python3 .claude/skills/handle-change/check-spec.py
      1. every spec topic file (not overview.md / decisions.md) starts with a `Conformance:` line
      2. no transient references inside spec/ (tickets, change sets, result files, docs/, "the POC"),
         except in spec/repository whose subject is the docs/changes/spec split
      3. every `spec/<area>/<file>.md[#anchor]` reference in spec/ and in code resolves to an
         existing file and heading
      Note: spec/README.md is the rulebook and is not checked.

  python3 .claude/skills/handle-change/check-spec.py --code <file> [<file>...]
      4. the given code/config files contain no forbidden references: ticket ids (ABC-123),
         change-set ids (m-07), paths under changes/, docs/contract, a docs/results/<file>,
         deploy/local/VERIFIED.md, or a bare "POC"; spec links in them must resolve
      A bare directory such as a `docs/results` output-path default is allowed; a reference to a
      file inside it is not.

Exit code 1 on any finding. Run from the repository root.
"""
from __future__ import annotations

import glob
import os
import re
import sys

SPEC_FILES = sorted(glob.glob("spec/*/*.md"))
# Tracker ticket ids (ABC-123). Narrow per project via CHECK_SPEC_TICKET_ID when too broad.
TICKET_ID = os.environ.get("CHECK_SPEC_TICKET_ID", r"\b[A-Z]{2,}-\d+\b")
SPEC_FORBIDDEN = re.compile(rf"(docs/|changes/|\bm-\d\d\b|{TICKET_ID}|\bPOC\b|results/)")
CODE_FORBIDDEN = re.compile(
    rf"({TICKET_ID}|\bm-\d\d\b|changes/m-|docs/contract|docs/results/[A-Za-z0-9_-]+\.md|VERIFIED\.md|\bPOC\b)"
)
LINK = re.compile(r"spec/([a-z-]+)/([a-z-]+\.md)(#([A-Za-z0-9_-]+))?")
CODE_GLOBS = ["**/*.go", "**/*.ts", "**/*.py", "**/*.sql", "**/*.sh", "**/*.yml", "**/*.yaml", "**/*.json", "Makefile"]
SKIP_DIRS = ("node_modules", ".venv", "/dist/", "/docs/", "/changes/", "/.claude/", "/spec/", "/.git/")


def slug(heading: str) -> str:
    h = re.sub(r"[`*_]", "", heading.strip().lower())
    h = re.sub(r"[^\w\s-]", "", h)
    return re.sub(r"\s+", "-", h).strip("-")


def headings(path: str) -> set[str]:
    with open(path, encoding="utf-8") as f:
        return {slug(l.lstrip("#").strip()) for l in f if l.startswith("#")}


def read(path: str) -> str | None:
    try:
        with open(path, encoding="utf-8", errors="ignore") as f:
            return f.read()
    except OSError:
        return None


class Checker:
    def __init__(self) -> None:
        self.findings: list[str] = []
        self.heads = {p: headings(p) for p in SPEC_FILES}

    def links(self, path: str, text: str) -> None:
        for i, line in enumerate(text.splitlines(), 1):
            for m in LINK.finditer(line):
                target = f"spec/{m.group(1)}/{m.group(2)}"
                if not os.path.exists(target):
                    self.findings.append(f"{path}:{i}: missing spec file {target}")
                elif m.group(4) and m.group(4) not in self.heads.get(target, set()):
                    self.findings.append(f"{path}:{i}: missing anchor {target}#{m.group(4)}")

    def spec(self) -> None:
        if not SPEC_FILES:
            self.findings.append("no spec files found; run from the repository root")
            return
        for p in SPEC_FILES:
            text = read(p) or ""
            lines = text.splitlines()
            if os.path.basename(p) not in ("overview.md", "decisions.md"):
                first = [l for l in lines if l.strip()][:3]
                if not any("Conformance:" in l for l in first):
                    self.findings.append(f"{p}: missing Conformance line in the first lines")
            if not p.startswith("spec/repository/"):
                for i, l in enumerate(lines, 1):
                    if SPEC_FORBIDDEN.search(l):
                        self.findings.append(f"{p}:{i}: transient reference: {l.strip()[:100]}")
            self.links(p, text)
        for pattern in CODE_GLOBS:
            for p in glob.glob(pattern, recursive=True):
                if any(s in "/" + p + "/" for s in SKIP_DIRS):
                    continue
                text = read(p)
                if text and "spec/" in text:
                    self.links(p, text)

    def code(self, files: list[str]) -> None:
        for p in files:
            text = read(p)
            if text is None:
                self.findings.append(f"{p}: cannot read")
                continue
            for i, l in enumerate(text.splitlines(), 1):
                if CODE_FORBIDDEN.search(l):
                    self.findings.append(f"{p}:{i}: forbidden reference: {l.strip()[:100]}")
            self.links(p, text)


def main(argv: list[str]) -> int:
    c = Checker()
    if argv and argv[0] == "--code":
        files = argv[1:]
        if not files:
            print("usage: check-spec.py --code <file> [<file>...]")
            return 2
        c.code(files)
        what = f"{len(files)} code file(s)"
    else:
        c.spec()
        what = f"{len(SPEC_FILES)} spec files"
    if c.findings:
        print("\n".join(c.findings))
        print(f"\n{len(c.findings)} finding(s)")
        return 1
    print(f"ok: {what}, no findings")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
