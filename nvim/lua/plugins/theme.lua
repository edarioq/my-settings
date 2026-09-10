return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      transparent_background = true, -- Core transparency setting
      -- `styles` in catppuccin means syntax styles; sidebars/floats are
      -- tokyonight options and were being ignored.
      float = { transparent = true, solid = false },
      integrations = {
        telescope = { enabled = true, style = "transparent" },
        neotree = true,
        which_key = true,
      },
      -- transparent_background leaves the cursor row filled so it stays
      -- visible. A terminal cannot blend a named background colour, so mark
      -- the row with an underline instead of a fill.
      custom_highlights = function(colors)
        local cursor_row = { bg = colors.none, underline = true, sp = colors.surface1 }
        return {
          CursorLine = cursor_row,
          NeoTreeCursorLine = cursor_row,
          CursorColumn = { bg = colors.none },
        }
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      -- Neovim 0.12 ships its own "catppuccin" scheme, which shadows the
      -- plugin and silently ignores every option above. Flavour-suffixed
      -- names only exist in the plugin.
      colorscheme = "catppuccin-mocha",
    },
  },
}
