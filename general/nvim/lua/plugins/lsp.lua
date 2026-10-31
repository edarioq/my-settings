-- Neovim leaves LSP file watching off on Linux. With inotifywait installed it works, so language
-- servers such as gopls see files that change outside the editor, such as git checkouts, generated
-- code and edits from other tools.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          capabilities = {
            workspace = {
              didChangeWatchedFiles = { dynamicRegistration = true },
            },
          },
        },
      },
    },
  },
}
