#!/usr/bin/env python3
"""Archive a finished change set (see changes/README.md, "Archiving a change set").

Moves changes/<m-NN-name>/ to changes/archives/<m-NN-name>/ and makes the rest of the repository
agree with the move:

  * changes/CHECKLIST.md: the row leaves the `## Status` table and lands in `## Archived`; the id
    is removed from every other row's `Hard deps` / `Soft deps`; a `## Log` line is appended;
    `Last updated` is refreshed.
  * changes/README.md: the row leaves the `## Index` table (its one-liner moves to `## Archived`).
  * every active change set's overview.md header: the id is removed from `Depends on:`, `Soft:`
    and `Blocked by:`; a set that was `blocked` only by this id becomes `pending` (or
    `in-progress` when it has a progress.md), in the header and in CHECKLIST.md.
  * every `changes/<dir>` path reference in the repository is rewritten to
    `changes/archives/<dir>`; relative links between markdown files under changes/ are retargeted.
  * the archived progress.md gets a closing `## Archived` section.

The script never changes the archived set's own status unless `--mark-done` is given; without
it, a set that is not `done` or `dropped` is refused with a readiness report.

Usage (from the repository root):
  python3 .claude/skills/archive-change/archive.py <m-NN | m-NN-name | name> [--dry-run] [--mark-done]
  python3 .claude/skills/archive-change/archive.py --check

Exit codes: 0 ok · 1 findings from --check · 2 refused / bad arguments.
"""
from __future__ import annotations

import datetime as _dt
import glob
import os
import re
import sys

CHANGES = "changes"
ARCHIVES = os.path.join(CHANGES, "archives")
CHECKLIST = os.path.join(CHANGES, "CHECKLIST.md")
README = os.path.join(CHANGES, "README.md")
SKIP_DIRS = {".git", ".jj", "node_modules", ".venv", "dist", "__pycache__", ".pytest_cache", ".mypy_cache"}
TERMINAL = ("done", "dropped")
ID_RE = re.compile(r"\bm-(\d\d)\b")
HEADER_LABELS_TO_CLEAN = ("Depends on", "Soft", "Blocked by")
LINK_RE = re.compile(r"\]\(([^)\s]+)\)")
TODAY = _dt.date.today().isoformat()

ARCHIVES_README = """# Archived change sets

Change sets that reached `done` or `dropped` and were moved here by the `archive-change`
skill. Each directory keeps the files it had when it was archived, including `progress.md`.
Nothing here is edited after archiving; the index of archived change sets is the `Archived`
table in [`../CHECKLIST.md`](../CHECKLIST.md).
"""


# ----------------------------------------------------------------------------- helpers

def read(path: str) -> str:
    with open(path, encoding="utf-8") as f:
        return f.read()


def is_text(path: str) -> bool:
    try:
        if os.path.getsize(path) > 2_000_000:
            return False
        with open(path, "rb") as f:
            chunk = f.read(4096)
        return b"\0" not in chunk
    except OSError:
        return False


def walk_files(root: str = ".", skip_prefix: str | None = None):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(d for d in dirnames if d not in SKIP_DIRS)
        for fn in sorted(filenames):
            p = os.path.normpath(os.path.join(dirpath, fn))
            if skip_prefix and (p == skip_prefix or p.startswith(skip_prefix + os.sep)):
                continue
            yield p


def split_row(line: str) -> list[str]:
    return [c.strip() for c in line.strip().strip("|").split("|")]


def join_row(cells: list[str]) -> str:
    return "| " + " | ".join(cells) + " |"


def find_table(lines: list[str], heading: str) -> tuple[int, int, int] | None:
    """Return (header_row_index, first_data_index, end_index_exclusive) of the table under `## heading`."""
    start = None
    for i, l in enumerate(lines):
        if l.strip() == f"## {heading}":
            start = i
            break
    if start is None:
        return None
    i = start + 1
    while i < len(lines) and not lines[i].startswith("|"):
        if lines[i].startswith("## "):
            return None
        i += 1
    if i >= len(lines):
        return None
    header = i
    j = header + 2  # skip separator
    while j < len(lines) and lines[j].startswith("|"):
        j += 1
    return header, header + 2, j


