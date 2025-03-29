local wezterm = require("wezterm")
local act = wezterm.action

local config = {
	color_scheme = "oxocarbon-dark",
	font = wezterm.font("JetBrains Mono", { weight = "Book" }),
	window_close_confirmation = "NeverPrompt",
	check_for_updates = false,
	enable_tab_bar = true,
	tab_bar_at_bottom = true,
	leader = {
		key = "a",
		mods = "CTRL",
		timeout_milliseconds = 2000,
	},
	keys = {
		{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = "=", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
		{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },
		{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
		{ key = "LeftArrow", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
		{ key = "DownArrow", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
		{ key = "UpArrow", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
		{ key = "RightArrow", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
		{ key = "`", mods = "LEADER", action = act.ActivateLastTab },
		{ key = " ", mods = "LEADER", action = act.ActivateTabRelative(1) },
		{ key = "1", mods = "LEADER", action = act.ActivateTab(0) },
		{ key = "2", mods = "LEADER", action = act({ ActivateTab = 1 }) },
		{ key = "3", mods = "LEADER", action = act({ ActivateTab = 2 }) },
		{ key = "4", mods = "LEADER", action = act({ ActivateTab = 3 }) },
		{ key = "5", mods = "LEADER", action = act({ ActivateTab = 4 }) },
		{ key = "6", mods = "LEADER", action = act({ ActivateTab = 5 }) },
		{ key = "7", mods = "LEADER", action = act({ ActivateTab = 6 }) },
		{ key = "8", mods = "LEADER", action = act({ ActivateTab = 7 }) },
		{ key = "9", mods = "LEADER", action = act({ ActivateTab = 8 }) },
		{ key = "x", mods = "LEADER", action = act({ CloseCurrentPane = { confirm = true } }) },
	},
}

return config
