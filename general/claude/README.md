# Claude Code

Global context and preferences for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

| File            | Goes to                    | What it is                                                        |
| --------------- | -------------------------- | ----------------------------------------------------------------- |
| `CLAUDE.md`     | `~/.claude/CLAUDE.md`      | Writing style and code commenting rules, loaded in every project |
| `standards/`    | nowhere                    | Project standards to copy into a project's `CLAUDE.md`           |
| `settings.json` | `~/.claude/settings.json`  | Model, effort level, theme, fullscreen TUI, no co-author trailer  |

`CLAUDE.md` is symlinked by `install.sh`. `settings.json` is
copied once and only if none exists, because Claude Code writes into it while
running and a symlink would push every machine-specific change back into the
repo. To pick up a newer version, copy it over by hand or diff the two.

`standards/backend.md` covers a NestJS API and `standards/frontend.md` an
Expo + React Native app. They are not loaded anywhere. When starting a project
of that kind, copy the relevant one into the project's `CLAUDE.md` or reference
it from there with `@path/to/file`.

Project-level context (`.claude/settings.local.json`, project `CLAUDE.md`
files) belongs in each project, not here. The `auto mode` environment block is
left out on purpose: it describes one private repo.
