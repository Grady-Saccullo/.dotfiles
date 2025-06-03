-- [START] nvim-lspconfig.lua --

local function find_config_file(file_names, start_path)
	-- normalize the stop path, aka project root (cwd)
	local stop_dir = vim.fn.resolve(vim.fn.getcwd())
	local current_dir = start_path

	while current_dir ~= "/" and current_dir ~= "" do
		for _, file_name in ipairs(file_names) do
			local config_path = current_dir .. "/" .. file_name
			if vim.fn.filereadable(config_path) == 1 then
				return config_path, current_dir
			end
		end

		if vim.fn.resolve(current_dir) == stop_dir then
			break
		end

		-- move up a dir
		local parent_dir = vim.fn.fnamemodify(current_dir, ":h")

		if current_dir == parent_dir then
			break
		end

		current_dir = parent_dir
	end

	return nil, nil
end

local function has_config(file_names)
	-- attempt to find in root
	local root_config_path, root_config_dir = find_config_file(file_names, vim.fn.getcwd())
	if root_config_path ~= nil then
		return true, root_config_dir
	end

	-- if we didn't find in the config it is probably a mono repo
	-- traverse backwards from the current file until we find a valid config
	local traversal_config_path, traversal_config_dir = find_config_file(file_names, vim.fn.expand("%:p:h"))
	return traversal_config_path ~= nil, traversal_config_dir
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

			local biome_exists, biome_dir = has_config({ "biome.json", "biome.jsonc" })
			local prettier_exists, prettier_dir = has_config({
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
