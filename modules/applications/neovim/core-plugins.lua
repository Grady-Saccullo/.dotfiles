-- [START] core-plugins.lua --
-- Neovim's own pack/dist/opt plugins, loaded through lz.n like everything else.
require("lz.n").load({
	{
		"nvim.undotree",
		cmd = { "Undotree" },
		keys = { { "<leader>tu", "<cmd>Undotree<CR>", desc = "[T]oggle [U]ndotree" } },
	},
	{ "nvim.difftool", cmd = { "DiffTool" } },
})
-- [END] core-plugins.lua --
