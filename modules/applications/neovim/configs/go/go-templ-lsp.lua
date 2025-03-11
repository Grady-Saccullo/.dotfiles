-- [START] go-templ-lsp.lua --
addLspServer("templ", {})

local templ_format = function()
	local bufnr = vim.api.nvim_get_current_buf()
	local filename = vim.api.nvim_buf_get_name(bufnr)
	local cmd = "templ fmt " .. vim.fn.shellescape(filename)

	vim.fn.jobstart(cmd, {
		on_exit = function()
			if vim.api.nvim_get_current_buf() == bufnr then
				vim.cmd("e!")
			end
		end,
	})
end
-- [END] go-templ-lsp.lua --
