return {
	{
		"rcarriga/nvim-dap-ui",
		dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
		opts = {
			layouts = {
				{
					elements = {
						{
							id = "breakpoints",
							size = 0.3
						},
						{
							id = "repl",
							size = 0.3
						},
						{
							id = "console",
							size = 0.4
						}
					},
					position = "bottom",
					size = 15
				}
			},
		},
	},
	{ 'leoluz/nvim-dap-go', opts = {} }
}
