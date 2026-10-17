return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        -- nvim-lint picks golangci-lint's target from Neovim's cwd. In a monorepo
        -- opened at the root there is no go.mod there, so it lints the lone file,
        -- which fails to load the standard library. Lint the file's package from
        -- inside its own module instead.
        golangcilint = function()
          local linter = vim.deepcopy(require("lint.linters.golangcilint"))
          local root = vim.fs.root(0, "go.mod")
          if root and linter.args then
            linter.cwd = root
            linter.args[#linter.args] = function()
              return vim.fn.expand("%:p:h")
            end
          end
          return linter
        end,
      },
    },
  },
}
