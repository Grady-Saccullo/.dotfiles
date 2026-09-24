# Review prompt template

Fill every `{{placeholder}}`. Send as the `prompt` of an `Agent` call with
`subagent_type: general-purpose`. The reviewer is read-only.

---

Read-only review of change set `{{change_id}}` in the repository at `{{repo_root}}`. Do not
edit any file. Do not run docker or make. You may run `go build ./...`, `go vet ./...`,
`gofmt -l .`, and `go test` on packages without external dependencies.

## Read first

1. `{{repo_root}}/changes/{{change_dir}}/design.md` — what the code should now look like.
2. `{{repo_root}}/changes/{{change_dir}}/work-items.md` — what was claimed done (ticked boxes).
3. `{{repo_root}}/spec/README.md` and these spec files, which the code must conform to:
{{spec_files_bulleted}}
4. The changed files:
{{changed_files_bulleted}}

Use `git diff` / `git status` in the repo to see the actual changes.

## Check, in this order

1. **Correctness.** Bugs, races, off-by-one on version comparisons, transactions that commit
   offsets before the database, error paths that can block a Kafka partition, migrations that
   are not additive.
2. **Design conformance.** Anything the diff does differently from `design.md` without a
   recorded deviation.
3. **Spec conformance.** Statements in the listed spec files that the code now contradicts,
   and `Conformance:` lines that are no longer truthful.
4. **Forbidden references.** Run
   `python3 ~/.claude/skills/handle-change/check-spec.py --code <changed files>` — it is the single
   definition (ticket ids, change-set ids, `changes/`, `docs/contract`, result files) and also
   resolves spec citations. Additionally read the comments for dates and people, which the
   script cannot detect.
5. **Tests.** Work items ticked without a test that exercises them; tests that are skipped
   unconditionally.
6. **Scope.** Files changed that no work item covers.

## Report

Findings ranked by severity, each with `file:line`, a one-line failure scenario, and the
minimal fix as a short diff or sentence. State explicitly for each of the six categories
whether you found nothing. No praise, no summary of what the change does.
