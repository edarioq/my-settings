-- The SQL extra runs sqlfluff, which needs a dialect config that projects like gymboss don't have.
-- sqlc already checks their SQL, so keep the extra's highlighting and database tools without it.
local function without_sqlfluff(names)
  return vim.tbl_filter(function(name)
    return name ~= "sqlfluff"
  end, names or {})
end

return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = without_sqlfluff(opts.ensure_installed)
    end,
  },
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      for _, ft in ipairs({ "sql", "mysql", "plsql" }) do
        opts.linters_by_ft[ft] = without_sqlfluff(opts.linters_by_ft[ft])
      end
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      for _, ft in ipairs({ "sql", "mysql", "plsql" }) do
        opts.formatters_by_ft[ft] = without_sqlfluff(opts.formatters_by_ft[ft])
      end
    end,
  },
}
