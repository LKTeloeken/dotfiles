vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

vim.opt.clipboard = "unnamedplus"

-- Save with Ctrl+S (formatting runs on the BufWritePre autocmd, in plugins/prettier.lua)
vim.keymap.set({ "n", "v" }, "<C-s>", "<cmd>write<CR>", { desc = "Save file" })
vim.keymap.set("i", "<C-s>", "<Esc><cmd>write<CR>", { desc = "Save file" })
