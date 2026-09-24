---
name: handle-change
description: Executes one change set from changes/m-NN-<name>/ end to end — resolves the id, checks CHECKLIST.md dependencies, splits work-items.md into subtasks, runs each subtask in a fresh-context subagent, verifies, syncs the spec, updates status. Use when the user says "handle the m-07 change", "work on change set m1-new-feature", "execute/continue/resume m-03", or "/handle-change m-07". Arguments: <m-NN | m-NN-name | name> [--dry-run] [--only <group>] [--include-cross-repo].
allowed-tools: Bash(go *) Bash(gofmt *) Bash(python3 ~/.claude/skills/handle-change/check-spec.py*) Bash(git status*) Bash(git diff*) Bash(git rev-parse*) Bash(ls *) Bash(grep *) Bash(find *) Bash(shasum *) Bash(make test) Bash(make up-core) Bash(make down) Bash(make ps) Bash(docker info) Bash(npm run build) Bash(npm test) Bash(uv run pytest*)
---

# handle-change

Execute a change set under `changes/` the way the repo's conventions demand: the change set is
the plan, `spec/` is the source of truth, every subtask runs in a subagent with fresh context,
and status lives in `changes/CHECKLIST.md`. Re-running the skill on the same change set resumes
from `progress.md`; nothing is redone that is already checked off.

Supporting files in this directory: `subagent-prompt.md` (subtask prompt template),
`spec-sync-prompt.md` (spec-sync subtask template), `review-prompt.md` (final review template),
`progress-template.md`, `check-spec.py` (spec rules, spec links, and forbidden references in
code — the single definition of what a code comment may not cite). Paths below are relative to the repository root.

## 1. Resolve the change set

The argument is `$ARGUMENTS` when invoked as a slash command, otherwise the user's sentence.
It is free text: `m-07`, `m7`, `m-07-scheduler-hardening`, `scheduler-hardening`, or a
sentence containing one of those. Flags: `--dry-run` (plan only, change nothing), `--only <group>`
(run a single subtask: a `work-items.md` sub-heading, or a path prefix such as `internal/store`), `--include-cross-repo` (allow edits in sibling
repos named by work items; off by default).

1. Extract the number if present (`m-?0*(\d+)`) and zero-pad to two digits; extract any name words.
2. `ls -d changes/m-*/` and match by number, else by name substring. A directory that exists
   only under `changes/archives/` is archived: say so and stop.
3. Exactly one match → continue. Zero or several → list the candidates and ask the user which one.
4. Confirm the directory has `overview.md`, `design.md`, `decisions.md`, `work-items.md`,
   `verification.md`, `rollout.md`. If not, stop and report which are missing.

## 2. Load exactly this context, no more

Read, in order: `changes/README.md`, `changes/CHECKLIST.md`, the six change-set files,
`spec/README.md`, and `changes/<id>/progress.md` if it exists. For the spec files on the
`Spec impact:` line read only their headings and conformance lines
(`grep -n '^#\|^Conformance:' <files>`); the subtask agents and the spec-sync agent read them in
full. Do not read the codebase yourself beyond `ls` of the directories the work items name. Keep
your own context small so you can coordinate a long run.

## 3. Preflight

- `--dry-run` → run the checks below but only report their outcome, then print the subtask
  plan from step 5 and stop without writing anything (no `progress.md`, no status change).
- Status in CHECKLIST.md is `done`, or the id is in its `## Archived` table → say so and stop.
- Status is `blocked` → show the `Blocked by:` line and stop unless the user asked to proceed.
- Hard dependencies (CHECKLIST "Hard deps" column) not `done` → report which, set nothing, and
  stop unless the user explicitly said to proceed anyway (in `--dry-run` the plan is still
  printed). Soft dependencies only get a note, plus a list of work items that reference things
  those change sets would have created. An archived change set no longer appears in either
  column (`archive-change` removes it), so every id listed is still live.
