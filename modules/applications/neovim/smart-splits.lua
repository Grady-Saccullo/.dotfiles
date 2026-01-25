-- [START] smart-splits.lua --
require("smart-splits").setup({
	at_edge = "stop",
	multiplexer_integration = "wezterm",
})

-- Navigation keymaps (Ctrl + Arrow keys)
vim.keymap.set("n", "<C-Left>", require("smart-splits").move_cursor_left, { desc = "Move to left pane" })
vim.keymap.set("n", "<C-Down>", require("smart-splits").move_cursor_down, { desc = "Move to below pane" })
vim.keymap.set("n", "<C-Up>", require("smart-splits").move_cursor_up, { desc = "Move to above pane" })
vim.keymap.set("n", "<C-Right>", require("smart-splits").move_cursor_right, { desc = "Move to right pane" })

-- Resize keymaps (Ctrl + Shift + Arrow keys)
vim.keymap.set("n", "<C-S-Left>", require("smart-splits").resize_left, { desc = "Resize left" })
vim.keymap.set("n", "<C-S-Down>", require("smart-splits").resize_down, { desc = "Resize down" })
vim.keymap.set("n", "<C-S-Up>", require("smart-splits").resize_up, { desc = "Resize up" })
vim.keymap.set("n", "<C-S-Right>", require("smart-splits").resize_right, { desc = "Resize right" })

-- Split keymaps (matching wezterm: - for horizontal, = for vertical)
vim.keymap.set("n", "<leader>-", "<cmd>split<cr>", { desc = "Split horizontal" })
vim.keymap.set("n", "<leader>=", "<cmd>vsplit<cr>", { desc = "Split vertical" })

-- Zoom toggle (matching wezterm: leader + z)
vim.keymap.set("n", "<leader>z", function()
	if vim.t.zoomed then
		vim.cmd("tabclose")
		vim.t.zoomed = false
	else
		vim.cmd("tab split")
		vim.t.zoomed = true
	end
end, { desc = "Toggle zoom" })
-- [END] smart-splits.lua --