def col_index(header_line: str, name: str) -> int | None:
    cells = split_row(header_line)
    for i, c in enumerate(cells):
        if c.lower().startswith(name.lower()):
            return i
    return None


def split_top(val: str) -> list[tuple[str, str]]:
    """Split on top-level ',' or ';' (outside parentheses). Returns [(fragment, separator)]."""
    out, depth, cur = [], 0, ""
    for ch in val:
        if ch in "([":
            depth += 1
        elif ch in ")]":
            depth = max(0, depth - 1)
        if ch in ",;" and depth == 0:
            out.append((cur, ch))
            cur = ""
        else:
            cur += ch
    out.append((cur, ""))
    return out


FRAG_ID_RE = re.compile(r"^(m-\d\d(?:/m-\d\d)*)(?![A-Za-z0-9-])(.*)$", re.S)


def remove_id(val: str, cid: str) -> str:
    """Remove the change-set id `cid` from a dependency list such as
    `m-NN (hard), m-MM (soft)` or `— (hard); m-NN (soft: …), m-MM (soft: …)`."""
    kept: list[tuple[str, str]] = []
    for frag, sep in split_top(val):
        f = frag.strip()
        m = FRAG_ID_RE.match(f)
        if m:
            ids = m.group(1).split("/")
            if cid in ids:
                rest = [i for i in ids if i != cid]
                if not rest:
                    continue
                f = "/".join(rest) + m.group(2)
        kept.append((f, sep))
    frags = [f for f, _ in kept if f and f != "—"]
    if not frags:
        return "—"
    text = ""
    for k, (f, sep) in enumerate(kept):
        if not f:
            continue
        text += f
        if k < len(kept) - 1 and sep:
            text += sep + " "
    return text.strip().rstrip(",;").strip() or "—"


def remove_id_from_cell(cell: str, cid: str) -> str:
    ids = [c.strip() for c in cell.split(",") if c.strip() and c.strip() != "—"]
    ids = [i for i in ids if i != cid]
    return ", ".join(ids) if ids else "—"


def header_end(lines: list[str]) -> int:
    for i, l in enumerate(lines):
        if l.startswith("## "):
            return i
    return len(lines)


def header_value(lines: list[str], label: str) -> str | None:
    for l in lines[: header_end(lines)]:
        for seg in l.split(" · "):
            m = re.match(r"^\*\*([^*]+):\*\*\s*(.*)$", seg.strip())
            if m and m.group(1) == label:
                return m.group(2).strip()
    return None


def set_header_value(lines: list[str], label: str, value: str) -> bool:
    for i, l in enumerate(lines[: header_end(lines)]):
        segs = l.split(" · ")
        changed = False
        for k, seg in enumerate(segs):
            m = re.match(r"^(\s*)\*\*([^*]+):\*\*\s*(.*?)(\s*)$", seg)
            if m and m.group(2) == label and m.group(3) != value:
                segs[k] = f"{m.group(1)}**{label}:** {value}{m.group(4)}"
                changed = True
        if changed:
            lines[i] = " · ".join(segs)
            return True
    return False


# ----------------------------------------------------------------------------- transaction

class Tx:
    """Buffered edits and a directory move; nothing touches disk until commit()."""

    def __init__(self) -> None:
        self.texts: dict[str, str] = {}
        self.orig: dict[str, str] = {}
        self.move: tuple[str, str] | None = None
        self.notes: list[str] = []
        self.new_files: dict[str, str] = {}

    def get(self, path: str) -> str:
        if path not in self.texts:
            self.texts[path] = self.orig[path] = read(path)
        return self.texts[path]

    def put(self, path: str, text: str) -> None:
        if path not in self.orig:
            self.orig[path] = read(path) if os.path.exists(path) else ""
        self.texts[path] = text

    def changed(self) -> list[str]:
        return sorted(p for p, t in self.texts.items() if t != self.orig.get(p))

    def commit(self) -> None:
        if self.move:
            src, dst = self.move
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            os.rename(src, dst)
        for p, t in self.texts.items():
            if t == self.orig.get(p):
                continue
            target = p
            if self.move and (p == self.move[0] or p.startswith(self.move[0] + os.sep)):
                target = self.move[1] + p[len(self.move[0]):]
            os.makedirs(os.path.dirname(target) or ".", exist_ok=True)
            with open(target, "w", encoding="utf-8") as f:
                f.write(t)
        for p, t in self.new_files.items():
            if not os.path.exists(p):
                os.makedirs(os.path.dirname(p) or ".", exist_ok=True)
                with open(p, "w", encoding="utf-8") as f:
                    f.write(t)


