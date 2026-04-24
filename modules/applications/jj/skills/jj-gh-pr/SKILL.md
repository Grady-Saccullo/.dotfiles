---
name: jj-gh-pr
description: Opens GitHub PRs from jj bookmarks in jj-colocated repos. Triggers when the user asks to open or create a PR. Takes bookmark names as args; falls back to the bookmark at `@`.
---

# jj-gh-pr

Open a GitHub PR for each target jj bookmark against the repository's default branch. One PR per bookmark.

## Preconditions

Run these before doing anything else. If any fails, report the failure verbatim and stop.

1. `test -d .jj` — the working directory must be a jj repository.
2. `gh auth status` — the user must be authenticated with GitHub CLI.
3. `jj git fetch` — refresh remote bookmark state so local decisions reflect origin.

## Determine target bookmarks

- If the user provided bookmark name(s) as arguments, use those names.
- Otherwise, run `jj bookmark list -r @` to find bookmark(s) at the working-copy commit.
  - Exactly one → use it.
  - More than one → ask the user which to PR.
  - Zero → run `jj bookmark list` to show candidates and ask the user which bookmark(s) to PR.

## For each target bookmark

1. **Ensure the bookmark is on origin.** Run `jj bookmark list <name>`. If no `<name>@origin` line appears, push it:

   ```
   jj git push -b <name>
   ```

   If the push fails, surface the error verbatim and stop — do not retry blindly.

2. **Check for an existing open PR.** Run `gh pr list --head <name> --state open --json number,url`. If one already exists, skip creation and report the existing URL. Do not open duplicates.

3. **Inspect the commit:**
   - Title: first line of `jj log -r <name> -T description --no-graph`.
   - Diff: `jj diff -r <name>`. Read it to understand what changed.

4. **Draft the PR body** with exactly two sections:
   - `## Summary` — 1–3 bullets describing what changed and why, derived from the commit description and the diff.
   - `## Test plan` — actionable checks a reviewer can run (rebuild commands, manual verifications, expected outputs).

5. **Create the PR.** Always pass `--head` explicitly — in jj-colocated repos, `git HEAD` often does not match the bookmark, so omitting `--head` can push the wrong branch. Do NOT pass `--base`; `gh` will target the repository's default branch automatically (this is what the user wants, and avoids guessing the trunk name):

   ```
   gh pr create \
     --head <bookmark> \
     --title "<title>" \
     --body "$(cat <<'EOF'
   ## Summary
   - <bullet>

   ## Test plan
   - [ ] <check>
   EOF
   )"
   ```

   Use a single-quoted `'EOF'` heredoc so shell expansion inside the body is suppressed.

6. Capture and record the returned PR URL.

## Report

After processing all bookmarks, print a summary with one line per bookmark showing its PR URL (or the existing URL if the PR already existed, or a clear failure reason if creation failed).

## Guardrails

- Do NOT rebase, amend, squash, or reorder commits unless the user explicitly asks. The jj history is how the user wants it.
- Do NOT open draft PRs unless the user explicitly asks.
- Do NOT run `git push` directly — always use `jj git push` so jj's bookmark tracking stays in sync.
- Do NOT modify files, create commits, or run `jj new` / `jj describe` / `jj bookmark set` as part of this flow. If something looks off (empty description, missing bookmark, bookmark far behind trunk), surface the issue and ask the user how to proceed.
- If `gh pr create` output (or a follow-up `gh pr view`) indicates the bookmark is behind the default branch or the merge state is `BEHIND`/`DIRTY`, relay that to the user rather than silently moving on.
