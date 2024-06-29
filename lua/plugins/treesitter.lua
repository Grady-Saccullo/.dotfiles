return {
	{
		'nvim-treesitter/nvim-treesitter',
		event = { 'BufReadPost', 'BufNewFile' },
		-- build = ':TSUpdate',

		-- IF NIX: setup tree sitter as dev so we can point
		-- it to ~/.local/share/nvim/nix/nvim-treesitter
		dev = true
	},
	'nvim-treesitter/nvim-treesitter-textobjects',
	'nvim-treesitter/nvim-treesitter-context'
}
