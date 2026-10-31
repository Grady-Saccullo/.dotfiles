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

local builtin = require("telescope.builtin")
local kmap = vim.keymap.set
kmap("n", "<leader>?", builtin.oldfiles, { desc = "[?] Find recently opened files" })
kmap("n", "<leader><space>", builtin.buffers, { desc = "[ ] Find existing buffers" })
kmap("n", "<leader>/", function()
	builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
		winblend = 10,
		previewer = false,
	}))
end, { desc = "[/] Fuzzily search in current buffer" })
kmap("n", "<leader>gf", builtin.git_files, { desc = "Search [G]it [F]iles" })
kmap("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
kmap("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
kmap("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
kmap("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
kmap("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
kmap("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
-- [END] telescope-nvim.lua --
