-- [START] octo.lua --
require("octo").setup({
	picker = "telescope",
	-- No devicons plugin is installed.
	file_panel = { icons = false },
	mappings = {
		-- <leader>q is the quickfix toggle.
		pull_request = { approve_pr = { lhs = "<localleader>pa", desc = "approve PR" } },
	},
})
-- [END] octo.lua --
