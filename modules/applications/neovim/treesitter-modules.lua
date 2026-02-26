-- [START] treesitter-modules.lua --
require("treesitter-modules").setup({
	incremental_selection = {
		enable = true,
		keymaps = {
			init_selection = "<C-space>",
			node_incremental = "<C-space>",
			scope_incremental = false,
			node_decremental = "<bs>",
		},
	},
})
-- [END] treesitter-modules.lua --
