-- [START] diagnostic.lua --
-- Show the diagnostic that was jumped to as a virtual line even when it is off the cursor line.
local function on_jump(diagnostic, bufnr)
	if not diagnostic then
		return
	end
	vim.diagnostic.show(
		diagnostic.namespace,
		bufnr,
		{ diagnostic },
		{ virtual_lines = { current_line = true }, virtual_text = false }
	)
end

vim.diagnostic.config({
	virtual_text = false,
	virtual_lines = { current_line = true },
	severity_sort = true,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "",
			[vim.diagnostic.severity.WARN] = "",
			[vim.diagnostic.severity.INFO] = "",
			[vim.diagnostic.severity.HINT] = "",
		},
	},
	jump = { on_jump = on_jump },
})
-- [END] diagnostic.lua --
