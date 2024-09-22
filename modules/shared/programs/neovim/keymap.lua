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
kmap('n', '<leader>hs', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end,
	{ desc = '[H]arpoon [S]how quick menu' })

-- Diagnostic keymaps --
kmap('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
kmap('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
kmap('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
kmap('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- Dap keymaps --
vim.keymap.set('n', '<F5>', function() require('dap').continue() end)
vim.keymap.set('n', '<F10>', function() require('dap').step_over() end)
vim.keymap.set('n', '<F11>', function() require('dap').step_into() end)
vim.keymap.set('n', '<F12>', function() require('dap').step_out() end)
vim.keymap.set('n', '<Leader>b', function() require('dap').toggle_breakpoint() end)
vim.keymap.set('n', '<Leader>B', function() require('dap').set_breakpoint() end)
vim.keymap.set('n', '<Leader>lp',
	function() require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end)
vim.keymap.set('n', '<Leader>dr', function() require('dap').repl.open() end)
vim.keymap.set('n', '<Leader>dl', function() require('dap').run_last() end)
vim.keymap.set({ 'n', 'v' }, '<Leader>dh', function()
	require('dap.ui.widgets').hover()
end)
vim.keymap.set({ 'n', 'v' }, '<Leader>dp', function()
	require('dap.ui.widgets').preview()
end)
vim.keymap.set('n', '<Leader>df', function()
	local widgets = require('dap.ui.widgets')
	widgets.centered_float(widgets.frames)
end)
vim.keymap.set('n', '<Leader>Ds', function()
	local widgets = require('dap.ui.widgets')
	widgets.centered_float(widgets.scopes)
end)
