-- [START] telescope-nvim.lua --
local telescope = require("telescope")
telescope.setup({
	defaults = {
		file_sorter = require("telescope.sorters").get_fuzzy_file,
		generic_sorter = require("telescope.sorters").get_generic_fuzzy_sorter,
	},
	extensions = {
		fzf = {
			fuzzy = true,
			override_generic_sorter = true,
			override_file_sorter = true,
			case_mode = "smart_case",
		},
		["ui-select"] = {
			require("telescope.themes").get_dropdown(),
		},
	},
})
telescope.load_extension("fzf")
telescope.load_extension("ui-select")
-- [END] telescope-nvim.lua --
