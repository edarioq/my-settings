# Neovim (LazyVim) with a transparent background

Copy of `~/.config/nvim`. Drop it in place on any machine, including WSL.

## Install

```bash
# back up anything already there
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null

mkdir -p ~/.config/nvim
cp -r nvim/. ~/.config/nvim/
nvim   # lazy.nvim installs everything on first start
```

First start also recompiles the catppuccin cache, so it takes an extra moment.

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

`lua/plugins/theme.lua` holds all of it. Three things in there are easy to get
wrong, so they are worth knowing:

**Use a flavour-suffixed colorscheme name.** Neovim 0.12 ships its own
`catppuccin` scheme in `$VIMRUNTIME/colors/`. Asking for the bare name loads
that one, the plugin never loads, and every option below is silently ignored.

```lua
colorscheme = "catppuccin"        -- loads Neovim's built-in scheme
colorscheme = "catppuccin-mocha"  -- loads the plugin
```

**Floats have their own option.** `styles.sidebars` and `styles.floats` belong
to tokyonight. In catppuccin, `styles` means syntax styles.

```lua
styles = { floats = "transparent" }        -- ignored
float = { transparent = true }             -- works
```

**Clear the cursor row yourself.** `transparent_background` deliberately keeps
`CursorLine` filled so the cursor stays findable, and neo-tree's selected file
inherits from it. A terminal paints any named background colour as solid, so
there is no half-transparent option. Clear the fill and mark the row some other
way instead:

```lua
local cursor_row = { bg = colors.none, underline = true, sp = colors.surface1 }
```

Drop `underline` and `sp` if you would rather the row carry no mark at all.
`Visual` and `Pmenu` keep their backgrounds on purpose, so selections and the
completion menu stay readable.

## What else is in here

- `lua/plugins/neo-tree.lua` shows dotfiles and gitignored files in the tree
- `lazyvim.json` holds the language extras: Docker, Go, JSON, Markdown, SQL,
  Tailwind, TypeScript (vtsls)
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
