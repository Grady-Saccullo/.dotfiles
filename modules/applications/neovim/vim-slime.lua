-- [START] vim-slime.lua --
vim.g.slime_target = "wezterm"
vim.g.slime_bracketed_paste = 1
vim.g.slime_dont_ask_default = 1
vim.g.slime_default_config = { pane_id = "" }

-- Auto-pick a sibling pane in the current wezterm tab so Ctrl-c Ctrl-c
-- "just sends to the other pane" without ever prompting — mirroring the
-- classic tmux "send to last pane" workflow. Re-resolves on focus change
-- so pane splits/closures mid-session keep working.
local function resolve_slime_pane()
	local current_pane = vim.env.WEZTERM_PANE
	if not current_pane or current_pane == "" then
		return
	end

	local out = vim.fn.system({ "wezterm", "cli", "list", "--format", "json" })
	if vim.v.shell_error ~= 0 then
		return
	end

	local ok, panes = pcall(vim.json.decode, out)
	if not ok or type(panes) ~= "table" then
		return
	end

	local current_tab
	for _, p in ipairs(panes) do
		if tostring(p.pane_id) == tostring(current_pane) then
			current_tab = p.tab_id
			break
		end
	end
	if current_tab == nil then
		return
	end

	for _, p in ipairs(panes) do
		if p.tab_id == current_tab and tostring(p.pane_id) ~= tostring(current_pane) then
			vim.g.slime_default_config = { pane_id = tostring(p.pane_id) }
			return
		end
	end
end

vim.api.nvim_create_autocmd({ "VimEnter", "FocusGained" }, {
	callback = resolve_slime_pane,
})

vim.api.nvim_create_user_command("SlimeResolvePane", resolve_slime_pane, {
	desc = "Re-resolve vim-slime target to a sibling wezterm pane",
})
-- [END] vim-slime.lua --