# ----------------------------------------------------------------------------- resolve

def list_dirs() -> tuple[list[str], list[str]]:
    active = sorted(os.path.basename(p.rstrip("/")) for p in glob.glob(f"{CHANGES}/m-*/"))
    archived = sorted(os.path.basename(p.rstrip("/")) for p in glob.glob(f"{ARCHIVES}/m-*/"))
    return active, archived


def resolve(arg: str) -> tuple[str, str, str]:
    """Return (id, dirname, location) with location in {"active", "archived"}."""
    active, archived = list_dirs()
    candidates = [(d, "active") for d in active] + [(d, "archived") for d in archived]
    m = re.search(r"\bm-?0*(\d+)\b", arg, re.I)
    hits: list[tuple[str, str]] = []
    if m:
        cid = f"m-{int(m.group(1)):02d}"
        hits = [(d, loc) for d, loc in candidates if d.startswith(cid + "-")]
    if not hits:
        words = [w for w in re.split(r"[^a-z0-9]+", arg.lower()) if len(w) > 2 and not re.match(r"m?\d+$", w)]
        hits = [(d, loc) for d, loc in candidates if all(w in d for w in words)] if words else []
    if len(hits) != 1:
        print(f"cannot resolve {arg!r}: candidates {[d for d, _ in hits] or [d for d, _ in candidates]}")
        sys.exit(2)
    d, loc = hits[0]
    return d[:4], d, loc


# ----------------------------------------------------------------------------- readiness

def checklist_status(cid: str) -> str | None:
    lines = read(CHECKLIST).splitlines()
    t = find_table(lines, "Status")
    if not t:
        return None
    hdr, first, end = t
    si = col_index(lines[hdr], "Status")
    for l in lines[first:end]:
        cells = split_row(l)
        if cells and cells[0] == cid:
            return cells[si] if si is not None and si < len(cells) else None
    return None


def readiness(dirpath: str) -> dict:
    r: dict = {"unticked": [], "subtasks_open": [], "criteria_unmet": [], "cross_repo": [],
               "remaining_sections": [], "overview_status": None, "has_progress": False}
    ov = os.path.join(dirpath, "overview.md")
    if os.path.exists(ov):
        r["overview_status"] = header_value(read(ov).splitlines(), "Status")
    wi = os.path.join(dirpath, "work-items.md")
    if os.path.exists(wi):
        for i, l in enumerate(read(wi).splitlines(), 1):
            if re.match(r"^\s*- \[ \]", l):
                r["unticked"].append(f"work-items.md:{i}: {l.strip()}")
    pg = os.path.join(dirpath, "progress.md")
    if os.path.exists(pg):
        r["has_progress"] = True
        lines = read(pg).splitlines()
        t = find_table(lines, "Subtasks")
        if t:
            hdr, first, end = t
            si = col_index(lines[hdr], "Status")
            for l in lines[first:end]:
                c = split_row(l)
                if si is None or si >= len(c):
                    continue
                s = c[si]
                if s.startswith("pending (cross-repo)"):
                    r["cross_repo"].append(f"subtask {c[0]}: {c[1][:60]}")
                elif not (s.startswith("done") or s.startswith("redirected")):
                    r["subtasks_open"].append(f"subtask {c[0]} [{s}]: {c[1][:60]}")
        t = find_table(lines, "Acceptance criteria")
        if t:
            hdr, first, end = t
            si = col_index(lines[hdr], "Status")
            for l in lines[first:end]:
                c = split_row(l)
                if si is None or si >= len(c):
                    continue
                s = c[si].lower()
                if not (s.startswith("met") or s.startswith("not applicable") or s.startswith("n/a")):
                    r["criteria_unmet"].append(f"[{c[si]}] {c[0]}")
        for l in lines:
            if l.startswith("## Remaining") or l.startswith("## Spec statements still open"):
                r["remaining_sections"].append(l[3:].strip())
    return r


