-- [START] conform.lua --
local conform = require("conform")

conform.setup({
	formatters_by_ft = {
		lua = { "stylua" },
		nix = { "alejandra" },
		python = { "ruff_format", "ruff_organize_imports" },
		sh = { "shfmt" },
		bash = { "shfmt" },
		swift = { "swiftformat" },
		templ = { "templ" },
		javascript = { "biome", "prettier", stop_after_first = true },
		typescript = { "biome", "prettier", stop_after_first = true },
		javascriptreact = { "biome", "prettier", stop_after_first = true },
		typescriptreact = { "biome", "prettier", stop_after_first = true },
		jsx = { "biome", "prettier", stop_after_first = true },
		tsx = { "biome", "prettier", stop_after_first = true },
		json = { "biome", "prettier", stop_after_first = true },
		jsonc = { "biome", "prettier", stop_after_first = true },
		css = { "biome", "prettier", stop_after_first = true },
		html = { "biome", "prettier", stop_after_first = true },
		yaml = { "yamlfmt" },
		markdown = { "prettier" },
	},
	format_on_save = function(bufnr)
		local autoformat = vim.b[bufnr].autoformat
		if autoformat == nil then
			autoformat = vim.g.autoformat
		end
		if not autoformat then
			return
		end
		return { timeout_ms = 500, lsp_format = "fallback" }
	end,
})

vim.api.nvim_create_user_command("Format", function()
	conform.format({ lsp_format = "fallback" })
end, { desc = "Format current buffer" })

vim.keymap.set("n", "<leader>f", function()
	conform.format({ lsp_format = "fallback" })
end, { desc = "LSP: [F]ormat" })

vim.keymap.set("n", "<leader>tf", function()
	local current = vim.b.autoformat
	if current == nil then
		current = vim.g.autoformat
	end
	vim.b.autoformat = not current
	print("Format-on-save: " .. (vim.b.autoformat and "enabled" or "disabled"))
end, { desc = "LSP: [T]oggle [F]ormat-on-save" })
-- [END] conform.lua --
