# Subtask prompt template

Fill every `{{placeholder}}`. Send as the `prompt` of an `Agent` call with
`subagent_type: general-purpose` and a short `description` such as `m-07: quarantine`.
The agent has no memory of this conversation; everything it needs must be in the prompt or
on disk at the paths given.

---

You are implementing one subtask of change set `{{change_id}}` in the Go/TypeScript/Python
repository at `{{repo_root}}`. You start with no context; read before you write.

## Read first, in this order

1. `{{repo_root}}/spec/README.md` — the rules for the spec and for code comments.
2. `{{repo_root}}/spec/repository/code-conventions.md` and `spec/repository/documentation.md`.
3. `{{repo_root}}/changes/{{change_dir}}/overview.md` and `design.md` — what the change set is
   for and what the system looks like after it. `decisions.md` if a work item cites a decision.
4. These spec files, which describe the behaviour your code must conform to:
{{spec_files_bulleted}}
5. The current code you will change (paths in the work items below) and its tests.

## Your work items (do exactly these, nothing more)

{{work_items_verbatim}}

## Files you may create or modify

{{allowed_files_bulleted}}

Anything else is read-only. If a work item cannot be completed without touching another file,
stop and report that instead of touching it. Never edit `changes/`, `spec/`, `CHECKLIST.md`,
`progress.md`, or any file outside the set above; the coordinator owns those. If a work item
below names a `docs/` path, the coordinator has already decided it belongs there (or has given
you the redirected path in the allowed set) — follow the allowed set.

## Rules

- Follow the design in `design.md`; do not redesign. If the design is wrong or impossible, say
  so in your report with the reason and stop that item.
- Code comments explain the local "why" in one sentence and may cite the spec as
  `spec: spec/<area>/<file>.md#<heading>`. Never reference tickets, change sets (`m-NN`),
  pull requests, result files, dates or people in code or comments.
- Database migrations are additive-only, numbered `NNNNN_<name>.sql`, one concern per file,
  with goose `Up`/`Down` sections like the existing ones.
- Go: 1.26, `log/slog`, context everywhere, no globals, table-driven tests, `gofmt`/`go vet`
  clean, no new dependencies unless a work item names one. TypeScript: Node 24 ESM strict,
  Zod at boundaries. Python: 3.13, uv, typed.
- Keep existing metric, log-event and env-var names unless a work item renames them.
- Do not run `docker compose up/down`, `make up/down/reset`, or anything that changes the
  running local stack. You may start a throwaway container for a test
  (`docker run -d -p <port>:5432 -e POSTGRES_PASSWORD=password postgres:16-alpine`) and
  must remove it afterwards.
- Do not commit.

## Verify before you report

{{verification_commands_bulleted}}

Also run `gofmt -l .` (must print nothing), `go build ./...`, `go vet ./...` when Go changed,
and the unit tests of every package you touched.

## Report (this exact shape)

- **Done:** each work item, one line each, with the files changed.
- **Not done:** each work item you could not complete, with the reason.
- **Verification:** the commands you ran and their results (pass/fail, counts, key numbers).
- **Deviations:** anything you did differently from `design.md` and why.
- **Spec drift:** any spec statement you found that the code now contradicts or that is
  missing, so the spec-sync subtask can fix it.
- **Notes for the coordinator:** files outside your set that need a change, follow-ups.
