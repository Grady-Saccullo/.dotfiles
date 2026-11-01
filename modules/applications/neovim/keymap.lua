-- [START] keymap.lua --
local kmap = vim.keymap.set

-- Diagnostic keymaps ([d / ]d / <C-W>d are core defaults) --
kmap("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
kmap("n", "<leader>xq", vim.diagnostic.setqflist, { desc = "Diagnostics to quickfix" })

kmap("n", "<Esc>", "<cmd>nohlsearch<CR>")
-- [END] keymap.lua --
