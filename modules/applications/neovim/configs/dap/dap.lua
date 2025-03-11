-- [START] dap.lua --
vim.fn.sign_define("DapBreakpoint", {
	text = "◉",
	texthl = "DapBreakpoint",
	linehl = "DapBreakpoint",
	numhl = "DapBreakpoint",
})

vim.fn.sign_define("DapBreakpointCondition", {
	text = "◎",
	DapBreakpointConditiontexthl = "DapBreakpoint",
	linehl = "DapBreakpoint",
	numhl = "DapBreakpoint",
})
vim.fn.sign_define("DapBreakpointRejected", {
	text = "",
	texthl = "DapBreakpoint",
	linehl = "",
	numhl = "DapBreakpoint",
})
vim.fn.sign_define("DapLogPoint", {
	text = "",
	texthl = "DapLogPoint",
	linehl = "DapLogPoint",
	numhl = "DapLogPoint",
})
vim.fn.sign_define("DapStopped", {
	text = "",
	texthl = "DapStopped",
	linehl = "DapStopped",
	numhl = "DapStopped",
})

local oxocarbon = require("oxocarbon").oxocarbon

vim.api.nvim_set_hl(0, "DapBreakpoint", {
	ctermbg = 0,
	fg = oxocarbon.base12,
	bg = oxocarbon.base01,
})
vim.api.nvim_set_hl(0, "DapLogPoint", {
	ctermbg = 0,
	fg = "#61afef",
	bg = oxocarbon.base01,
})
vim.api.nvim_set_hl(0, "DapStopped", {
	ctermbg = 0,
	fg = oxocarbon.base13,
	bg = oxocarbon.base01,
})

-- Dap keymaps --
vim.keymap.set("n", "<F5>", function()
	require("dap").continue()
end)
vim.keymap.set("n", "<F10>", function()
	require("dap").step_over()
end)
vim.keymap.set("n", "<F11>", function()
	require("dap").step_into()
end)
vim.keymap.set("n", "<F12>", function()
	require("dap").step_out()
end)
vim.keymap.set("n", "<Leader>b", function()
	require("dap").toggle_breakpoint()
end)
vim.keymap.set("n", "<Leader>B", function()
	require("dap").set_breakpoint()
end)
vim.keymap.set("n", "<Leader>lp", function()
	require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
end)
vim.keymap.set("n", "<Leader>dr", function()
	require("dap").repl.open()
end)
vim.keymap.set("n", "<Leader>dl", function()
	require("dap").run_last()
end)
vim.keymap.set({ "n", "v" }, "<Leader>dh", function()
	require("dap.ui.widgets").hover()
end)
vim.keymap.set({ "n", "v" }, "<Leader>dp", function()
	require("dap.ui.widgets").preview()
end)
vim.keymap.set("n", "<Leader>df", function()
	local widgets = require("dap.ui.widgets")
	widgets.centered_float(widgets.frames)
end)
vim.keymap.set("n", "<Leader>Ds", function()
	local widgets = require("dap.ui.widgets")
	widgets.centered_float(widgets.scopes)
end)
-- [END] dap.lua --
