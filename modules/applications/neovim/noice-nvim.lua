require("noice").setup({
	lsp = {
		progress = {
			enabled = true,
			format = "lsp_progress",
			format_done = "lsp_progress_done",
			throttle = 1000 / 30,
			view = "mini",
		},
		override = {
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
			["cmp.entry.get_documentation"] = true,
		},
		hover = {
			enabled = true,
			silent = false,
		},
		signature = {
			enabled = true,
		},
	},

	routes = {
		{
			filter = {
				event = "msg_show",
				kind = "search_count",
			},
			opts = { skip = true },
		},
		{
			filter = {
				event = "msg_show",
				kind = "",
				find = "written",
			},
			opts = { skip = true },
		},
		{
			filter = {
				event = "msg_show",
				min_height = 10,
			},
			view = "split",
		},
		{
			filter = {
				event = "lsp",
				kind = "progress",
			},
			opts = {
				replace = true,
				merge = true,
			},
		},
		{
			filter = {
				event = "msg_show",
				find = "No more valid diagnostics",
			},
			opts = { skip = true },
		},
	},

	presets = {
		bottom_search = true, -- Keep search at bottom, telescope takes center
		command_palette = false, -- Let telescope be the main picker
		long_message_to_split = true,
		inc_rename = false,
		lsp_doc_border = true,
	},

	views = {
		-- Compact notifications that don't interfere with telescope
		mini = {
			position = {
				row = 2,
				col = "100%",
			},
			size = {
				width = "auto",
				height = "auto",
			},
			border = {
				style = "none",
			},
			win_options = {
				winblend = 30,
			},
			timeout = 2000, -- Shorter timeout
		},

		-- Position cmdline to not conflict with telescope
		cmdline_popup = {
			position = {
				row = 20,
				col = "50%",
			},
			size = {
				width = 60,
				height = "auto",
			},
			border = {
				style = "rounded",
			},
		},

		popupmenu = {
			position = {
				row = 23,
				col = "50%",
			},
			size = {
				width = 60,
				height = 10,
			},
			border = {
				style = "rounded",
				padding = { 0, 1 },
			},
			win_options = {
				winhighlight = { Normal = "Normal", FloatBorder = "DiagnosticInfo" },
			},
		},
	},

	-- Let telescope handle most command/file operations
	cmdline = {
		enabled = true,
		view = "cmdline_popup",
		opts = {},
		format = {
			cmdline = { pattern = "^:", icon = ">_", lang = "vim" },
			search_down = { kind = "search", pattern = "^/", icon = "󰍉", lang = "regex" },
			search_up = { kind = "search", pattern = "^%?", icon = "󰍉", lang = "regex" },
			filter = { pattern = "^:%s*!", icon = "󰻿", lang = "bash" },
			lua = { pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" }, icon = "󰢱", lang = "lua" },
			help = { pattern = "^:%s*he?l?p?%s+", icon = "󰋖" },
		},
	},
})
