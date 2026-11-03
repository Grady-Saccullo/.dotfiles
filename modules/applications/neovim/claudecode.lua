-- [START] claudecode.lua --
-- Claude Code runs in a wezterm pane, not inside Neovim: this only serves the IDE protocol it
-- connects to with `/ide`. Keep the plugin eager enough that the lockfile exists before then.
require("claudecode").setup({
	terminal = { provider = "none" },
	diff_opts = { open_in_new_tab = true },
})

local kmap = vim.keymap.set
kmap("x", "<leader>cs", "<cmd>ClaudeCodeSend<CR>", { desc = "[C]laude: [S]end selection" })
kmap("n", "<leader>cs", function()
	vim.cmd(vim.bo.filetype == "oil" and "ClaudeCodeTreeAdd" or "ClaudeCodeAdd %")
end, { desc = "[C]laude: [S]end file under cursor / current file" })
kmap("n", "<leader>cf", "<cmd>ClaudeCodeAdd %<CR>", { desc = "[C]laude: add current [F]ile" })
kmap("n", "<leader>ca", "<cmd>ClaudeCodeDiffAccept<CR>", { desc = "[C]laude: [A]ccept diff" })
kmap("n", "<leader>cd", "<cmd>ClaudeCodeDiffDeny<CR>", { desc = "[C]laude: [D]eny diff" })
kmap("n", "<leader>ci", "<cmd>ClaudeCodeStatus<CR>", { desc = "[C]laude: connection [I]nfo" })
-- [END] claudecode.lua --
