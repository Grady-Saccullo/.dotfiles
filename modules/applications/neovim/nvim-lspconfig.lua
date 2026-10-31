-- [START] nvim-lspconfig.lua --

local function telescope(picker)
	return function()
		require("lz.n").trigger_load("telescope.nvim")
		require("telescope.builtin")[picker]()
	end
end

local lspconfig_custom_attach = function(client, bufnr)
	local nmap = function(keys, func, desc)
		vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc and ("LSP: " .. desc) })
	end

	-- Core already maps grn, gra, grr, gri, grt, gO, K and insert <C-s>; telescope pickers ride the core keys.
	nmap("gd", telescope("lsp_definitions"), "[G]oto [D]efinition")
	nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
	nmap("grr", telescope("lsp_references"), "[G]oto [R]eferences")
	nmap("gri", telescope("lsp_implementations"), "[G]oto [I]mplementation")
	nmap("grt", telescope("lsp_type_definitions"), "[G]oto [T]ype definition")
	nmap("gO", telescope("lsp_document_symbols"), "Document symbols")
	nmap("<leader>ws", telescope("lsp_dynamic_workspace_symbols"), "[W]orkspace [S]ymbols")

	nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
	nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
	nmap("<leader>wl", function()
		print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
	end, "[W]orkspace [L]ist Folders")

	if client:supports_method("textDocument/inlayHint") then
		vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
		nmap("<leader>th", function()
			vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
		end, "[T]oggle inlay [H]ints")
	end
end

for server, config in pairs(lsp_servers) do
	if type(config) ~= "table" then
		config = {}
	end

	local wrapped_on_attach = function(client, bufnr)
		lspconfig_custom_attach(client, bufnr)
		if config.on_attach then
			config.on_attach(client, bufnr)
		end
	end

	vim.lsp.config(server, vim.tbl_deep_extend("force", { on_attach = wrapped_on_attach }, config))
	vim.lsp.enable(server)
end
-- [END] nvim-lspconfig.lua --
