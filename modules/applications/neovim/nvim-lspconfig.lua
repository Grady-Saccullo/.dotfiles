-- [START] nvim-lspconfig.lua --

local function has_config(file_names)
	local root_dir = vim.fn.getcwd()

	for _, file_path in ipairs(file_names) do
		if vim.fn.filereadable(root_dir .. "/" .. file_path) == 1 then
			return true
		end
	end
	return false
end

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

	vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
		vim.lsp.buf.format()
	end, { desc = "Format current buffer with LSP" })

	nmap("<leader>f", function()
		if vim.bo.filetype == "templ" then
			templ_format()
			return
		end

		if client.name == "sourcekit" then
			vim.cmd("Neoformat swiftformat")
		elseif client.name == "vtsls" then
			local biome = has_config({ "biome.json", "biome.jsonc" })
			local prettier = has_config({
				".prettierrc",
				".prettierrc.json",
				".prettierrc.yml",
				".prettierrc.yaml",
				".prettierrc.js",
				"prettier.config.js",
			})

			if biome then
				vim.cmd("Neoformat biome")
			elseif prettier then
				vim.cmd("Neoformat prettier")
			else
				print("missing js/ts formatter...")
			end
		elseif client.name == "lua_ls" then
			vim.cmd("Neoformat stylua")
		elseif client.name == "nil_ls" then
			vim.cmd("Neoformat alejandra")
		else
			vim.lsp.buf.format()
		end
	end, "[F]ormat")
end

local lspconfig_setup_server = function(server, config)
	if not config then
		print("oh no... missing config")
		return
	end

	if type(config) ~= "table" then
		config = {}
	end

	local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())
	local lspconfig = vim.F.npcall(require, "lspconfig")

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

	lspconfig[server].setup(meshed_config)
end

for server, config in pairs(lsp_servers) do
	lspconfig_setup_server(server, config)
end
-- [END] nvim-lspconfig.lua --
