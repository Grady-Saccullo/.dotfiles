-- [START] harpoon.lua --
local harpoon = require("harpoon")

harpoon:setup({
	settings = {
		save_on_toggle = true,
		sync_on_ui_close = true,
	},
})

-- Highlight the current file in the quick menu
harpoon:extend(require("harpoon.extensions").builtins.highlight_current_file())

-- Open in split/vsplit from within the quick menu
harpoon:extend({
	UI_CREATE = function(cx)
		vim.keymap.set("n", "<C-v>", function()
			harpoon.ui:select_menu_item({ vsplit = true })
		end, { buffer = cx.bufnr })
		vim.keymap.set("n", "<C-x>", function()
			harpoon.ui:select_menu_item({ split = true })
		end, { buffer = cx.bufnr })
	end,
})

-- Telescope picker for harpoon list
local conf = require("telescope.config").values
local function toggle_telescope(harpoon_files)
	local file_paths = {}
	for _, item in ipairs(harpoon_files.items) do
		table.insert(file_paths, item.value)
	end
	require("telescope.pickers")
		.new({}, {
			prompt_title = "Harpoon",
			finder = require("telescope.finders").new_table({ results = file_paths }),
			previewer = conf.file_previewer({}),
			sorter = conf.generic_sorter({}),
		})
		:find()
end

local kmap = vim.keymap.set

kmap("n", "<leader>ha", function()
	harpoon:list():add()
end, { desc = "[H]arpoon [A]dd file" })
kmap("n", "<leader>hs", function()
	harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = "[H]arpoon [S]how quick menu" })
kmap("n", "<leader>hf", function()
	toggle_telescope(harpoon:list())
end, { desc = "[H]arpoon [F]ind via telescope" })

kmap("n", "<leader>h1", function()
	harpoon:list():select(1)
end, { desc = "[H]arpoon slot [1]" })
kmap("n", "<leader>h2", function()
	harpoon:list():select(2)
end, { desc = "[H]arpoon slot [2]" })
kmap("n", "<leader>h3", function()
	harpoon:list():select(3)
end, { desc = "[H]arpoon slot [3]" })
kmap("n", "<leader>h4", function()
	harpoon:list():select(4)
end, { desc = "[H]arpoon slot [4]" })

kmap("n", "[h", function()
	harpoon:list():prev()
end, { desc = "[H]arpoon previous" })
kmap("n", "]h", function()
	harpoon:list():next()
end, { desc = "[H]arpoon next" })
-- [END] harpoon.lua --
