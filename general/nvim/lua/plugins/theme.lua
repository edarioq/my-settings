return {
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    opts = function()
      local palette = require("gruvbox").palette
      return {
        contrast = "hard",
        transparent_mode = true,
        -- transparent_mode leaves the cursor row filled so it stays visible.
        -- A terminal cannot blend a named background colour, so mark the row
        -- with an underline instead of a fill.
        overrides = {
          CursorLine = { bg = "NONE", underline = true, sp = palette.dark2 },
          CursorColumn = { bg = "NONE" },
          -- bufferline's tabs have no background in transparent mode, so
          -- Neovim fills them with TabLineFill, which gruvbox keeps solid.
          TabLineFill = { bg = "NONE" },
          -- Same for the parts of lualine that have no fill.
          StatusLine = { bg = "NONE" },
          StatusLineNC = { bg = "NONE" },
          -- gruvbox points picker selections at CursorLine, which the
          -- underline above makes too faint; Visual is what snacks uses
          -- when no theme overrides it.
          SnacksPickerListCursorLine = { link = "Visual" },
          TelescopeSelection = { link = "Visual" },
        },
      }
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- Only the mode and branch blocks keep a fill; the middle of the bar
      -- shows the terminal through. Some modes use black text there, which
      -- is unreadable without a fill, so every mode gets the normal gray.
      local theme = vim.deepcopy(require("lualine.themes.gruvbox"))
      for _, mode in pairs(theme) do
        mode.c = { fg = require("gruvbox").palette.light4, bg = "NONE" }
      end
      opts.options.theme = theme
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
}
