-- [START] nvim-treesitter.lua --

-- Treesitter highlighting via Neovim core
vim.api.nvim_create_autocmd("FileType", {
	callback = function(ev)
		pcall(vim.treesitter.start, ev.buf)
	end,
})
-- [END] nvim-treesitter.lua --
