-- [START] nvim-lspconfig.lua --

local function find_dir_with_files(file_names, bufnr)
	local fname = vim.api.nvim_buf_get_name(bufnr)
	local root_dir = vim.fs.dirname(vim.fs.find(file_names, { path = fname, upward = true })[1])
	return root_dir ~= nil, root_dir
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
			local function run_neoformat(cmd, config_dir)
				local og_cwg = vim.fn.getcwd()
				vim.cmd("cd " .. vim.fn.fnameescape(config_dir))
				vim.cmd("Neoformat " .. cmd)
				vim.cmd("cd " .. vim.fn.fnameescape(og_cwg))
			end

			local biome_exists, biome_dir = find_dir_with_files({ "biome.json", "biome.jsonc" })
			local prettier_exists, prettier_dir = find_dir_with_files({
				".prettierrc",
				".prettierrc.json",
				".prettierrc.yml",
				".prettierrc.yaml",
				".prettierrc.js",
				"prettier.config.js",
			})

			if biome_exists then
				run_neoformat("biome", biome_dir)
			elseif prettier_exists then
				run_neoformat("prettier", prettier_dir)
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
