-- The module walker otherwise crawls node_modules in monorepos and logs every directory to stderr.
addLspServer("terraformls", {
	settings = {
		["terraform-ls"] = {
			indexing = { ignoreDirectoryNames = { "node_modules", "vendor", "dist", "build", ".next" } },
		},
	},
})
