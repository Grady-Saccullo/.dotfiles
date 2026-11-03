local kmap = vim.keymap.set
kmap("n", "<leader>oo", "<cmd>DBUIToggle<CR>", { desc = "Database: t[O]ggle DBUI" })
kmap("n", "<leader>of", "<cmd>DBUIFindBuffer<CR>", { desc = "Database: [F]ind buffer" })
require("which-key").add({ { "<leader>o", group = "database" } })

-- The <Plug> maps only exist in buffers DBUI opened, so these are no-ops in plain .sql files.
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "sql", "mysql", "plsql" },
	callback = function(ev)
		local opts = function(desc)
			return { buffer = ev.buf, remap = true, desc = desc }
		end
		kmap({ "n", "x" }, "<leader>oe", "<Plug>(DBUI_ExecuteQuery)", opts("Database: [E]xecute query"))
		kmap("n", "<leader>ow", "<Plug>(DBUI_SaveQuery)", opts("Database: save query"))
		kmap("n", "<leader>ob", "<Plug>(DBUI_EditBindParameters)", opts("Database: edit [B]ind parameters"))
	end,
})

local blink = require("blink.cmp")
blink.add_source_provider("dadbod", { name = "Dadbod", module = "vim_dadbod_completion.blink" })
for _, ft in ipairs({ "sql", "mysql", "plsql" }) do
	blink.add_filetype_source(ft, "dadbod")
end
