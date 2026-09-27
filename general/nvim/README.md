# Neovim (LazyVim) with a transparent background

My `~/.config/nvim`. Works on any machine, including WSL.

## Install

Run `install.sh` from the repo root. It links `~/.config/nvim` to this folder.
lazy.nvim installs everything on first start.

To install only this config by hand, from the repo root:

```bash
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null
ln -s "$PWD/general/nvim" ~/.config/nvim
```

To pull the latest plugin versions instead of the ones pinned in
`lazy-lock.json`, delete that file before starting, or run `:Lazy update`.

## Transparency: how the pieces fit

Neovim cannot make itself see-through. It only declines to paint a background,
and the terminal's own opacity setting shows through the gap. So two things
have to be set, in two different places.

### 1. The terminal

| Terminal         | Setting                                        |
| ---------------- | ---------------------------------------------- |
| Windows Terminal | `"useAcrylic": true`, `"opacity": 80`          |
| WezTerm          | `window_background_opacity = 0.8`              |
| Alacritty        | `window.opacity = 0.8`                         |
| kitty            | `background_opacity 0.8`                       |
| iTerm2           | Profiles > Window > Transparency               |

In Windows Terminal this goes on the WSL profile, not on the top-level
defaults, unless you want it everywhere.

### 2. Neovim

`lua/plugins/theme.lua` holds all of it. The theme is
[gruvbox.nvim](https://github.com/ellisonleao/gruvbox.nvim) with hard contrast.
Two things in there are worth knowing:

**Clear the cursor row yourself.** `transparent_mode` deliberately keeps
`CursorLine` filled so the cursor stays findable. A terminal paints any named
background colour as solid, so there is no half-transparent option. Clear the
fill and mark the row some other way instead:

```lua
CursorLine = { bg = "NONE", underline = true, sp = palette.dark2 }
```

Drop `underline` and `sp` if you would rather the row carry no mark at all.

**Give pickers their own selection colour.** gruvbox points the selected row in
pickers at `CursorLine`, and the underline above is too faint there. Link it to
`Visual` instead:

```lua
SnacksPickerListCursorLine = { link = "Visual" }
TelescopeSelection = { link = "Visual" }
```

## What else is in here

- `lua/plugins/diagnostics.lua` shows the cursor line's errors below the line,
  wrapped to the window. Neovim's own version cuts off long messages near the
  right edge
- `lua/plugins/biome.lua` checks every supported file with
  [Biome](https://biomejs.dev), but only formats in projects that use Biome.
  It expects `biome` on `PATH` and does not install it through Mason
- `lua/plugins/neo-tree.lua` shows dotfiles and gitignored files in the tree
- `lua/plugins/remote-ssh.lua` adds [remote-nvim](https://github.com/amitds1997/remote-nvim.nvim)
  for editing on remote machines over SSH (`:RemoteStart`)
- `lazyvim.json` holds the language extras: Docker, Go, JSON, Markdown, SQL,
  Tailwind, TypeScript (vtsls, Biome)
- `lua/config/keymaps.lua` maps `Ctrl+j` / `Ctrl+k` to jump 10 lines down / up
  in normal mode. This replaces LazyVim's default of moving between windows
  with those keys (`Ctrl+w j` / `Ctrl+w k` still do that)
- The rest of `lua/config/` is unchanged from the LazyVim starter

## WSL notes

- A Nerd Font is needed for the icons. Install it on Windows and set it as the
  font in the Windows Terminal profile, not inside WSL.
- The language extras expect their toolchains on `PATH` in the WSL side: `node`
  for TypeScript and Tailwind, `go` for Go. Mason installs the servers, not the
  runtimes.
- Clipboard sharing with Windows works out of the box on WSL2 via `win32yank`,
  which Neovim finds on its own if it is on `PATH`.
