-- [START] flash.lua --
-- char/search modes are off: this plugin is key-lazy, so f/t and / would behave differently before and after the first jump.
require("flash").setup({
	modes = {
		char = { enabled = false },
		search = { enabled = false },
	},
})

local kmap = vim.keymap.set
kmap({ "n", "x", "o" }, "s", function()
	require("flash").jump()
end, { desc = "Flash jump" })
kmap({ "n", "x", "o" }, "S", function()
	require("flash").treesitter()
end, { desc = "Flash treesitter select" })
kmap("o", "r", function()
	require("flash").remote()
end, { desc = "Flash remote operator" })
kmap({ "o", "x" }, "R", function()
	require("flash").treesitter_search()
end, { desc = "Flash treesitter search" })
-- [END] flash.lua --