- Change evidence baseline: if `git rev-parse HEAD` succeeds, `git diff --stat` is the evidence
  later; if the repository has no commits yet, evidence is a checksum snapshot instead (see
  step 6). Record which mode applies in `progress.md`.
- `progress.md` exists → resume mode: skip subtasks recorded `done`, retry those `failed`, keep
  those `blocked` unless the blocker is resolved.

## 4. Mark in progress

In one edit each: set the CHECKLIST row's status to `in-progress`, set `**Status:**` in
`overview.md` to `in-progress`, and append a dated line to the CHECKLIST `## Log` table
("m-NN started; N subtasks planned"). Create `changes/<id>/progress.md` from
`progress-template.md` if absent.

## 5. Plan subtasks

Work items are grouped under sub-headings in `work-items.md`. When a file has no sub-headings,
group by the top-level directory of the first path in each item (`migrations/`, `internal/store/`,
`cmd/<binary>/`, `docs/`…); a group with no path is its own subtask. Each group is a subtask
unless it is too big or too broad:

- Split a group that has more than about eight items or that spans unrelated directories.
- Merge groups of one or two items that touch the same files.
- A work item that names a sibling repository (a path outside this repo, or a bare
  repository name) goes to a **cross-repo** subtask, which is deferred with status `pending (cross-repo)` unless `--include-cross-repo`.
- `docs/` receives only explanatory or historical material. A work item that adds design or
  decision text there is fulfilled in the spec instead (`spec/<area>/decisions.md` or the topic
  file). A work item that adds *current reference material* there (an API landing page, a CLI
  reference, an OpenAPI document) is redirected too: OpenAPI and schemas go under `contract/`,
  a generated reference goes next to the code it describes (`cmd/<binary>/README.md`), and the
  root `README.md` links them. Record every redirect in `progress.md` and tell the subtask agent
  the new path.
- A work item that contradicts a spec statement, collides with another change set (for example
  a migration number already claimed in the CHECKLIST notes), or needs something a pending
  change set would create is recorded in `progress.md` under "Work items with problems" with
  the resolution you chose (renumber, stub with a clear error, defer). Do not silently skip it.
- Always add a final **spec-sync** subtask covering every file on the `Spec impact:` line.
- Order: schema and config first, code next, reference apps and deploy files after, docs and
  build files after that, spec-sync last. Two subtasks may run in parallel only if their file sets do not overlap; run at most
  three at a time.

Write the plan into `progress.md` (not in `--dry-run`): subtask name, work items (verbatim),
files it may touch, depends-on, status `pending`.

## 6. Dispatch a subtask

Use the `Agent` tool with `subagent_type: general-purpose`. **Never use `fork`**: the point is
a fresh context that reads the plan and the spec from disk rather than inheriting this
conversation. Build the prompt from `subagent-prompt.md`, filling in: repo root, change-set id
and directory, the exact work items (verbatim checkboxes), the allowed file set, the spec files
to read, the verification commands relevant to those files, and the rules block. One subtask per
agent. Do not give an agent more than one group.

Before dispatching, set the subtask `running` in `progress.md` and, when the repository has no
commits, record a checksum snapshot of its allowed files (`shasum -a 256 <files> 2>/dev/null`;
missing files count as absent). While agents run, do nothing else with the working tree. When
an agent reports, go to step 7.

## 7. Integrate each result

1. Run the fast gates yourself: `gofmt -l .`, `go build ./...`, `go vet ./...`, and the unit
   tests of the packages the subtask touched (`go test ./<pkg>/...`). For TypeScript or Python
   subtasks run the example's `npm run build && npm test` or `uv run pytest` in that directory.
2. Run `python3 ~/.claude/skills/handle-change/check-spec.py` (spec rules and links) and
   `python3 ~/.claude/skills/handle-change/check-spec.py --code <touched files>` (forbidden
   references in code and comments). Both must report no findings; a finding is a defect to fix.
   This script is the only definition of a forbidden reference; do not invent a grep.
