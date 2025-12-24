local wezterm = require("wezterm")
local act = wezterm.action

local config = {
	color_scheme = "oxocarbon-dark",
	font = wezterm.font("JetBrains Mono", { weight = "Book" }),
	window_close_confirmation = "NeverPrompt",
	window_padding = {
		left = 0,
		right = 0,
		top = 0,
		bottom = 0,
	},
	use_fancy_tab_bar = false,
	window_decorations = "NONE|MACOS_FORCE_SQUARE_CORNERS|RESIZE",
	-- window_background_opacity = 0.95,
	-- macos_window_background_blur = 40,
	check_for_updates = false,
	enable_tab_bar = true,
	tab_bar_at_bottom = true,
	leader = {
		key = "a",
		mods = "CTRL",
		timeout_milliseconds = 2000,
	},
	keys = {
		{
			key = "-",
			mods = "LEADER",
			action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
		},
		{
			key = "=",
			mods = "LEADER",
			action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
		},
		{
			key = "z",
			mods = "LEADER",
			action = act.TogglePaneZoomState,
		},
		{
			key = "[",
			mods = "LEADER",
			action = act.ActivateCopyMode,
		},
		{
			key = "{",
			mods = "LEADER|SHIFT",
			action = act.PaneSelect({ mode = "SwapWithActiveKeepFocus" }),
		},
		{
			key = "c",
			mods = "LEADER",
			action = act.SpawnTab("CurrentPaneDomain"),
		},
		{
			key = ",",
			mods = "LEADER",
			action = act.PromptInputLine({
				description = "Enter tab name",
				action = wezterm.action_callback(function(window, pane, line)
					if line then
						window:active_tab():set_title(line)
					end
				end),
			}),
		},
		{
			key = "w",
			mods = "LEADER",
			action = act.ShowTabNavigator,
		},
		{
			key = "LeftArrow",
			mods = "LEADER",
			action = act.ActivatePaneDirection("Left"),
		},
		{
			key = "DownArrow",
			mods = "LEADER",
			action = act.ActivatePaneDirection("Down"),
		},
		{
			key = "UpArrow",
			mods = "LEADER",
			action = act.ActivatePaneDirection("Up"),
		},
		{
			key = "RightArrow",
			mods = "LEADER",
			action = act.ActivatePaneDirection("Right"),
		},
		{
			key = "n",
			mods = "LEADER",
			action = act.ActivateTabRelative(1),
		},
		{
			key = "p",
			mods = "LEADER",
			action = act.ActivateTabRelative(-1),
		},
		{
			key = "1",
			mods = "LEADER",
			action = act.ActivateTab(0),
		},
		{
			key = "2",
			mods = "LEADER",
			action = act({ ActivateTab = 1 }),
		},
		{
			key = "3",
			mods = "LEADER",
			action = act({ ActivateTab = 2 }),
		},
		{
			key = "4",
			mods = "LEADER",
			action = act({ ActivateTab = 3 }),
		},
		{
			key = "5",
			mods = "LEADER",
			action = act({ ActivateTab = 4 }),
		},
		{
			key = "6",
			mods = "LEADER",
			action = act({ ActivateTab = 5 }),
		},
		{
			key = "7",
			mods = "LEADER",
			action = act({ ActivateTab = 6 }),
		},
		{
			key = "8",
			mods = "LEADER",
			action = act({ ActivateTab = 7 }),
		},
		{
			key = "9",
			mods = "LEADER",
			action = act({ ActivateTab = 8 }),
		},
		{
			key = "x",
			mods = "LEADER",
			action = act({ CloseCurrentPane = { confirm = true } }),
		},
	},
}

return config
