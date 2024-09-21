return {
	-- {
	-- 	"rose-pine/neovim",
	-- 	name = "rose-pine",
	-- 	opts = {
	--
	-- 	},
	-- 	config = function (_, opts)
	-- 		vim.o.background = "dark"
	-- 		vim.cmd("colorscheme rose-pine")
	-- 	end
	-- },
	{
		"nyoom-engineering/oxocarbon.nvim",
		config = function(_, opts) 
			vim.opt.background = "dark"
			vim.opt.termguicolors = true
			vim.cmd("colorscheme oxocarbon")
		end
	},
	-- {
	-- 	'rebelot/kanagawa.nvim',
	-- 	opts = {
	-- 		overrides = function(colors)
	-- 			local theme = colors.theme
	-- 			return {
	-- 				NormalFloat = { bg = "none" },
	-- 				FloatBorder = { bg = "none" },
	-- 				FloatTitle = { bg = "none" },
	-- 				NormalDark = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m3 },
	-- 				LazyNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
	-- 				MasonNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
	-- 				TelescopeTitle = { fg = theme.ui.special, bold = true },
	-- 				TelescopePromptNormal = { bg = theme.ui.bg_p1 },
	-- 				TelescopePromptBorder = { fg = theme.ui.bg_p1, bg = theme.ui.bg_p1 },
	-- 				TelescopeResultsNormal = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m1 },
	-- 				TelescopeResultsBorder = { fg = theme.ui.bg_m1, bg = theme.ui.bg_m1 },
	-- 				TelescopePreviewNormal = { bg = theme.ui.bg_dim },
	-- 				TelescopePreviewBorder = { bg = theme.ui.bg_dim, fg = theme.ui.bg_dim },
	-- 				Pmenu = { fg = theme.ui.shade0, bg = theme.ui.bg_p1 }, -- add `blend = vim.o.pumblend` to enable transparency
	-- 				PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
	-- 				PmenuSbar = { bg = theme.ui.bg_m1 },
	-- 				PmenuThumb = { bg = theme.ui.bg_p2 },
	-- 			}
	-- 		end,
	-- 	},
	-- 	priority = 1000,
	-- 	config = function(_, opts)
	-- 		vim.opt.termguicolors = true
	-- 		require('kanagawa').setup(opts)
	-- 		vim.cmd('colorscheme kanagawa-wave')
	-- 	end,
	-- }
}
