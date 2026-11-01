-- [START] quicker.lua --
local quicker = require("quicker")

quicker.setup({
	keys = {
		{
			">",
			function()
				quicker.expand({ before = 2, after = 2, add_to_existing = true })
			end,
			desc = "Expand quickfix context",
		},
		{
			"<",
			function()
				quicker.collapse()
			end,
			desc = "Collapse quickfix context",
		},
	},
})

vim.keymap.set("n", "<leader>q", function()
	quicker.toggle()
end, { desc = "Toggle [Q]uickfix" })
vim.keymap.set("n", "<leader>Q", function()
	quicker.toggle({ loclist = true })
end, { desc = "Toggle loclist" })
-- [END] quicker.lua --