3. Check the agent's own report against the work items: every item it claims done must have a
   corresponding file change — `git diff --stat` when the repository has commits, otherwise
   compare the checksum snapshot from step 6.
4. Success → tick the boxes in `work-items.md` (`- [ ]` → `- [x]`), set the subtask `done` in
   `progress.md` with a one-line result, and dispatch the next runnable subtasks.
5. Failure → re-dispatch once with the failure output appended to the prompt. A second failure
   sets the subtask `failed` in `progress.md` with the error, and independent subtasks continue.
   A subtask whose failure blocks others makes those `blocked (by <subtask>)`.

## 8. Spec-sync subtask

Dispatch it only after every code subtask is `done` or `failed`, using `spec-sync-prompt.md`.
It may edit every file on the `Spec impact:` line, any `spec/*/decisions.md` that a decision in
the change set's `decisions.md` belongs to, and may create a new topic file when the new
behaviour has no home (it lists new files in its report; add them to the `Spec impact:` line).
It also receives the "Spec drift" notes from the subtask reports. Then run `check-spec.py`
yourself; it must report no findings.

## 9. Verify acceptance

Work through `verification.md`:

- Run every named test suite. For database- or Kafka-gated tests, start the throwaway
  container the suite documents (or `make up-core`), export the gating variable, run, tear down.
- For bench or chaos scenarios that the verification names as required, run them through the
  Makefile if Docker is available (`docker info` succeeds); otherwise record "not run: no
  Docker" — do not claim a result you did not observe.
- For each acceptance criterion in `overview.md`, record in `progress.md` **met** with the
  evidence (test name, measured number, file) or **unmet** with the reason.

## 10. Review pass

Dispatch one read-only subagent (`general-purpose`, prompt from `review-prompt.md`) with the
list of changed files, `design.md`, and the spec files. It reports defects ranked by severity:
correctness bugs, deviations from `design.md`, spec statements the code contradicts, forbidden
references, missing tests. Fix anything it confirms by dispatching a fix subtask (step 6/7).
Record the review outcome in `progress.md`.

## 11. Close out

- All work items ticked (cross-repo items may remain `pending (cross-repo)`), every acceptance
  criterion **met**, review clean → set the CHECKLIST row and `overview.md` to `done`, append a
  log line ("m-NN done: <one-line summary>; deferred: <cross-repo items or none>"), and note in
  `rollout.md` anything that must happen outside this repo (flag flips, Terraform rows, other
  repos) as a short "Remaining outside this repo" list.
- Otherwise leave `in-progress` and list precisely what remains in `progress.md`. If a hard
  blocker outside the repo stops all remaining work, set `blocked` and fill `Blocked by:`.
- Do not commit or push unless the user asked. If they did, one commit per change set with the
  message `m-NN: <title>`; the repo may be jj-colocated, so prefer the user's usual flow.

## 12. Report

Lead with the outcome (done / in-progress / blocked). Then: a table of subtasks with status and
one-line results; acceptance criteria met/unmet; spec files updated and their conformance
lines; anything deferred (cross-repo) or left for a human; the next change set the CHECKLIST
tracks suggest; when the outcome is `done`, that `/archive-change m-NN` archives it. Keep it
short; `progress.md` holds the detail.

## Rules that apply to every step

- Fresh context per subtask: `general-purpose` agents, never `fork`, never one agent for two
  groups, never do a subtask's work yourself except one-line fixes found in step 7.
- Do not widen scope. If a work item is wrong or impossible, record it in `progress.md` with the
  reason and move on; do not invent replacement work.
- Sibling repositories are read-only unless `--include-cross-repo` is present.
- Database migrations are additive-only, numbered, one concern per file.
- Code comments may cite `spec/<area>/<file>.md#heading`; never tickets, change sets, PRs,
  result files, dates or people.
- Do not edit `spec/` outside the spec-sync subtask, and never make the spec reference `changes/`.
- Ask the user only when the change set cannot be resolved or a hard dependency is not done.
