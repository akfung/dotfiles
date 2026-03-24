-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set({ "v", "n" }, "<C-d>", "<C-d>zz")
vim.keymap.set({ "v", "n" }, "<C-u>", "<C-u>zz")
vim.keymap.set({ "n", "v" }, "<leader>yf", function()
    local filepath = vim.fn.expand("%:p")
    vim.fn.setreg("+", filepath)
    vim.notify("Copied full path: " .. filepath, vim.log.levels.INFO)
  end, { desc = "Yank full file path" })
vim.keymap.set({ "n", "v" }, "<leader>yr", function()
    local filepath = vim.fn.expand("%")
    vim.fn.setreg("+", filepath)
    vim.notify("Copied relative path: " .. filepath, vim.log.levels.INFO)
  end, { desc = "Yank relative file path" })
