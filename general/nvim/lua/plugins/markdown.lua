local markdownlint_config = vim.fn.stdpath("config") .. "/.markdownlint.yaml"

return {
  {
    -- The Markdown extra lists Prettier as a formatter but leaves installing
    -- it to the Prettier extra, which would also restyle JS and CSS.
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "prettier" } },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        prettier = {
          -- Prettier leaves long prose lines alone unless told to wrap them.
          -- prefer-file lets a project's own Prettier config win over this.
          prepend_args = { "--prose-wrap", "always", "--config-precedence", "prefer-file" },
        },
        ["markdownlint-cli2"] = {
          prepend_args = { "--config", markdownlint_config },
        },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        ["markdownlint-cli2"] = {
          prepend_args = { "--config", markdownlint_config },
        },
      },
    },
  },
}
