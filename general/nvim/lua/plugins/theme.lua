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
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
}
