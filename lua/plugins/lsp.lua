return {
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
