---
name: fprr
description: Validate chosen findings from the last /prr review and fix the ones that hold up, in the working tree. Run only when the user types /fprr with finding numbers and notes.
argument-hint: <numbers with notes, e.g. 1, 2, 3, 5, 8 (the first issue, not the second)>
disable-model-invocation: true
---

# /fprr: fix PR review findings

Selection: `$ARGUMENTS`

Items are numbers from the latest `/prr` list in this conversation, each with optional notes: "8 the first issue, not the second", "3 without a test". A note overrides the finding. Anything after the numbers is an extra instruction for the whole run. Typing `/fprr` is the go-ahead to edit, so do not ask again.

## Steps

1. Find the latest `/prr` list in this conversation and its PR. If there is none, ask for the PR link and stop.
2. Parse the selection. If a number does not exist or a note is unclear, ask before changing anything.
3. Make sure the working tree is the PR's head branch (`gh pr view <n> --json headRefName,headRefOid`). If it is another branch, run `gh pr checkout <n>` when the tree is clean. If the tree has uncommitted changes, say so and stop.
4. Validate each chosen finding against the current code. Read the lines and the code that calls them. A finding is valid when the problem it describes can happen. Leave it unfixed when the code shows it cannot happen, when it is already fixed, or when the fix would break something else, and say why.
5. Fix each valid finding with the smallest change that solves it. Match the surrounding code and follow `~/.claude/CLAUDE.md` for comments. Add or update a test when the project tests that code.
6. Run the project's checks that cover the changed files: tests, type check, lint. Fix anything the change broke.
7. Do not commit or push.
8. Reply with one line per number: **Fixed** with `file:line` and what changed, or **Not fixed** with the reason. Then the checks you ran and their result, and any you could not run.
