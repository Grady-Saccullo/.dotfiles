-- :Telescope loads the rest extension on first use.
vim.keymap.set("n", "<leader>rr", "<cmd>Rest run<cr>", { desc = "Run REST request" })
vim.keymap.set("n", "<leader>ro", "<cmd>Rest open<cr>", { desc = "Open REST result pane" })
vim.keymap.set("n", "<leader>re", "<cmd>Telescope rest select_env<cr>", { desc = "Select REST environment" })
require("which-key").add({ { "<leader>r", group = "rest" } })
