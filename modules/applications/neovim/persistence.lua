-- [START] persistence.lua --
local persistence = require("persistence")
persistence.setup({})

local kmap = vim.keymap.set
kmap("n", "<leader>Ss", function()
	persistence.select()
end, { desc = "[S]ession [S]elect" })
kmap("n", "<leader>Sl", function()
	persistence.load()
end, { desc = "[S]ession [L]oad for cwd" })
kmap("n", "<leader>SL", function()
	persistence.load({ last = true })
end, { desc = "[S]ession load [L]ast" })
kmap("n", "<leader>Sd", function()
	persistence.stop()
end, { desc = "[S]ession [D]o not save on exit" })
-- [END] persistence.lua --
