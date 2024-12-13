-- [START] highlight.lua --
local yank_highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank()
	end,
	group = yank_highlight_group,
	pattern = "*",
})
-- [END] highlight.lua --
