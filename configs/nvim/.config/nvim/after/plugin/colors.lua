local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })

vim.api.nvim_create_autocmd('TextYankPost', {
	callback = function()
		vim.highlight.on_yank()
	end,
	group = highlight_group,
	pattern = '*',
})

local oxocarbon = require('oxocarbon').oxocarbon

vim.fn.sign_define('DapBreakpoint', {
	text = '◉',
	texthl = 'DapBreakpoint',
	linehl = 'DapBreakpoint',
	numhl = 'DapBreakpoint'
})
vim.fn.sign_define('DapBreakpointCondition', {
	text = '◎',
	DapBreakpointConditiontexthl = 'DapBreakpoint',
	linehl = 'DapBreakpoint',
	numhl = 'DapBreakpoint'
})
vim.fn.sign_define('DapBreakpointRejected', {
	text = '',
	texthl = 'DapBreakpoint',
	linehl = '',
	numhl = 'DapBreakpoint'
})
vim.fn.sign_define('DapLogPoint', {
	text = '',
	texthl = 'DapLogPoint',
	linehl = 'DapLogPoint',
	numhl = 'DapLogPoint'
})
vim.fn.sign_define('DapStopped', {
	text = '',
	texthl = 'DapStopped',
	linehl = 'DapStopped',
	numhl = 'DapStopped'
})

vim.api.nvim_set_hl(0, 'DapBreakpoint', { ctermbg = 0, fg = oxocarbon.base12, bg = oxocarbon.base01 })
vim.api.nvim_set_hl(0, 'DapLogPoint', { ctermbg = 0, fg = '#61afef', bg = oxocarbon.base01 })
vim.api.nvim_set_hl(0, 'DapStopped', { ctermbg = 0, fg = oxocarbon.base13, bg = oxocarbon.base01 })
