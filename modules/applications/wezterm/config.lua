local wezterm = require("wezterm")
local act = wezterm.action

-- Smart splits plugin for seamless nvim/wezterm pane navigation
local smart_splits = wezterm.plugin.require("https://github.com/mrjones2014/smart-splits.nvim")

-- Fuzzy workspace switcher (tmux-sessionizer equivalent, uses zoxide).
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")

-- Persist + restore workspaces/tabs/panes across wezterm restarts.
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

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
	audible_bell = "Disabled",
	show_new_tab_button_in_tab_bar = false,
	tab_max_width = 32,
	status_update_interval = 500,
	scrollback_lines = 10000,
	leader = {
		key = "a",
		mods = "CTRL",
		timeout_milliseconds = 2000,
	},
	keys = {
		{
			key = "LeftArrow",
			mods = "OPT",
			action = act.SendString("\x1bb"),
		},
		{
			key = "RightArrow",
			mods = "OPT",
			action = act.SendString("\x1bf"),
		},
		{
			key = "UpArrow",
			mods = "SHIFT",
			action = act.ScrollToPrompt(-1),
		},
		{
			key = "DownArrow",
			mods = "SHIFT",
			action = act.ScrollToPrompt(1),
		},
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
		-- Leader + arrow for explicit wezterm pane navigation
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
		-- Workspaces (sessionizer-style)
		{
			key = "s",
			mods = "LEADER",
			action = workspace_switcher.switch_workspace(),
		},
		{
			key = "o",
			mods = "LEADER",
			action = act.SwitchWorkspaceRelative(1),
		},
		{
			key = "O",
			mods = "LEADER|SHIFT",
			action = act.SwitchWorkspaceRelative(-1),
		},
		-- Resurrect: save/load workspace state
		{
			key = "S",
			mods = "LEADER|SHIFT",
			action = wezterm.action_callback(function(win, pane)
				resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
			end),
		},
		{
			key = "R",
			mods = "LEADER|SHIFT",
			action = wezterm.action_callback(function(win, pane)
				resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
					local type = string.match(id, "^([^/]+)")
					id = string.match(id, "([^/]+)$")
					id = string.match(id, "(.+)%..+$")
					local opts = {
						relative = true,
						restore_text = true,
						on_pane_restore = resurrect.tab_state.default_on_pane_restore,
					}
					if type == "workspace" then
						local state = resurrect.state_manager.load_state(id, "workspace")
						resurrect.workspace_state.restore_workspace(state, opts)
					elseif type == "window" then
						local state = resurrect.state_manager.load_state(id, "window")
						resurrect.window_state.restore_window(pane:window(), state, opts)
					elseif type == "tab" then
						local state = resurrect.state_manager.load_state(id, "tab")
						resurrect.tab_state.restore_tab(pane:tab(), state, opts)
					end
				end)
			end),
		},
	},
}

-- Apply smart-splits with arrow keys for navigation and resize
smart_splits.apply_to_config(config, {
	direction_keys = {
		move = { "LeftArrow", "DownArrow", "UpArrow", "RightArrow" },
		resize = { "LeftArrow", "DownArrow", "UpArrow", "RightArrow" },
	},
	modifiers = {
		move = "CTRL",
		resize = "CTRL|SHIFT",
	},
})

tabline.setup({
	options = {
		icons_enabled = true,
		theme = "oxocarbon-dark",
	},
	sections = {
		tabline_a = { "mode" },
		tabline_b = { "workspace" },
		tabline_c = { " " },
		tab_active = {
			"index",
			{ "parent", padding = 0 },
			"/",
			{ "cwd", padding = { left = 0, right = 1 } },
			{ "zoomed", padding = 0 },
		},
		tab_inactive = { "index", { "process", padding = { left = 0, right = 1 } } },
		tabline_x = {},
		tabline_y = { "datetime" },
		tabline_z = { "domain" },
	},
	extensions = { "resurrect", "smart_workspace_switcher" },
})

-- Prefix workspace names in the picker for easier scanning.
workspace_switcher.workspace_formatter = function(label)
	return wezterm.format({
		{ Attribute = { Italic = true } },
		{ Foreground = { Color = "#33b1ff" } },
		{ Text = "󱂬 " .. label },
	})
end

-- Periodically snapshot the active workspace so ungraceful exits keep it.
wezterm.on("resurrect.periodic_save", function()
	resurrect.state_manager.write_current_state()
end)
resurrect.state_manager.periodic_save({
	interval_seconds = 15 * 60,
	save_workspaces = true,
	save_windows = true,
	save_tabs = true,
})

-- Auto-save whenever a new workspace is created via the switcher.
wezterm.on("smart_workspace_switcher.workspace_switcher.created", function(window, _, label)
	local workspace_state = resurrect.workspace_state
	workspace_state.restore_workspace(resurrect.state_manager.load_state(label, "workspace"), {
		window = window,
		relative = true,
		restore_text = true,
		on_pane_restore = resurrect.tab_state.default_on_pane_restore,
	})
end)
wezterm.on("smart_workspace_switcher.workspace_switcher.chosen", function(window, _, label)
	local workspace_state = resurrect.workspace_state
	resurrect.state_manager.save_state(workspace_state.get_workspace_state())
end)

return config
