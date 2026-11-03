-- [START] diffview.lua --
-- Colocated repos detect as git first; jj gives revsets and change IDs in history.
require("diffview").setup({ preferred_adapter = "jj" })

local kmap = vim.keymap.set
kmap("n", "<leader>vo", "<cmd>DiffviewOpen<CR>", { desc = "Git: Diff[v]iew [O]pen (working copy)" })
kmap("n", "<leader>vh", "<cmd>DiffviewFileHistory %<CR>", { desc = "Git: file [H]istory" })
kmap("n", "<leader>vH", "<cmd>DiffviewFileHistory<CR>", { desc = "Git: repo [H]istory" })
kmap("n", "<leader>vc", "<cmd>DiffviewClose<CR>", { desc = "Git: Diffview [C]lose" })
-- [END] diffview.lua --
