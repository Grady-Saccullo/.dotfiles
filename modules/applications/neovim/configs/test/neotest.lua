-- [START] neotest.lua --
local adapters = {}
for _, make in ipairs(neotest_adapters) do
	table.insert(adapters, make())
end

local neotest = require("neotest")
neotest.setup({
	adapters = adapters,
	status = { virtual_text = true },
})

local kmap = vim.keymap.set
kmap("n", "<leader>tt", function()
	neotest.run.run()
end, { desc = "[T]est nearest" })
kmap("n", "<leader>tT", function()
	neotest.run.run(vim.fn.expand("%"))
end, { desc = "[T]est file" })
kmap("n", "<leader>ta", function()
	neotest.run.run({ suite = true })
end, { desc = "[T]est [A]ll (suite)" })
kmap("n", "<leader>td", function()
	-- dap and its adapters are lazy; load them before neotest asks for the dap strategy.
	require("lz.n").trigger_load("nvim-dap")
	neotest.run.run({ strategy = "dap" })
end, { desc = "[T]est [D]ebug nearest" })
kmap("n", "<leader>ts", function()
	neotest.summary.toggle()
end, { desc = "[T]est [S]ummary" })
kmap("n", "<leader>to", function()
	neotest.output.open({ enter = true, auto_close = true })
end, { desc = "[T]est [O]utput" })
kmap("n", "<leader>tO", function()
	neotest.output_panel.toggle()
end, { desc = "[T]est [O]utput panel" })
kmap("n", "<leader>tw", function()
	neotest.watch.toggle(vim.fn.expand("%"))
end, { desc = "[T]est [W]atch file" })
kmap("n", "<leader>tx", function()
	neotest.run.stop()
end, { desc = "[T]est stop" })
kmap("n", "]t", function()
	neotest.jump.next({ status = "failed" })
end, { desc = "Next failed test" })
kmap("n", "[t", function()
	neotest.jump.prev({ status = "failed" })
end, { desc = "Previous failed test" })
-- [END] neotest.lua --
