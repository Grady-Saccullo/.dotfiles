-- [START] dap.lua --
vim.fn.sign_define("DapBreakpoint", {
	text = "◉",
	texthl = "DapBreakpoint",
	linehl = "DapBreakpoint",
	numhl = "DapBreakpoint",
})

vim.fn.sign_define("DapBreakpointCondition", {
	text = "◎",
	texthl = "DapBreakpoint",
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
end, { desc = "Debug: continue" })
vim.keymap.set("n", "<F10>", function()
	require("dap").step_over()
end, { desc = "Debug: step over" })
vim.keymap.set("n", "<F11>", function()
	require("dap").step_into()
end, { desc = "Debug: step into" })
vim.keymap.set("n", "<F12>", function()
	require("dap").step_out()
end, { desc = "Debug: step out" })
vim.keymap.set("n", "<Leader>b", function()
	require("dap").toggle_breakpoint()
end, { desc = "Debug: toggle [B]reakpoint" })
vim.keymap.set("n", "<Leader>B", function()
	require("dap").set_breakpoint()
end, { desc = "Debug: set [B]reakpoint" })
vim.keymap.set("n", "<Leader>lp", function()
	require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
end, { desc = "Debug: [L]og [P]oint" })
vim.keymap.set("n", "<Leader>dr", function()
	require("dap").repl.open()
end, { desc = "[D]ebug [R]EPL" })
vim.keymap.set("n", "<Leader>dl", function()
	require("dap").run_last()
end, { desc = "[D]ebug run [L]ast" })
vim.keymap.set({ "n", "v" }, "<Leader>dh", function()
	require("dap.ui.widgets").hover()
end, { desc = "[D]ebug [H]over" })
vim.keymap.set({ "n", "v" }, "<Leader>dp", function()
	require("dap.ui.widgets").preview()
end, { desc = "[D]ebug [P]review" })
vim.keymap.set("n", "<Leader>df", function()
	local widgets = require("dap.ui.widgets")
	widgets.centered_float(widgets.frames)
end, { desc = "[D]ebug [F]rames" })
vim.keymap.set("n", "<Leader>Ds", function()
	local widgets = require("dap.ui.widgets")
	widgets.centered_float(widgets.scopes)
end, { desc = "[D]ebug [S]copes" })
-- [END] dap.lua --
