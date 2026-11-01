-- [START] gitsigns-nvim.lua --
require("gitsigns").setup({
	signs = {
		add = { text = "+" },
		change = { text = "~" },
		delete = { text = "_" },
		topdelete = { text = "‾" },
		changedelete = { text = "~" },
	},
	on_attach = function(bufnr)
		local gs = require("gitsigns")
		local function map(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
		end

		-- don't override the built-in and fugitive keymaps
		map({ "n", "v" }, "]c", function()
			if vim.wo.diff then
				return "]c"
			end
			vim.schedule(gs.next_hunk)
			return "<Ignore>"
		end, "Jump to next hunk")
		map({ "n", "v" }, "[c", function()
			if vim.wo.diff then
				return "[c"
			end
			vim.schedule(gs.prev_hunk)
			return "<Ignore>"
		end, "Jump to previous hunk")

		map("n", "<leader>vs", gs.stage_hunk, "Git: [S]tage hunk")
		map("v", "<leader>vs", function()
			gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, "Git: [S]tage selection")
		map("n", "<leader>vr", gs.reset_hunk, "Git: [R]eset hunk")
		map("v", "<leader>vr", function()
			gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, "Git: [R]eset selection")
		map("n", "<leader>vS", gs.stage_buffer, "Git: [S]tage buffer")
		map("n", "<leader>vR", gs.reset_buffer, "Git: [R]eset buffer")
		map("n", "<leader>vp", gs.preview_hunk_inline, "Git: [P]review hunk inline")
		map("n", "<leader>vP", gs.preview_hunk, "Git: [P]review hunk (float)")
		map("n", "<leader>vb", function()
			gs.blame_line({ full = true })
		end, "Git: [B]lame line")
		map("n", "<leader>vd", gs.diffthis, "Git: [D]iff against index")
		map("n", "<leader>vD", function()
			gs.diffthis("~")
		end, "Git: [D]iff against last commit")
		map("n", "<leader>vm", function()
			gs.change_base("main", true)
		end, "Git: diff signs against [M]ain")
		map("n", "<leader>vM", function()
			gs.change_base(nil, true)
		end, "Git: diff signs against index again")
		map("n", "<leader>vq", function()
			gs.setqflist("all")
		end, "Git: all hunks to [Q]uickfix")
		map("n", "<leader>vw", gs.toggle_word_diff, "Git: toggle [W]ord diff")
		map("n", "<leader>tb", gs.toggle_current_line_blame, "[T]oggle line [B]lame")
		map({ "o", "x" }, "ih", gs.select_hunk, "Select hunk")
	end,
})
-- [END] gitsigns-nvim.lua --
