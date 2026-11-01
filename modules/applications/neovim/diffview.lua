-- [START] diffview.lua --
require("diffview").setup({})

local kmap = vim.keymap.set
kmap("n", "<leader>vo", "<cmd>DiffviewOpen<CR>", { desc = "Git: Diff[v]iew [O]pen (index)" })
kmap("n", "<leader>vh", "<cmd>DiffviewFileHistory %<CR>", { desc = "Git: file [H]istory" })
kmap("n", "<leader>vH", "<cmd>DiffviewFileHistory<CR>", { desc = "Git: repo [H]istory" })
kmap("n", "<leader>vc", "<cmd>DiffviewClose<CR>", { desc = "Git: Diffview [C]lose" })
-- [END] diffview.lua --
