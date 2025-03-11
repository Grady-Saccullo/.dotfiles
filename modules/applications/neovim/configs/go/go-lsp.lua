addLspServer("gopls", {
	cmd = { "gopls", "serve" },
	root_dir = require("lspconfig").util.root_pattern("go.mod", ".git"),
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
})
