-- [START] grug-far.lua --
local grug = require("grug-far")
grug.setup({})

vim.keymap.set("n", "<leader>sR", function()
	grug.open()
end, { desc = "[S]earch and [R]eplace (grug-far)" })
vim.keymap.set("x", "<leader>sR", function()
	grug.with_visual_selection()
end, { desc = "[S]earch and [R]eplace selection (grug-far)" })
-- [END] grug-far.lua --
