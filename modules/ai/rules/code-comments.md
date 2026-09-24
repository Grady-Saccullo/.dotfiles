# Code comments

**Hard limits: no line comment over 2 lines, no doc comment (JSDoc, godoc, docstring)
over 4.** Wanting more means the code needs renaming or restructuring instead.

**Do not match the comment density around you.** A file full of long explanatory comments
is legacy, not the target.

Comment only what the code cannot say: a non-obvious constraint, a decision that looks wrong
without context, an external quirk. One sentence for the reason (the *why*), never a
restatement of what the code does.

The counterfactual, the alternative you rejected and what would break belong in the commit
message or the PR description, where they are read once by someone deciding, rather than on
every future visit to the file.

Project documentation (a `CLAUDE.md`, a README) is the exception: recording *why* is its
job. Comments that assert a design the code does not have are a real source of production
failures, so prose that cannot drift out of step with code is worth keeping and prose sitting
next to code is worth moving.
