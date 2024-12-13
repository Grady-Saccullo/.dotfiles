-- [START] telescope-nvim.lua --
local telescope = require("telescope")
telescope.setup({})
telescope.load_extension("file_browser")
telescope.load_extension("fzf")
-- [END] telescope-nvim.lua --
