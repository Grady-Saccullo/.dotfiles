local luasnip = require 'luasnip'
luasnip.config.setup {}


local lspkind = require "lspkind"
lspkind.init {}

local cmp = require "cmp"

cmp.setup {
	snippet = {
		expand = function(args)
			require "luasnip".lsp_expand(args.body)
		end
	},
	completion = {
		completeopt = "menu,menuone,noinsert",
	},
	mapping = cmp.mapping.preset.insert {
		["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
		["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
		["<C-Space>"] = cmp.mapping.complete(),
		["<S-CR>"] = cmp.mapping.confirm {
			behavior = cmp.ConfirmBehavior.Insert,
			select = true
		},
	},
	sources = cmp.config.sources({
		{ name = "nvim_lsp", priority = 8,      keyword_length = 1 },
		{ name = "path",     keyword_length = 3 },
		{ name = "luasnip",  keyword_length = 2 }
	}, {
		name = "buffer",
	}),
	sorting = {
		priority_weight = 1.0,
		comparators = {
			cmp.config.compare.recently_used,
			cmp.config.compare.score,
			cmp.config.compare.locality,
			cmp.config.compare.offset,
			cmp.config.compare.order,
		}
	},
	formatting = {
		expandable_indicator = true,
		fields = { "abbr", "kind" },
		format = lspkind.cmp_format {
			mode = "text",
			maxwidth = 50,
			ellipsis_char = "..."
		}
	}
}

cmp.setup.cmdline({ '/', '?' }, {
	mapping = cmp.mapping.preset.cmdline(),
	sources = {
		{ name = 'buffer' }
	}
})
