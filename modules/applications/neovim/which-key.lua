-- [START] which-key.lua --
local wk = require("which-key")
wk.setup({ preset = "helix" })
wk.add({
	{ "<leader>s", group = "search" },
	{ "<leader>h", group = "harpoon" },
	{ "<leader>v", group = "git" },
	{ "<leader>t", group = "test / toggle" },
	{ "<leader>w", group = "workspace" },
	{ "<leader>x", group = "diagnostics" },
	{ "<leader>d", group = "debug", mode = { "n", "v" } },
})
-- [END] which-key.lua --
