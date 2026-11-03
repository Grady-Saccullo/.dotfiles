-- [START] dap-rust.lua --
local dap = require("dap")
dap.adapters.codelldb = {
	type = "server",
	port = "${port}",
	executable = { command = require("dap-rust-codelldb"), args = { "--port", "${port}" } },
}
dap.configurations.rust = {
	{
		name = "Launch binary",
		type = "codelldb",
		request = "launch",
		program = function()
			return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
		end,
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
	},
}
-- [END] dap-rust.lua --
