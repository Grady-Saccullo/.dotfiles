-- [START] vim-slime.lua --
vim.g.slime_target = "wezterm"
vim.g.slime_bracketed_paste = 1
vim.g.slime_dont_ask_default = 1
vim.g.slime_default_config = { pane_id = "" }

-- Target the sibling pane of the current wezterm tab so <C-c><C-c> never prompts.
local function resolve_slime_pane()
	local current_pane = vim.env.WEZTERM_PANE
	if not current_pane or current_pane == "" then
		return
	end

	vim.system({ "wezterm", "cli", "list", "--format", "json" }, { text = true }, function(out)
		if out.code ~= 0 then
			return
		end
		local ok, panes = pcall(vim.json.decode, out.stdout)
		if not ok or type(panes) ~= "table" then
			return
		end

		local current_tab
		for _, p in ipairs(panes) do
			if tostring(p.pane_id) == current_pane then
				current_tab = p.tab_id
				break
			end
		end
		if current_tab == nil then
			return
		end

		for _, p in ipairs(panes) do
			if p.tab_id == current_tab and tostring(p.pane_id) ~= current_pane then
				vim.schedule(function()
					vim.g.slime_default_config = { pane_id = tostring(p.pane_id) }
				end)
				return
			end
		end
	end)
end

resolve_slime_pane()
vim.api.nvim_create_autocmd("FocusGained", { callback = resolve_slime_pane })

vim.api.nvim_create_user_command("SlimeResolvePane", resolve_slime_pane, {
	desc = "Re-resolve vim-slime target to a sibling wezterm pane",
})
-- [END] vim-slime.lua --
