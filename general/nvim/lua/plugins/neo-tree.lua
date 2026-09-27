return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = true, -- Ensures hidden/ignored items can still be toggled or visible
        hide_dotfiles = false, -- Shows .env, .gitignore, etc.
        hide_gitignored = false, -- Shows files ignored by your .gitignore
      },
    },
  },
}
