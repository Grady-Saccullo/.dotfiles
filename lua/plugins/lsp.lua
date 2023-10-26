return {
	{
		'neovim/nvim-lspconfig',
		config = function()
			require('stuffs.lsp')
		end,
	},
	'williamboman/mason.nvim',
	'williamboman/mason-lspconfig.nvim',
	'folke/neodev.nvim',
	'jose-elias-alvarez/nvim-lsp-ts-utils'
}