def print_readiness(r: dict, status: str | None) -> None:
    print(f"  status: {status or '?'} (CHECKLIST) / {r['overview_status'] or '?'} (overview.md)")
    print(f"  work items unticked: {len(r['unticked'])}; subtasks not done: {len(r['subtasks_open'])}; "
          f"acceptance not met: {len(r['criteria_unmet'])}; cross-repo deferred: {len(r['cross_repo'])}")
    for k, label in (("unticked", "unticked"), ("subtasks_open", "subtask"), ("criteria_unmet", "acceptance"),
                     ("cross_repo", "cross-repo")):
        for item in r[k][:12]:
            print(f"    {label}: {item[:110]}")
        if len(r[k]) > 12:
            print(f"    … {len(r[k]) - 12} more")
    for s in r["remaining_sections"]:
        print(f"    progress.md section still present: {s}")


# ----------------------------------------------------------------------------- archive

def archive(arg: str, dry_run: bool, mark_done: bool) -> int:
    cid, dirname, loc = resolve(arg)
    old = os.path.join(CHANGES, dirname)
    new = os.path.join(ARCHIVES, dirname)
    already = loc == "archived"
    src_dir = new if already else old
    print(f"archive-change: {cid} ({dirname}){' — already under archives/, repairing references' if already else ''}")

    status = checklist_status(cid)
    r = readiness(src_dir)
    print_readiness(r, status if not already else "archived")

    # --- decide the final status ------------------------------------------------------------
    waived: list[str] = []
    effective = status or r["overview_status"]
    if already:
        final = effective if effective in TERMINAL else (r["overview_status"] if r["overview_status"] in TERMINAL else "done")
    elif effective in TERMINAL:
        final = effective
        if final == "dropped" and os.path.exists(os.path.join(src_dir, "decisions.md")) \
                and "dropped" not in read(os.path.join(src_dir, "decisions.md")).lower():
            print("  note: status is dropped but decisions.md does not say why (changes/README.md asks it to)")
    else:
        waived = r["unticked"] + r["subtasks_open"] + r["criteria_unmet"]
        if not mark_done:
            print(f"\nrefused: status is {effective!r}, not done/dropped. Re-run with --mark-done to set `done` and archive"
                  + (f" (this would record {len(waived)} waived item(s) in CHECKLIST.md and progress.md)." if waived else "."))
            return 2
        final = "done"
        print(f"  --mark-done: status {effective!r} becomes 'done'"
              + (f"; {len(waived)} item(s) recorded as waived" if waived else "; nothing outstanding"))

    tx = Tx()
    if not already:
        tx.move = (old, new)
    unblocked_deps: list[str] = []
    status_flips: dict[str, str] = {}
    one_line = ""

    # --- changes/README.md: drop the Index row -------------------------------------------------
    if os.path.exists(README):
        lines = tx.get(README).splitlines()
        t = find_table(lines, "Index")
        if t:
            hdr, first, end = t
            for i in range(first, end):
                cells = split_row(lines[i])
                if cells and cells[0] == cid:
                    one_line = cells[-1]
                    del lines[i]
                    tx.notes.append(f"{README}: Index row {cid} removed")
                    break
        tx.put(README, "\n".join(lines) + "\n")

    # --- active overview.md headers: dependency lines and blocked status ----------------------
    active, _ = list_dirs()
    for d in active:
        if d == dirname:
            continue
        ov = os.path.join(CHANGES, d, "overview.md")
        if not os.path.exists(ov):
            continue
        lines = tx.get(ov).splitlines()
        changed_labels = []
        for label in HEADER_LABELS_TO_CLEAN:
            val = header_value(lines, label)
            if val is None or not re.search(rf"\b{cid}\b", val):
                continue
            new_val = remove_id(val, cid)
            if new_val != val and set_header_value(lines, label, new_val):
                changed_labels.append(f"{label}: {val!r} -> {new_val!r}")
        if changed_labels:
            unblocked_deps.append(d[:4])
            tx.notes.append(f"{ov}: " + "; ".join(changed_labels))
            st = header_value(lines, "Status")
            if st == "blocked" and (header_value(lines, "Blocked by") or "—") == "—":
                new_st = "in-progress" if os.path.exists(os.path.join(CHANGES, d, "progress.md")) else "pending"
                set_header_value(lines, "Status", new_st)
                status_flips[d[:4]] = new_st
                tx.notes.append(f"{ov}: Status blocked -> {new_st} (no blocker left)")
            tx.put(ov, "\n".join(lines) + "\n")

    # --- CHECKLIST.md ---------------------------------------------------------------------------
    lines = tx.get(CHECKLIST).splitlines()
    t = find_table(lines, "Status")
    if not t:
        print(f"{CHECKLIST}: no `## Status` table; cannot continue")
        return 2
    hdr, first, end = t
    hi, si_, ci, sti = (col_index(lines[hdr], n) for n in ("Hard deps", "Soft deps", "Change set", "Status"))
    removed_row = None
    i = first
    while i < end:
        cells = split_row(lines[i])
        if cells[0] == cid:
            removed_row = cells
            del lines[i]
            end -= 1
            tx.notes.append(f"{CHECKLIST}: Status row {cid} removed")
            continue
        touched = False
        for k in (hi, si_):
            if k is not None and k < len(cells) and re.search(rf"\b{cid}\b", cells[k]):
                cells[k] = remove_id_from_cell(cells[k], cid)
                touched = True
        if cells[0] in status_flips and sti is not None and sti < len(cells):
            cells[sti] = status_flips[cells[0]]
            touched = True
        if touched:
            lines[i] = join_row(cells)
            if cells[0] not in unblocked_deps:
                unblocked_deps.append(cells[0])
        i += 1
    unblocked_deps = sorted(set(unblocked_deps))

    # Archived table
    ta = find_table(lines, "Archived")
    if not ta:
        insert_at = None
        for j, l in enumerate(lines):
            if l.strip() in ("## Suggested tracks", "## Log") and j > hdr:
                insert_at = j
                break
        if insert_at is None:
            insert_at = len(lines)
        block = [
            "## Archived",
            "",
            "Finished change sets, moved to `archives/` by the `archive-change` skill; their files are not",
            "edited after that. When a change set is archived its id is removed from the dependency columns",
            "above, so nothing in `## Status` waits on it.",
            "",
            "| # | Change set | Final status | Archived | One line |",
            "|---|---|---|---|---|",
            "",
        ]
        lines[insert_at:insert_at] = block
        tx.notes.append(f"{CHECKLIST}: `## Archived` section created")
        ta = find_table(lines, "Archived")
    hdr_a, first_a, end_a = ta
    if not any(split_row(l)[0] == cid for l in lines[first_a:end_a]):
        if not one_line and removed_row and ci is not None:
            one_line = removed_row[-1]
        if not one_line:
            ov_title = read(os.path.join(src_dir, "overview.md")).splitlines()[0] if os.path.exists(os.path.join(src_dir, "overview.md")) else ""
            one_line = ov_title.split("—", 1)[-1].strip() if "—" in ov_title else ov_title.lstrip("# ").strip()
        row = join_row([cid, f"[`{dirname}`](archives/{dirname}/overview.md)", final, TODAY, one_line])
        lines.insert(end_a, row)
        tx.notes.append(f"{CHECKLIST}: Archived row {cid} added")

    # Log line
    tl = find_table(lines, "Log")
    if tl:
        _, first_l, end_l = tl
        parts = [f"{cid} archived to `archives/{dirname}`"]
        if not already and effective != final:
            parts.append(f"status {effective} set to {final} by archive-change")
        if waived:
            parts.append("waived: " + "; ".join(w.split(": ", 1)[-1][:120] for w in waived[:6]) + (" …" if len(waived) > 6 else ""))
        if unblocked_deps:
            parts.append("removed from the dependencies of " + ", ".join(unblocked_deps))
        if status_flips:
            parts.append("unblocked: " + ", ".join(f"{k} -> {v}" for k, v in status_flips.items()))
        log_row = join_row([TODAY, "; ".join(parts) + "."])
        if not any(f"{cid} archived to" in l for l in lines[first_l:end_l]):
            lines.insert(end_l, log_row)
            tx.notes.append(f"{CHECKLIST}: Log line appended")
    lines = [re.sub(r"Last updated: \d{4}-\d\d-\d\d", f"Last updated: {TODAY}", l) for l in lines]
    tx.put(CHECKLIST, "\n".join(lines) + "\n")

    # --- the archived set's own files -----------------------------------------------------------
    ov = os.path.join(src_dir, "overview.md")
    if os.path.exists(ov):
        lines = tx.get(ov).splitlines()
        touched = False
        if header_value(lines, "Status") != final and (mark_done or final in TERMINAL):
            touched |= set_header_value(lines, "Status", final)
        if (header_value(lines, "Blocked by") or "—") != "—":
            touched |= set_header_value(lines, "Blocked by", "—")
        if touched:
            tx.notes.append(f"{ov}: header Status -> {final}, Blocked by -> —")
            tx.put(ov, "\n".join(lines) + "\n")
    pg = os.path.join(src_dir, "progress.md")
    if os.path.exists(pg):
        text = tx.get(pg)
        if "\n## Archived" not in text:
            sec = ["", "## Archived", "", f"- **When:** {TODAY} · **Final status:** {final} · **Location:** `{ARCHIVES}/{dirname}/`"]
            if waived:
                sec.append("- **Waived when marking done:**")
                sec += [f"  - {w}" for w in waived]
            if r["cross_repo"]:
                sec.append("- **Deferred cross-repo items (still open elsewhere):**")
                sec += [f"  - {c}" for c in r["cross_repo"]]
            sec.append("- This file is not edited after archiving.")
            tx.put(pg, text.rstrip("\n") + "\n" + "\n".join(sec) + "\n")
            tx.notes.append(f"{pg}: `## Archived` section appended")

    # --- path references repo-wide ---------------------------------------------------------------
    if not already:
        pat = re.compile(rf"(?<!archives/)changes/{re.escape(dirname)}(?![A-Za-z0-9_-])")
        rewritten: list[str] = []
        for p in walk_files("."):
            if not is_text(p) or p.startswith(".claude" + os.sep) and p.endswith(".py"):
                continue
            text = tx.texts.get(p)
            if text is None:
                try:
                    text = read(p)
                except (OSError, UnicodeDecodeError):
                    continue
                if not pat.search(text):
                    continue
                tx.orig[p] = text
            new_text, n = pat.subn(f"changes/archives/{dirname}", text)
            if n:
                tx.texts[p] = new_text
                rewritten.append(f"{p} ({n})")
        if rewritten:
            tx.notes.append("path references rewritten: " + ", ".join(rewritten))

        # relative links between markdown files under changes/
        old_abs = os.path.abspath(old)
        new_abs = os.path.abspath(new)
        retargeted: list[str] = []
        for p in walk_files(CHANGES):
            if not p.endswith(".md"):
                continue
            text = tx.texts.get(p)
            if text is None:
                text = read(p)
            file_old_dir = os.path.dirname(os.path.abspath(p))
            file_new_dir = new_abs + file_old_dir[len(old_abs):] if file_old_dir == old_abs or file_old_dir.startswith(old_abs + os.sep) else file_old_dir
            count = 0

            def fix(m: re.Match) -> str:
                nonlocal count
                target = m.group(1)
                if re.match(r"^[a-z]+:", target) or target.startswith(("#", "/")):
                    return m.group(0)
                path, _, anchor = target.partition("#")
                if not path:
                    return m.group(0)
                abs_old = os.path.normpath(os.path.join(file_old_dir, path))
                if not os.path.exists(abs_old):
                    return m.group(0)
                abs_new = new_abs + abs_old[len(old_abs):] if abs_old == old_abs or abs_old.startswith(old_abs + os.sep) else abs_old
                rel = os.path.relpath(abs_new, file_new_dir)
                if path.endswith("/") and not rel.endswith("/"):
                    rel += "/"
                if rel == path:
                    return m.group(0)
                count += 1
                return f"]({rel}{'#' + anchor if anchor else ''})"

            new_text = LINK_RE.sub(fix, text)
            if count:
                if p not in tx.orig:
                    tx.orig[p] = text
                tx.texts[p] = new_text
                retargeted.append(f"{p} ({count})")
        if retargeted:
            tx.notes.append("relative links retargeted: " + ", ".join(retargeted))

    tx.new_files[os.path.join(ARCHIVES, "README.md")] = ARCHIVES_README

    # --- report -----------------------------------------------------------------------------------
    verb = "would" if dry_run else "will"
    print(f"\n{'plan' if dry_run else 'applying'}:")
    if tx.move:
        print(f"  move  {old}  ->  {new}")
    for n in tx.notes:
        print(f"  edit  {n}")
    if not os.path.exists(os.path.join(ARCHIVES, "README.md")):
        print(f"  create {ARCHIVES}/README.md")
    if not tx.notes and not tx.move:
        print("  nothing to do")

    # remaining mentions for a human / the skill to judge
    mentions: list[str] = []
    for p in walk_files("."):
        if p.startswith((ARCHIVES + os.sep, ".claude" + os.sep, "docs" + os.sep)) or not p.endswith(".md"):
            continue
        text = tx.texts.get(p)
        if text is None:
            try:
                text = read(p)
            except (OSError, UnicodeDecodeError):
                continue
        if tx.move and (p == old or p.startswith(old + os.sep)):
            continue
        for i, l in enumerate(text.splitlines(), 1):
            if p == CHECKLIST and (re.match(r"^\| \d{4}-\d\d-\d\d \|", l) or f"archives/{dirname}" in l):
                continue  # log history and the Archived row this run wrote
            if re.search(rf"\b{cid}\b", l) or dirname in l:
                mentions.append(f"{p}:{i}: {l.strip()[:110]}")
    if mentions:
        print(f"\nremaining mentions of {cid} outside the archive (prose that states history is fine; a line that still reads as a pending dependency is not):")
        for m in mentions[:40]:
            print(f"  {m}")
        if len(mentions) > 40:
            print(f"  … {len(mentions) - 40} more")

    if dry_run:
        print("\ndry run: nothing written")
        return 0
    tx.commit()
    print("\napplied.")
    return check()


