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
	'nvim-java/nvim-java',
	{
		'neovim/nvim-lspconfig',
		config = function()
			require 'configs.lsp'
		end,
	},
	'williamboman/mason.nvim',
	'williamboman/mason-lspconfig.nvim',
	'folke/neodev.nvim',
	'jose-elias-alvarez/nvim-lsp-ts-utils',
	-- {
	-- 	'xbase-lab/xbase',
	-- 	build = 'make install',
	-- 	config = function()
	-- 		require('xbase').setup({})
	-- 	end
	-- },
	{
		'j-hui/fidget.nvim',
		opts = {},
	},
	{
		'ziglang/zig.vim',
		config = function()
			vim.g.zig_fmt_autosave = 0
		end,
	}
}
