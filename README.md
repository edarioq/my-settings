# Settings to share between my machines

## Install on a new machine

```bash
git clone git@github.com:edarioq/my-settings.git ~/Development/my-settings
~/Development/my-settings/install.sh
```

The script links each config into place, so editing a file in either spot
edits the repo. Anything already there is moved to `<name>.bak.<timestamp>`.
It is safe to run again.

On macOS it first installs the tools in `macos/Brewfile` (needs
[Homebrew](https://brew.sh)). On Ubuntu and other apt systems it installs the
ones in `ubuntu/packages.txt` and makes zsh the login shell. Ubuntu 22.04 ships a Neovim too old
for LazyVim; the script says so and you install a newer one from the
[releases page](https://github.com/neovim/neovim/releases). The Nerd Font and
[Biome](https://biomejs.dev/guides/manual-installation) are manual steps on
Linux. The shell config skips any tool that is missing.

Secrets stay out of this repo. Put them in `~/.zshrc.local`, which `.zshrc`
loads when it exists:

```bash
export CODERABBIT_API_KEY="..."
```

## What is in here

```
general/   used on every machine
macos/     macOS only
ubuntu/    Ubuntu only
windows/   Windows only
```

### `general/`

| Folder      | Goes to                                  | Notes                                             |
| ----------- | ---------------------------------------- | ------------------------------------------------- |
| `zsh/`      | `~/.zshrc`, `~/.zprofile`                | History, completion, key bindings, `gg-review`    |
| `starship/` | `~/.config/starship.toml`                | Prompt, Gruvbox colors                            |
| `tmux/`     | `~/.config/tmux`                         | [Plain tmux with the Oh my tmux key bindings and status bar](general/tmux/README.md) |
| `nvim/`     | `~/.config/nvim`                         | [LazyVim, Gruvbox, transparent background](general/nvim/README.md) |
| `vim/`      | `~/.vimrc`                               | Plain Vim with the Dracula theme                  |
| `git/`      | `~/.config/git/ignore`, included from `~/.gitconfig` | Name, email, global ignore            |
| `kitty/`    | `~/.config/kitty/`                       | Opacity, blur, CaskaydiaCove Nerd Font, Gruvbox Dark Hard |
| `claude/`   | `~/.claude/`                             | [Global CLAUDE.md, settings, project standards](general/claude/README.md) |
| `vscode/`   | VS Code user folder                      | Shared `settings.json`, [details and Windows steps](general/vscode/README.md) |

### `macos/`

| Item        | Goes to                                  | Notes                                             |
| ----------- | ---------------------------------------- | ------------------------------------------------- |
| `Brewfile`  | nowhere                                  | Tools that `install.sh` installs with Homebrew    |
| `borders/`  | `~/.config/borders/bordersrc`            | Window border colors                              |
| `vscode/`   | VS Code user folder                      | `keybindings.json` with cmd keys                  |

### `ubuntu/`

| Item           | Goes to                               | Notes                                             |
| -------------- | ------------------------------------- | ------------------------------------------------- |
| `packages.txt` | nowhere                               | Tools that `install.sh` installs with `apt`       |

Ubuntu uses the VS Code keybindings in `windows/`, because the keys are the same.

### `windows/`

| Item        | Goes to                                  | Notes                                             |
| ----------- | ---------------------------------------- | ------------------------------------------------- |
| `vscode/`   | `%APPDATA%\Code\User\`                   | `keybindings.json` with ctrl and win keys         |

Windows itself is not covered by `install.sh`. Follow the
[VS Code README](general/vscode/README.md) there.
