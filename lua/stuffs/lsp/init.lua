local neodev = vim.F.npcall(require, "neodev")
if neodev then
	neodev.setup({})
end

local lspconfig = vim.F.npcall(require, "lspconfig")
if not lspconfig then
	print("lspconfig nil!")
	return
end

local telescope = vim.F.npcall(require, "telescope.builtin")
if not telescope then
	print("telescope nil!")
	return
end

local custom_attach = function(client, bufnr)
	if client.name == "copilot" then
		return
	end

	local nmap = function(keys, func, desc)
		if desc then
			desc = 'LSP: ' .. desc
		end

		vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
	end

	nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
	nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

	nmap('gd', telescope.lsp_definitions, '[G]oto [D]efinition')
	nmap('gr', telescope.lsp_references, '[G]oto [R]eferences')
	nmap('gI', telescope.lsp_implementations, '[G]oto [I]mplementation')
	nmap('<leader>D', telescope.lsp_type_definitions, 'Type [D]efinition')
	nmap('<leader>ds', telescope.lsp_document_symbols, '[D]ocument [S]ymbols')
	nmap('<leader>ws', telescope.lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

	-- See `:help K` for why this keymap
	nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
	nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

	-- Lesser used LSP functionality
	nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
	nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
	nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
	nmap('<leader>wl', function()
		print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
	end, '[W]orkspace [L]ist Folders')


	vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
		vim.lsp.buf.format()
	end, { desc = 'Format current buffer with LSP' })

	nmap('<leader>f', function()
		if client.name == 'sourcekit' then
			vim.cmd('Neoformat swiftformat')
		elseif client.name == 'tsserver' then
			vim.cmd('Neoformat prettier')
		else
			vim.lsp.buf.format()
		end
	end, '[F]ormat')
end


local servers = {
	bashls = {},
	lua_ls = {
		Lua = {
			workspace = { checkThirdParty = false },
			telemetry = { enable = false },
		},
	},
	tsserver = {
		init_options = require('nvim-lsp-ts-utils').init_options,
		cmd = { 'typescript-language-server', '--stdio' },
		on_attach = function(client, bufnr)
			local ts_util = require("nvim-lsp-ts-utils")
			ts_util.setup({ auto_inlay_hints = false })
			ts_util.setup_client(client)

			custom_attach(client, bufnr)
		end,
		root_dir = lspconfig.util.root_pattern('.git')
	},
	gopls = {
		cmd = { 'gopls', 'serve' },
		root_dir = lspconfig.util.root_pattern('go.mod', '.git'),
		settings = {
			gopls = {
				hints = {
					assignVariableTypes = true,
					compositeLiteralFields = true,
					compositeLiteralTypes = true,
					constantValues = true,
					functionTypeParameters = true,
					parameterNames = true,
					rangeVariableTypes = true,
				},
			},
		},
	},
	yamlls = {},
	pyright = {},
	html = {},
	cssls = {},
	ocamllsp = {},
	angularls = {},
	jdtls = {},
	sqlls = {
		root_dir = function()
			return vim.loop.cwd()
		end,
		cmd = { 'sql-language-server', 'up', '--method', 'stdio', '-d', 'true' },
	},
	sourcekit = {
		-- cmd = { '/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp' },
		cmd = {
			'xcrun',
			'sourcekit-lsp',
			'--log-level',
			'debug',
		},
		root_dir = lspconfig.util.root_pattern('*.xcodeproj', '*.xcworkspace', 'Package.swift', '.git', 'project.yml'),
	}
}

require('mason').setup()
require('mason-lspconfig').setup({
	ensure_installed = { 'lua_ls', 'bashls', 'sqlls' }
})

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

local setup_server = function(server, config)
	if not config then
		print("oh no... missing config")
		return
	end

	if type(config) ~= "table" then
		config = {}
	end

	local meshed_config = vim.tbl_deep_extend("force", {
		on_attach = custom_attach,
		capabilities = capabilities,
	}, config)

	lspconfig[server].setup(meshed_config)
end

for server, config in pairs(servers) do
	setup_server(server, config)
end


vim.filetype.add {
	extension = {
		zsh = 'sh',
		sh = 'sh',
	},
	filename = {
		['.zshrc'] = 'sh',
		['.zshenv'] = 'sh',
		['.zsh'] = 'sh',
	}
}

return {
	on_attach = custom_attach,
	capabilities = capabilities,
}
