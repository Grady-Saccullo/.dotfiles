-- [START] nvim-cmp.lua --
local luasnip = require("luasnip")
luasnip.config.setup()
require("luasnip.loaders.from_vscode").lazy_load()

local lspkind = require("lspkind")
lspkind.init()

local cmp = require("cmp")
cmp.setup({
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},

	completion = {
		completeopt = "menu,menuone,noinsert",
	},

	preselect = cmp.PreselectMode.Item,

	view = {
		entries = {
			selection_order = "near_cursor",
		},
	},

	mapping = cmp.mapping.preset.insert({
		["<C-j>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
		["<C-k>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.abort(),
		["<CR>"] = cmp.mapping.confirm({ select = true }),
	}),

	sources = cmp.config.sources({
		{ name = "nvim_lsp", priority = 8 },
		{ name = "luasnip", priority = 7 },
		{ name = "spell", keyword_length = 3, priority = 5, keyword_psttern = [[\w\+]] },
		{ name = "path", priority = 4 },
	}, {
		name = "buffer",
		priority = 6,
	}),

	sorting = {
		priority_weight = 1,
		comparators = {
			cmp.config.compare.locality,
			cmp.config.compare.recently_used,
			cmp.config.compare.score,
			cmp.config.compare.offset,
			cmp.config.compare.order,
		},
	},
})

cmp.setup.filetype("gitcommit", {
	sources = cmp.config.sources({
		{ name = "git" },
	}, {
		{ name = "buffer" },
	}),
})

require("cmp_git").setup()

cmp.setup.cmdline({ "/", "?" }, {
	mapping = cmp.mapping.preset.cmdline(),
	sources = {
		{ name = "buffer" },
	},
})

cmp.event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done())
-- [END] nvim-cmp.lua --
