# {{change_id}} — Progress

Working record for this change set. Transient: deleted or archived with the change set when it
is `done`. Updated only by the `handle-change` skill (the coordinator), never by subtask agents.

**Run started:** {{date}} · **Mode:** fresh | resume · **Flags:** {{flags}}
**Change evidence:** git diff (repo has commits) | checksum snapshots (no commits yet)

## Work items with problems

Items that contradict the spec, collide with another change set, or depend on something a
pending change set would create — with the resolution chosen (renumber, stub, defer, redirect).

- (none)

## Subtasks

| # | Subtask (work-items group) | Files it may touch | Depends on | Status | Result |
|---|---|---|---|---|---|
| 1 | {{group}} | {{files}} | — | pending | |

Status values: `pending` · `running` · `done` · `failed (<error, one line>)` ·
`blocked (by <#>)` · `pending (cross-repo)` · `redirected-to-spec`.

## Work items redirected to the spec

Items that asked for design or decision text under `docs/`; fulfilled in `spec/` instead.

- (none)

## Acceptance criteria

| Criterion (from overview.md) | Status | Evidence |
|---|---|---|
| {{criterion}} | unmet | |

## Verification runs

| What | Command | Result |
|---|---|---|

## Review

- Reviewer findings: (pending)
- Fixes applied: (pending)

## Remaining outside this repo

- (none)

## Log

| When | Event |
|---|---|
| {{date}} | run started |
