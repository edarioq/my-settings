-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<C-j>", "10j", { desc = "Jump down 10 lines" })
vim.keymap.set("n", "<C-k>", "10k", { desc = "Jump up 10 lines" })
vim.keymap.set("n", "<A-w>", function()
  Snacks.bufdelete()
end, { desc = "Close buffer" })

-- Like Cmd+Shift+L in VS Code: prefill a file-wide replace with the cursor
-- where the new text goes, so every match changes live while typing.
-- With a count, only this line and the lines below it change: 4<leader>r
-- covers four lines.
local function replace_in_file(text, whole_word)
  -- \V matches the text as written. Tabs are spelled out because a typed Tab
  -- would start command-line completion.
  local pattern = vim.fn.escape(text, [[/\]]):gsub("\n", [[\n]]):gsub("\t", [[\t]])
  if whole_word then
    pattern = [[\<]] .. pattern .. [[\>]]
  end
  local range = "%"
  if vim.v.count > 0 then
    range = ".,.+" .. math.min(vim.v.count - 1, vim.fn.line("$") - vim.fn.line("."))
  end
  -- <C-u> drops the range Neovim prefills after a count or a selection. The
  -- result is read as key notation, so a "<" from the text must not start a key name.
  return ":<C-u>" .. range .. [[s/\V]] .. pattern:gsub("<", "<lt>") .. "//g<Left><Left>"
end

vim.keymap.set("n", "<leader>r", function()
  local word = vim.fn.expand("<cword>")
  return replace_in_file(word, vim.fn.match(word, [[^\k\+$]]) == 0)
end, { expr = true, desc = "Replace word in file" })

vim.keymap.set("x", "<leader>r", function()
  local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() })
  return replace_in_file(table.concat(lines, "\n"))
end, { expr = true, desc = "Replace selection in file" })
