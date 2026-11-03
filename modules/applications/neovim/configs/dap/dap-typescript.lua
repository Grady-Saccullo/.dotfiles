-- [START] dap-typescript.lua --
local dap = require("dap")

-- js-debug binds to localhost; nvim-dap only substitutes ${port} inside executable.args.
dap.adapters["pwa-node"] = {
	type = "server",
	host = "127.0.0.1",
	port = "${port}",
	executable = { command = require("dap-js-debug"), args = { "${port}", "127.0.0.1" } },
}

-- The debuggee runs on whatever `node` the repo shell provides; nothing is pinned here.
local configurations = {
	{
		name = "Launch file",
		type = "pwa-node",
		request = "launch",
		program = "${file}",
		cwd = "${workspaceFolder}",
		sourceMaps = true,
		console = "internalConsole",
	},
	{
		name = "Launch file with tsx",
		type = "pwa-node",
		request = "launch",
		runtimeExecutable = "npx",
		runtimeArgs = { "tsx" },
		program = "${file}",
		cwd = "${workspaceFolder}",
		sourceMaps = true,
		console = "internalConsole",
	},
	{
		name = "Attach to process",
		type = "pwa-node",
		request = "attach",
		processId = require("dap.utils").pick_process,
		cwd = "${workspaceFolder}",
	},
}
for _, ft in ipairs({ "javascript", "javascriptreact", "typescript", "typescriptreact" }) do
	dap.configurations[ft] = configurations
end
-- [END] dap-typescript.lua --
