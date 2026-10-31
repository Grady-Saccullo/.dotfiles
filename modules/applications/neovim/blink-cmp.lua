-- [START] blink-cmp.lua --
local blink = require("blink.cmp")

blink.setup({
	keymap = {
		preset = "default",
		["<CR>"] = { "accept", "fallback" },
		["<C-j>"] = { "select_next", "fallback" },
		["<C-k>"] = { "select_prev", "fallback" },
		["<C-s>"] = { "show_signature", "hide_signature", "fallback" },
	},

	completion = {
		list = { selection = { preselect = true, auto_insert = false } },
		menu = { draw = { treesitter = { "lsp" } } },
		documentation = { auto_show = true, auto_show_delay_ms = 200 },
		ghost_text = { enabled = true },
	},

	signature = { enabled = true },

	cmdline = {
		keymap = { preset = "cmdline" },
		completion = {
			menu = { auto_show = true },
			list = { selection = { preselect = false, auto_insert = true } },
		},
	},

	sources = {
		default = { "lsp", "path", "snippets", "buffer" },
		per_filetype = {
			gitcommit = { inherit_defaults = true, "git" },
		},
		providers = {
			git = { module = "blink-cmp-git", name = "Git" },
		},
	},

	-- nixpkgs links the Rust matcher into target/release; warn rather than silently degrade.
	fuzzy = { implementation = "prefer_rust_with_warning" },
})

-- Advertise snippet/resolve support to every server before any client starts.
vim.lsp.config("*", { capabilities = blink.get_lsp_capabilities() })
-- [END] blink-cmp.lua --
