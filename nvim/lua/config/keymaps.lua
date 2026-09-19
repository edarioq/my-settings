-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<C-j>", "10j", { desc = "Jump down 10 lines" })
vim.keymap.set("n", "<C-k>", "10k", { desc = "Jump up 10 lines" })
