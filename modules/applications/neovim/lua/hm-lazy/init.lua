local M = { specs = {} }

--- Record what loads a pack/*/opt plugin so :checkhealth hm-lazy can report it.
function M.register(name, triggers)
	M.specs[name] = triggers
end

--- :packadd leaves after/plugin unsourced, which is where cmp sources register themselves.
function M.packadd(name)
	vim.cmd.packadd(name)
	for _, pat in ipairs({ "*.lua", "*.vim" }) do
		local files = vim.fn.globpath(vim.o.packpath, "pack/*/opt/" .. name .. "/after/plugin/**/" .. pat, false, true)
		for _, f in ipairs(files) do
			vim.cmd.source(f)
		end
	end
end

return M
