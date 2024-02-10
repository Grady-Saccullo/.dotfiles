local kmap = vim.keymap.set

-- Telescope keymaps --
local telescope = require('telescope.builtin')
kmap('n', '<leader>?', telescope.oldfiles, { desc = '[?] Find recently opened files' })
kmap('n', '<leader><space>', telescope.buffers, { desc = '[ ] Find existing buffers' })
kmap(
	'n',
	'<leader>/',
	function()
		telescope.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
			winblend = 10,
			previewer = false,
		})
	end,
	{ desc = '[/] Fuzzily search in current buffer' }
)
kmap('n', '<leader>gf', telescope.git_files, { desc = 'Search [G]it [F]iles' })
kmap('n', '<leader>sf', telescope.find_files, { desc = '[S]earch [F]iles' })
kmap('n', '<leader>sh', telescope.help_tags, { desc = '[S]earch [H]elp' })
kmap('n', '<leader>sw', telescope.grep_string, { desc = '[S]earch current [W]ord' })
kmap('n', '<leader>sg', telescope.live_grep, { desc = '[S]earch by [G]rep' })
kmap('n', '<leader>sd', telescope.diagnostics, { desc = '[S]earch [D]iagnostics' })
kmap('n', '<leader>sr', telescope.resume, { desc = '[S]earch [R]esume' })

-- Harpoon --
local harpoon = require('harpoon')
kmap('n', '<leader>ha', function() harpoon:list():append() end, { desc = '[H]arpoon [A]dd current file to harpoon' })
kmap('n', '<leader>hs', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = '[H]arpoon [S]how quick menu' })

-- Diagnostic keymaps --
kmap('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
kmap('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
kmap('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
kmap('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- Copilot keymaps --
kmap('i', '<M-Tab>', 'copilot#Accept("<CR>")',
	{
		noremap = true,
		silent = true,
		expr = true,
		replace_keycodes = false,
		desc = 'Copilot accept key map',
	}
)
