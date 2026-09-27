# VS Code

`settings.json` is shared. Nothing in it is platform-specific any more, so
it lives here in `general/vscode/`. Keybindings do differ, so those live in
`macos/vscode/` and `windows/vscode/` at the repo root. Linux uses the Windows
ones.

## Where the files go

| Platform          | User settings directory                       |
| ----------------- | --------------------------------------------- |
| macOS             | `~/Library/Application Support/Code/User/`    |
| Windows           | `%APPDATA%\Code\User\`                        |
| Linux             | `~/.config/Code/User/`                        |

On Windows with WSL, VS Code itself runs on the Windows side, so these go in
`%APPDATA%\Code\User\`, not anywhere inside WSL. Only the language servers and
tools run in WSL, through the Remote-WSL extension.

On macOS and Linux, `install.sh` in the repo root links these for you. By hand,
from the repo root:

```bash
# macOS
cp general/vscode/settings.json  ~/Library/Application\ Support/Code/User/
cp macos/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
```

```powershell
# Windows
copy general\vscode\settings.json    "$env:APPDATA\Code\User\"
copy windows\vscode\keybindings.json "$env:APPDATA\Code\User\keybindings.json"
```

## Extensions these settings expect

- `biomejs.biome` formats JS, JSON, JSONC, TSX, Docker Compose and GitHub
  Actions workflows
- Catppuccin Mocha theme and its icon theme, matching the Neovim config
- `streetsidesoftware.code-spell-checker` reads the `cSpell.words` list
