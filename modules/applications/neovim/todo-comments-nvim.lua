-- [START] todo-comments-nvim.lua --
local oxocarbon = require("oxocarbon").oxocarbon
require("todo-comments").setup({
	signs = false,
	colors = {
		error = { oxocarbon.base12 },
		warning = { "#FDDC69" },
		info = { oxocarbon.base11 },
		hint = { oxocarbon.base13 },
		default = { oxocarbon.base15 },
		test = { oxocarbon.base07 },
	},
})
-- [END] todo-comments-nvim.lua --
