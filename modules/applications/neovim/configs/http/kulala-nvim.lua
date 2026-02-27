require("kulala").setup({
  default_env = "dev",
})

vim.keymap.set("n", "<leader>kr", function() require("kulala").run() end, { desc = "Kulala run request" })
vim.keymap.set("n", "<leader>ka", function() require("kulala").run_all() end, { desc = "Kulala run all requests" })
vim.keymap.set("n", "<leader>ki", function() require("kulala").inspect() end, { desc = "Kulala inspect request" })
vim.keymap.set("n", "<leader>kc", function() require("kulala").copy() end, { desc = "Kulala copy as cURL" })
vim.keymap.set("n", "[r", function() require("kulala").jump_prev() end, { desc = "Kulala previous request" })
vim.keymap.set("n", "]r", function() require("kulala").jump_next() end, { desc = "Kulala next request" })
vim.keymap.set("n", "<leader>ke", function() require("kulala").set_selected_env() end, { desc = "Kulala select environment" })
