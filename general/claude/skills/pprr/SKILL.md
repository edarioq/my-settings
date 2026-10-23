---
name: pprr
description: Post chosen findings from the last /prr review as inline review comments on the pull request. Run only when the user types /pprr with finding numbers and notes.
argument-hint: <numbers with notes, e.g. 1, 3 (only the first issue), 6>
disable-model-invocation: true
---

# /pprr: post PR review comments

Selection: `$ARGUMENTS`

Items are numbers from the latest `/prr` list in this conversation, each with optional notes: "3 but mention only the first issue, not the second", "6 as a nit", "9 without code". A note overrides the finding. Typing `/pprr` is the go-ahead to post, so do not ask again.

## Steps

1. Find the latest `/prr` list in this conversation and its PR. If there is none, ask for the PR link and stop.
2. Parse the selection. If a number does not exist or a note is unclear, ask before posting anything.
3. Get the current head SHA (`gh pr view <n> --json headRefOid`). If it moved since `/prr`, re-check each chosen finding against the new code and say which changed.
4. Write each comment in the **Code Review Comments** style of `~/.claude/CLAUDE.md`, as short as possible and friendly. Read the exact lines at the head SHA before writing code:
   - A `suggestion` block must replace the anchored lines exactly, with the file's indentation. An empty `suggestion` block deletes them.
   - Otherwise use a language block with only the lines that change.
5. Anchor every comment on RIGHT-side lines inside a diff hunk. Read the hunk ranges from `gh pr diff <n>`. A multi-line comment needs `start_line`, `line`, `start_side` and `side`. When the problem is outside the diff, anchor on the nearest related changed line and name the real `file:line` in the text.
6. Build the payload with a script in the scratchpad, then post one review:

   ```bash
   gh api -X POST repos/<o>/<r>/pulls/<n>/reviews --input payload.json
   ```

   The payload has `commit_id` set to the head SHA, `event: "COMMENT"`, no `body`, and every comment in `comments`. Never approve or request changes unless asked.
7. Check the result: list the review's comments with `gh api repos/<o>/<r>/pulls/<n>/comments --paginate`, filtered by `pull_request_review_id`, and confirm each `path` and line.
8. Reply with the review link and one line per posted number. Name anything you changed, merged or skipped.
