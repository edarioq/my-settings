-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- LazyVim reloads files changed outside Neovim only when the terminal regains focus. Also
-- check on switching buffers and pausing, so edits from git or another tool show up without
-- leaving the terminal. Unmodified buffers reload silently (LazyVim turns on autoread);
-- buffers with unsaved changes still ask first.
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold" }, {
  group = vim.api.nvim_create_augroup("reload_changed_files", { clear = true }),
  callback = function()
    if vim.o.buftype == "" and vim.fn.getcmdwintype() == "" then
      vim.cmd("checktime")
    end
  end,
})

-- A stopped language server clears its diagnostics only from buffers it was still attached
-- to, so after a restart other buffers can keep its old errors. When a server attaches, drop
-- the diagnostics of earlier copies of it that are no longer running.
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("clear_stale_lsp_diagnostics", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      return
    end

    local running = {}
    for _, c in ipairs(vim.lsp.get_clients({ name = client.name })) do
      running[c.id] = true
    end

    -- Neovim names client namespaces "nvim.lsp.<server>.<client id>", plus a suffix for pull diagnostics.
    local prefix = "nvim.lsp." .. client.name .. "."
    for ns, info in pairs(vim.diagnostic.get_namespaces()) do
      if info.name:sub(1, #prefix) == prefix then
        local id = tonumber(info.name:sub(#prefix + 1):match("^%d+"))
        if id and not running[id] then
          vim.diagnostic.reset(ns)
        end
      end
    end
  end,
})
