addLspServer("gopls", {
	settings = {
		gopls = {
			-- gofumpt runs through gopls formatting; conform has no Go entry on purpose.
			gofumpt = true,
			staticcheck = true,
			usePlaceholders = true,
			analyses = {
				shadow = true,
			},
			codelenses = {
				test = true,
			},
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
