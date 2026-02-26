-- [START] nvim-lspconfig.lua --

local lspconfig_custom_attach = function(client, bufnr)
	local nmap = function(keys, func, desc)
		if desc then
			desc = "LSP: " .. desc
		end

		vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
	end

	local telescope = vim.F.npcall(require, "telescope.builtin")

	nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
	nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

	nmap("gd", telescope.lsp_definitions, "[G]oto [D]efinition")
	nmap("gr", telescope.lsp_references, "[G]oto [R]eferences")
	nmap("gI", telescope.lsp_implementations, "[G]oto [I]mplementation")
	nmap("<leader>D", telescope.lsp_type_definitions, "Type [D]efinition")
	nmap("<leader>ds", telescope.lsp_document_symbols, "[D]ocument [S]ymbols")
	nmap("<leader>ws", telescope.lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

	-- See `:help K` for why this keymap
	nmap("K", vim.lsp.buf.hover, "Hover Documentation")
	nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")

	-- Lesser used LSP functionality
	nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
	nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
	nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
	nmap("<leader>wl", function()
		print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
	end, "[W]orkspace [L]ist Folders")

end

for server, config in pairs(lsp_servers) do
	if type(config) ~= "table" then
		config = {}
	end

	local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

	local wrapped_on_attach = function(client, bufnr)
		lspconfig_custom_attach(client, bufnr)
		if config.on_attach then
			config.on_attach(client, bufnr)
		end
	end

	local meshed_config = vim.tbl_deep_extend("force", {
		on_attach = wrapped_on_attach,
		capabilities = capabilities,
	}, config)

	vim.lsp.enable(server)
	vim.lsp.config(server, meshed_config)
end
-- [END] nvim-lspconfig.lua --
