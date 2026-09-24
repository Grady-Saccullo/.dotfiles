---
name: archive-change
description: Archives a finished change set — moves changes/m-NN-<name>/ to changes/archives/, moves its CHECKLIST.md row into the Archived table, removes the id from every other change set's dependencies (unblocking them), rewrites path references and links, and marks the set done first when told to. Use when the user says "archive the m-01 change", "archive m-02", "/archive-change m-01", "close out m-03", or right after handle-change reports a change set done. Arguments: <m-NN | m-NN-name | name> [--dry-run] [--mark-done].
allowed-tools: Bash(python3 ~/.claude/skills/archive-change/archive.py*) Bash(python3 ~/.claude/skills/handle-change/check-spec.py*) Bash(git status*) Bash(git diff*) Bash(ls *) Bash(grep *) Bash(cat *) Bash(sed -n*)
---

# archive-change

Close the lifecycle of a change set under `changes/`: once it is `done` or `dropped`, move it to
`changes/archives/`, make the checklist and every other change set agree that it is history, and
leave `changes/` holding only live work. The mechanics are deterministic and live in
`archive.py`; this skill decides whether the change set is ready, runs the script, judges what the
script deliberately leaves to a person, and reports. Paths below are relative to the repository
root. The conventions the script enforces are written down in `changes/README.md`
("Archiving a change set") and in the `## Archived` table of `changes/CHECKLIST.md`.

## 1. Resolve and dry-run

The argument is `$ARGUMENTS` as a slash command, otherwise the user's sentence (`m-01`, `m1`,
`m-01-repo-structure`, `repo-structure`, or a sentence containing one). Flags: `--dry-run`
(plan only), `--mark-done` (set `done` before archiving). Run:

```
python3 ~/.claude/skills/archive-change/archive.py <argument> --dry-run
```

The script resolves the id itself (zero or several matches: it lists candidates; ask the user
which one). Its output has three parts you must read:

- **status and readiness** — CHECKLIST status, `overview.md` status, unticked work items, subtasks
  not `done`, acceptance criteria not `met`, cross-repo items deferred, and which "Remaining…"
  sections `progress.md` still has;
- **plan** — the move, every table row and header line it will edit, every path reference and
  link it will rewrite, files it will create;
- **remaining mentions** — lines outside the archive that still name the id after the edits.
  These are for step 4; the script never touches prose.

Read nothing else beyond the change set's `overview.md` header and, when the status is not
terminal, the `## Acceptance criteria` and `## Remaining…` sections of its `progress.md`.

## 2. Decide

- Status `done` or `dropped` → proceed to step 3 without flags. (`dropped` should have a numbered
  decision in the set's `decisions.md` saying why; the script notes when it does not. Add one if
  the user gave the reason; otherwise say so in the report.)
- Any other status → the script refuses and lists what is outstanding. Sort the leftovers:
  - **human steps outside the repo** (an external review, a registry choice, a Terraform row),
    **deferred cross-repo work**, and **"partially met" measurements the user has accepted** can
    be waived;
  - **unticked work items, `failed` or `running` subtasks, and unmet criteria that code in this
    repo could still satisfy** cannot: stop, report them, and point at `handle the m-NN change`.
  If everything outstanding is waivable and the user asked to archive or to mark it done, proceed
  with `--mark-done`. If the user is present and it is unclear whether they accept the waivers,
  ask once, listing them. If they are not present and did not say to mark it done, stop and
  report what would be waived.
- If the user says to **drop** the change set instead: add a numbered decision to its
  `decisions.md` (context, decision, alternatives, consequences), set `dropped` in the CHECKLIST
  row and in `overview.md`, then proceed as for a terminal status.
- `git status --short changes/` — uncommitted edits inside the change set's directory move
  with it and are fine; uncommitted edits to `changes/CHECKLIST.md` or `changes/README.md` are
  fine too (the script edits in place). Mention both in the report so the user knows what the
  commit will contain.

## 3. Apply

```
python3 ~/.claude/skills/archive-change/archive.py <argument> [--mark-done]
```

The script performs the plan, then runs its own `--check` and must end with `check ok`. A finding
is a defect to fix by hand (usually a link the script could not resolve because it was already
broken); fix it, then run `python3 ~/.claude/skills/archive-change/archive.py --check` again.

Re-running on an already-archived set is safe: it repairs references and re-checks, and edits
nothing that is already right.

## 4. Judge the remaining mentions

The script lists every line outside `changes/archives/`, `docs/` and `.claude/` that still names
the id. Apply these rules, editing only active change sets and the CHECKLIST `Notes` column:

- `## Suggested tracks` in the CHECKLIST and the `## Log` history stay as they are.
- Prose that states history or a fact stays: "the m-01 layout", "after m-01", "vectors from
  m-02", "(m-02 shapes)".
- A line that still reads as a **pending prerequisite** is reworded to state the fact in a few
  words, without the id when the id adds nothing: "→ m-02 must carry it" becomes "carried by
  contract v1"; "wait for m-01's registry decision" becomes "registry: GitHub Packages
  (decided)" when the decision exists, or names where it is still open.
- A `- [ ]` work item in another change set that says "after m-NN" or "(→ path after m-NN)" keeps
  its checkbox; rewrite only the parenthetical to the path that now exists.
- Never edit `spec/`, `docs/`, code, or anything under `changes/archives/`.

## 5. Verify and report

Run `python3 ~/.claude/skills/archive-change/archive.py --check` and
`python3 ~/.claude/skills/handle-change/check-spec.py`; both must report ok. Then `git status --short`.

Report, in this order: the outcome (archived, or refused and why); the new location; the final
status and, with `--mark-done`, the waived items verbatim; which change sets lost a dependency
and any that went from `blocked` to `pending`; prose you reworded (file and line); and the
commit command if the user wants one (`git add -A changes/ README.md CLAUDE.md && git commit -m
"m-NN: archive"`, or their jj flow). Do not commit or push unless asked.

## Rules

- Archiving is a move, never a delete; `progress.md` stays with the change set.
- Nothing under `changes/archives/` is edited except by `archive.py` during the archive itself.
- The script is the only thing that edits the `## Status`, `## Archived` and `## Log` tables and
  the dependency columns during an archive; do not hand-edit them in parallel.
- Do not change a change set's status to `done` by hand to get past the refusal; use
  `--mark-done` so the waiver is recorded in the log and in `progress.md`.
- Do not widen scope: no code, no spec, no other change set's plan beyond the rewording in step 4.