# ----------------------------------------------------------------------------- check

def check() -> int:
    findings: list[str] = []
    lines = read(CHECKLIST).splitlines()
    active, archived = list_dirs()
    status_rows: dict[str, list[str]] = {}
    archived_rows: dict[str, list[str]] = {}
    t = find_table(lines, "Status")
    if t:
        hdr, first, end = t
        for l in lines[first:end]:
            c = split_row(l)
            status_rows[c[0]] = c
        hi, si_, sti = (col_index(lines[hdr], n) for n in ("Hard deps", "Soft deps", "Status"))
    else:
        findings.append(f"{CHECKLIST}: no `## Status` table")
        hi = si_ = sti = None
    ta = find_table(lines, "Archived")
    if ta:
        _, first_a, end_a = ta
        for l in lines[first_a:end_a]:
            c = split_row(l)
            archived_rows[c[0]] = c
    active_ids = {d[:4]: d for d in active}
    archived_ids = {d[:4]: d for d in archived}

    for cid, d in active_ids.items():
        if cid not in status_rows:
            findings.append(f"{CHANGES}/{d}: active directory has no row in `## Status`")
        if cid in archived_rows:
            findings.append(f"{CHANGES}/{d}: listed in `## Archived` but still under changes/")
    for cid, d in archived_ids.items():
        if cid not in archived_rows:
            findings.append(f"{ARCHIVES}/{d}: archived directory has no row in `## Archived`")
        if cid in status_rows:
            findings.append(f"{ARCHIVES}/{d}: archived but still has a row in `## Status`")
        ov = os.path.join(ARCHIVES, d, "overview.md")
        if os.path.exists(ov):
            st = header_value(read(ov).splitlines(), "Status")
            if st not in TERMINAL:
                findings.append(f"{ov}: archived set has status {st!r}, expected done or dropped")
    for cid in status_rows:
        if cid not in active_ids and cid not in archived_ids:
            findings.append(f"{CHECKLIST}: `## Status` row {cid} has no directory")
    for cid in archived_rows:
        if cid not in archived_ids:
            findings.append(f"{CHECKLIST}: `## Archived` row {cid} has no directory under {ARCHIVES}/")

    for cid, c in status_rows.items():
        for k, name in ((hi, "Hard deps"), (si_, "Soft deps")):
            if k is None or k >= len(c):
                continue
            for dep in ID_RE.findall(c[k]):
                dep = f"m-{dep}"
                if dep in archived_ids:
                    findings.append(f"{CHECKLIST}: {cid} {name} names archived {dep}; remove it")
                elif dep not in active_ids:
                    findings.append(f"{CHECKLIST}: {cid} {name} names unknown {dep}")
        d = active_ids.get(cid)
        if d:
            ov = os.path.join(CHANGES, d, "overview.md")
            if os.path.exists(ov):
                ol = read(ov).splitlines()
                st = header_value(ol, "Status")
                if sti is not None and sti < len(c) and st and st != c[sti]:
                    findings.append(f"{ov}: Status {st!r} differs from CHECKLIST {c[sti]!r}")
                for label in HEADER_LABELS_TO_CLEAN:
                    val = header_value(ol, label) or ""
                    for dep in ID_RE.findall(val):
                        dep = f"m-{dep}"
                        if dep in archived_ids:
                            findings.append(f"{ov}: `{label}:` names archived {dep}; remove it")

    # path references and relative links
    path_re = re.compile(r"changes/([A-Za-z0-9_./-]+)")
    for p in walk_files("."):
        if not p.endswith(".md") or p.startswith(".claude" + os.sep):
            continue
        try:
            text = read(p)
        except (OSError, UnicodeDecodeError):
            continue
        for i, l in enumerate(text.splitlines(), 1):
            for m in path_re.finditer(l):
                target = f"changes/{m.group(1)}".rstrip(".,;:)")
                nxt = l[m.end():m.end() + 1]
                if any(x in target for x in ("NN", "<", "XX", "{{", "m-*")) or target.endswith("-") or nxt == "<":
                    continue
                if not os.path.exists(target):
                    findings.append(f"{p}:{i}: path {target} does not exist")
        if p.startswith(CHANGES + os.sep):
            for i, l in enumerate(text.splitlines(), 1):
                for m in LINK_RE.finditer(l):
                    target = m.group(1)
                    if re.match(r"^[a-z]+:", target) or target.startswith(("#", "/")):
                        continue
                    path = target.partition("#")[0]
                    if not path or any(x in path for x in ("NN", "<", "{{")):
                        continue
                    if not os.path.exists(os.path.normpath(os.path.join(os.path.dirname(p), path))):
                        findings.append(f"{p}:{i}: broken link {target}")

    if os.path.isdir(ARCHIVES) and not os.path.exists(os.path.join(ARCHIVES, "README.md")):
        findings.append(f"{ARCHIVES}/README.md missing")

    if findings:
        print("\n".join(sorted(set(findings))))
        print(f"\n{len(set(findings))} finding(s)")
        return 1
    print(f"check ok: {len(active)} active, {len(archived)} archived change set(s); checklist, dependency lines and links agree")
    return 0


# ----------------------------------------------------------------------------- main

def main(argv: list[str]) -> int:
    if not os.path.exists(CHECKLIST):
        print(f"{CHECKLIST} not found; run from the repository root")
        return 2
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__.strip())
        return 2
    if argv[0] == "--check":
        return check()
    dry = "--dry-run" in argv
    mark = "--mark-done" in argv
    words = [a for a in argv if not a.startswith("--")]
    if not words:
        print("usage: archive.py <change set> [--dry-run] [--mark-done] | --check")
        return 2
    return archive(" ".join(words), dry, mark)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
