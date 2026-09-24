# Spec-sync prompt template

Fill every `{{placeholder}}`. Send as the `prompt` of an `Agent` call with
`subagent_type: general-purpose` and a `description` such as `m-07: spec sync`. Dispatch only
after every code subtask of the change set is `done` or `failed`.

---

You are updating the normative specification after change set `{{change_id}}` changed the code
in the repository at `{{repo_root}}`. You start with no context; read before you write.

## Read first, in this order

1. `{{repo_root}}/spec/README.md` — the rules are binding: RFC 2119 language, present tense,
   a `Conformance:` line at the top of every topic file, numbered permanent decisions
   `<spec>-D<n>`, stable headings, no code, files under about 300 lines, and **no references to
   tickets, change sets, pull requests, dates, people, result files, or "the POC"**.
2. `{{repo_root}}/changes/{{change_dir}}/design.md` and `decisions.md` — what changed and why.
3. The spec files you own for this run:
{{spec_files_bulleted}}
4. The code that changed (read it; do not trust the change set to describe it):
{{changed_files_bulleted}}
5. Notes from the subtask agents about spec drift they noticed:
{{spec_drift_notes}}

## What to do

- For every spec file above, make the text describe the behaviour the code **now** has. Add
  or amend statements; remove statements that are no longer true. Keep headings stable; add a
  heading rather than renaming one.
- Set each `Conformance:` line truthfully by checking the code: `implemented`,
  `partial — <the gap in one sentence>`, or `not implemented`.
- For each decision in the change set's `decisions.md` that is a lasting design decision (not a
  scheduling or rollout choice), add a numbered entry to the right `spec/<area>/decisions.md`
  with **Context / Decision / Alternatives / Consequences**, in spec language (no change-set
  ids, no dates). If a decision reverses an existing one, add a new number that names the
  superseded one; never delete.
- If the new behaviour has no home in any existing topic file, create one under the right
  `spec/<area>/`, with a `Conformance:` line, and add it to that area's `overview.md` index.
  List every file you created in your report.
- Do not edit anything outside `spec/`. Do not edit `spec/README.md`.

## Verify before you report

Run `python3 ~/.claude/skills/handle-change/check-spec.py` from the repository root; it must print
`ok`. Fix any finding it reports.

## Report (this exact shape)

- **Files updated:** one line each — what changed and the new conformance line.
- **Files created:** path and one-line purpose (or "none").
- **Decisions added:** `<spec>-D<n> — title` for each.
- **Statements you could not reconcile:** spec text and code that still disagree, with the
  reason (the coordinator records these).
