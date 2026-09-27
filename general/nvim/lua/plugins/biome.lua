local function project_uses_biome(root)
  if vim.uv.fs_stat(root .. "/biome.json") or vim.uv.fs_stat(root .. "/biome.jsonc") then
    return true
  end
  local ok, package_json = pcall(vim.fn.readfile, root .. "/package.json")
  return ok and table.concat(package_json, "\n"):find('"@biomejs/biome"', 1, true) ~= nil
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        biome = {
          -- Already installed with Homebrew; don't let Mason add a second copy
          mason = false,
          -- nvim-lspconfig only starts Biome when the project has a biome.json
          -- or lists Biome in package.json. Check every supported file with
          -- Biome's defaults instead, the way the VS Code extension does.
          root_dir = function(bufnr, on_dir)
            local markers = { { "biome.json", "biome.jsonc" }, { "package.json" }, { ".git" } }
            on_dir(vim.fs.root(bufnr, markers) or vim.fn.getcwd())
          end,
          -- Format-on-save falls back to any LSP that can format, so without
          -- this Biome would restyle files in projects that never chose it.
          -- Biome announces formatting both at startup and again right after,
          -- so both places need the same check.
          on_init = function(client)
            if not project_uses_biome(client.root_dir) then
              client.server_capabilities.documentFormattingProvider = false
              client.server_capabilities.documentRangeFormattingProvider = false
            end
          end,
          handlers = {
            ["client/registerCapability"] = function(err, params, ctx)
              local client = vim.lsp.get_client_by_id(ctx.client_id)
              if client and not project_uses_biome(client.root_dir) then
                params.registrations = vim.tbl_filter(function(registration)
                  return not registration.method:lower():find("formatting")
                end, params.registrations)
              end
              return vim.lsp.handlers["client/registerCapability"](err, params, ctx)
            end,
          },
        },
      },
    },
  },
}
