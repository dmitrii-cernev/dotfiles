-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("n", "<leader>fg", function()
  Snacks.picker.grep()
end, { desc = "Grep" })

-- vim.keymap.set("n", "<leader>ad", ":Copilot disable<CR>", { desc = "Disable Copilot" })
-- vim.keymap.set("n", "<leader>ae", ":Copilot enable<CR>", { desc = "Enable Copilot" })
