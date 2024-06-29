local parsers_path = vim.g.treesitter_parsers_path
require('nvim-treesitter.configs').setup({
	-- IF NIX
	-- ensure_installed = {},
	-- ELSE
	-- ensure_installed = {
	-- 	"go",
	-- 	"html",
	-- 	"javascript",
	-- 	"json",
	-- 	"lua",
	-- 	"typescript",
	-- 	"tsx",
	-- 	"python",
	-- 	"swift"
	-- },
	ensure_installed = {},
	parser_install_dir = parsers_path,
	modules = {},
	auto_install = false,
	ignore_install = {},
	sync_install = false,
	highlight = {
		enable = true,
		additional_vim_regex_highlighting = false
	},
	indent = { enable = true },
	incremental_selection = {
		enable = true,
		keymaps = {
			init_selection = '<c-space>',
			node_incremental = '<c-space>',
			scope_incremental = '<c-s>',
			node_decremental = '<M-space>',
		},
	},
	textobjects = {
		select = {
			enable = true,
			lookahead = true,
			keymaps = {
				['aa'] = '@parameter.outer',
				['ia'] = '@parameter.inner',
				['af'] = '@function.outer',
				['if'] = '@function.inner',
				['ac'] = '@class.outer',
				['ic'] = '@class.inner',
			},
		},
		move = {
			enable = true,
			set_jumps = true,
			goto_next_start = {
				[']m'] = '@function.outer',
				[']]'] = '@class.outer',
			},
			goto_next_end = {
				[']M'] = '@function.outer',
				[']['] = '@class.outer',
			},
			goto_previous_start = {
				['[m'] = '@function.outer',
				['[['] = '@class.outer',
			},
			goto_previous_end = {
				['[M'] = '@function.outer',
				['[]'] = '@class.outer',
			},
		},
		swap = {
			enable = true,
			swap_next = {
				['<leader>a'] = '@parameter.inner',
			},
			swap_previous = {
				['<leader>A'] = '@parameter.inner',
			},
		},
	},
})

require("treesitter-context").setup { enable = true }
