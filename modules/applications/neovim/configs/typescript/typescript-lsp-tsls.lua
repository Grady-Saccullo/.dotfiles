addLspServer("ts_ls", {
	init_options = require("nvim-lsp-ts-utils").init_options,
	cmd = { "typescript-language-server", "--stdio" },
	on_attach = function(client, bufnr)
		local ts_util = require("nvim-lsp-ts-utils")
		ts_util.setup({ auto_inlay_hints = false })
		ts_util.setup_client(client)
		-- FIXME: we do not have access to lspconfig_custom_attach at this point... lua will error
		lspconfig_custom_attach(client, bufnr)
	end,
	root_dir = require("lspconfig").util.root_pattern(".git"),
})
