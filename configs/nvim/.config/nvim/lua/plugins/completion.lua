return {
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-nvim-lua",
			"hrsh7th/cmp-nvim-lsp",
			"onsails/lspkind.nvim",
			{
				"L3MON4D3/LuaSnip",
				version = "v2.*",
				build = "make install_jsregexp"
			},
			"saadparwaiz1/cmp_luasnip"
		},
		config = function()
			require "configs.completion"
		end,
		-- { "tamago324/cmp-zsh" },
	}
}
