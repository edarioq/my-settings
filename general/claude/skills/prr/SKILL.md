---
name: prr
description: Review a GitHub pull request from its link and list numbered findings in chat, posting nothing. Run only when the user types /prr <PR link>.
argument-hint: <PR link> [low|medium|high|xhigh|max]
disable-model-invocation: true
---

# /prr: review a pull request

Arguments: `$ARGUMENTS`. The first is the PR link or number; an optional second is the review effort. The user writes nothing else, so do not ask what to focus on.

## Steps

1. Read the owner, repo and number from the link. If the working directory is not a clone of that repo, say so and stop.
2. Gather context with `gh`:
   - the PR description, base branch and head SHA (`gh pr view <n> --json title,body,baseRefName,headRefName,headRefOid`);
   - every existing review thread, including the author's replies (`gh api repos/<o>/<r>/pulls/<n>/comments --paginate`);
   - for a stacked PR, the open PRs whose base is this PR's branch, and their descriptions.
3. Run the review by invoking the `code-review` skill with the PR number and the effort, if one was given. Wait for its result.
4. Check every finding against the code at the head SHA (`git show <sha>:<path>`). Leave a finding out when:
   - the author already answered it in a thread;
   - a later PR in the stack fixes it;
   - the PR description accepts it as a risk, for a reason that holds;
   - the code shows it is wrong or would not matter (for example, an event left out on purpose).
5. Reply in chat, following `~/.claude/CLAUDE.md`:
   - One sentence: whether the PR is ready and why.
   - The findings, numbered 1 to N across three groups: **Must fix**, **Should fix**, **Minor**. Each gets a bold short title, `file:line`, and one or two short sentences: what goes wrong, then the fix. Use a small good/bad code pair where it helps.
   - **Left out**: one line per dropped finding with the reason.
   - What was not run (tests, `arch:check`, and so on).
   - Last line: `Post with /pprr <numbers>.`

Post nothing to GitHub. The numbers are what `/pprr` refers to, so do not renumber later in the conversation.
