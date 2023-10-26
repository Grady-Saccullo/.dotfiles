local kset = vim.keymap.set
local telescope = require('telescope.builtin')

-- Telescope keymaps --
kset('n', '<leader>?', telescope.oldfiles, { desc = '[?] Find recently opened files' })
kset('n', '<leader><space>', telescope.buffers, { desc = '[ ] Find existing buffers' })
kset('n', '<leader>/', function()
	-- You can pass additional configuration to telescope to change theme, layout, etc.
	telescope.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
		winblend = 10,
		previewer = false,
	})
end, { desc = '[/] Fuzzily search in current buffer' })
kset('n', '<leader>gf', telescope.git_files, { desc = 'Search [G]it [F]iles' })
kset('n', '<leader>sf', telescope.find_files, { desc = '[S]earch [F]iles' })
kset('n', '<leader>sh', telescope.help_tags, { desc = '[S]earch [H]elp' })
kset('n', '<leader>sw', telescope.grep_string, { desc = '[S]earch current [W]ord' })
kset('n', '<leader>sg', telescope.live_grep, { desc = '[S]earch by [G]rep' })
kset('n', '<leader>sd', telescope.diagnostics, { desc = '[S]earch [D]iagnostics' })
kset('n', '<leader>sr', telescope.resume, { desc = '[S]earch [R]esume' })

kset('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
kset('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
kset('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
kset('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

kset('i', '<M-Tab>', 'copilot#Accept("<CR>")',
	{
		noremap = true,
		silent = true,
		expr = true,
		replace_keycodes = false,
		desc = 'Copilot accept key map',
	}
)
