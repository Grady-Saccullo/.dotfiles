local M = {}

-- Neovim's own pack/dist plugins are not ours to report on.
local function pack_dirs(kind)
	local dirs = vim.tbl_filter(function(d)
		return not vim.startswith(d, vim.env.VIMRUNTIME)
	end, vim.fn.globpath(vim.o.packpath, "pack/*/" .. kind .. "/*", false, true))
	table.sort(dirs)
	return dirs
end

function M.check()
	local h = vim.health
	local specs = require("hm-lazy").specs
	local on_rtp = {}
	for _, p in ipairs(vim.api.nvim_list_runtime_paths()) do
		on_rtp[vim.fs.normalize(p)] = true
	end

	h.start("Lazy plugins (pack/*/opt)")
	for _, dir in ipairs(pack_dirs("opt")) do
		local name = vim.fs.basename(dir)
		local state = on_rtp[vim.fs.normalize(dir)] and "loaded" or "not loaded"
		local triggers = specs[name]
		if triggers then
			h.ok(("%s: %s [%s]"):format(name, state, triggers))
		else
			h.warn(("%s: %s, nothing registered to load it"):format(name, state))
		end
	end

	h.start("Eager plugins (pack/*/start)")
	for _, dir in ipairs(pack_dirs("start")) do
		h.info(vim.fs.basename(dir))
	end
end

return M
