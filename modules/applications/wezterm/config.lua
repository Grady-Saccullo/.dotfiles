local wezterm = require("wezterm")
local act = wezterm.action

-- Smart splits plugin for seamless nvim/wezterm pane navigation
local smart_splits = wezterm.plugin.require("https://github.com/mrjones2014/smart-splits.nvim")

-- Fuzzy workspace switcher (tmux-sessionizer equivalent, uses zoxide).
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")

-- Persist + restore workspaces/tabs/panes across wezterm restarts.
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

local wezterm = require("wezterm")
local config = wezterm.config_builder and wezterm.config_builder() or {}

-- Wezsesh
local wezsesh_root = "/Users/hackerman/code/grady-saccullo/wezsesh/plugin"
local wezsesh_binary = "/Users/hackerman/code/grady-saccullo/wezsesh/wezsesh"

package.path = wezsesh_root
	.. "/?.lua;"
	.. wezsesh_root
	.. "/?/init.lua;"
	.. wezsesh_root
	.. "/wezsesh/?.lua;"
	.. wezsesh_root
	.. "/wezsesh/?/init.lua;"
	.. package.path
local wezsesh = dofile(wezsesh_root .. "/init.lua")

local oxocarbon = {
	background = "#161616",
	foreground = "#ffffff",
	cursor_bg = "#ffffff",
	cursor_border = "#ffffff",
	cursor_fg = "#161616",
	ansi = { "#262626", "#ee5396", "#42be65", "#ffe97b", "#33b1ff", "#ff7eb6", "#3ddbd9", "#dde1e6" },
	brights = { "#393939", "#ee5396", "#42be65", "#ffe97b", "#33b1ff", "#ff7eb6", "#3ddbd9", "#ffffff" },
	tab_bar = {
		background = "rgba(0,0,0,0)",
		active_tab = {
			bg_color = "#161616",
			fg_color = "#ff7eb6",
			intensity = "Normal",
			italic = false,
			strikethrough = false,
			underline = "None",
		},
		inactive_tab = {
			bg_color = "#262626",
			fg_color = "#ffffff",
			intensity = "Normal",
			italic = false,
			strikethrough = false,
			underline = "None",
		},
		new_tab = {
			bg_color = "#262626",
			fg_color = "#ffffff",
			intensity = "Normal",
			italic = false,
			strikethrough = false,
			underline = "None",
		},
	},
}

local config = {
	color_schemes = { ["oxocarbon-dark"] = oxocarbon },
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
		{ key = "L", mods = "CTRL|SHIFT", action = wezterm.action.ShowDebugOverlay },
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
		-- {
		-- 	key = "W",
		-- 	mods = "LEADER|SHIFT",
		-- 	action = wezterm.action_callback(function(window, pane)
		-- 		workspace_manager(window, pane)
		-- 	end),
		-- },
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

wezsesh.apply_to_config(config, {
	binary = wezsesh_binary,
	resurrect = resurrect,
	snapshot_dir = wezterm.home_dir .. "/Library/Application Support/wezterm/resurrect",
	state_dir = wezterm.home_dir .. "/.local/state/wezsesh",
	data_dir = wezterm.home_dir .. "/.local/share/wezsesh",
	runtime_dir = "/tmp/wezsesh",
	log_level = "debug",
	-- dir_providers feed the picker with rows that are neither live
	-- nor saved (the "external" source). Selecting one renames the
	-- current workspace to the picked name and `cd`s the active pane
	-- into the supplied path — replaces the smart_workspace_switcher
	-- + zoxide flow.
	--
	-- Each entry is a typed config table. The Go binary executes
	-- them natively (shell-out for `command`, fs walk for
	-- `directory`, literal list for `static`). Fields:
	--   command:   argv (required), limit (default 200), timeout_ms (default 5000)
	--   directory: path (required), depth (default 2), limit, include_hidden
	--   static:    paths (required)
	dir_providers = {
		{ type = "command", argv = { "zoxide", "query", "-l" }, limit = 200 },
	},
})

tabline.setup({
	options = {
		icons_enabled = true,
		theme = oxocarbon,
	},
	sections = {
		tabline_a = {
			{
				"mode",
				cond = function(window)
					return window:active_key_table() ~= nil
				end,
			},
		},
		tabline_b = { "workspace" },
		tabline_c = { " " },
		tab_active = {
			"index",
			{ "tab", padding = { left = 1, right = 1 } },
			{ "zoomed", padding = 0 },
		},
		tab_inactive = {
			"index",
			{ "tab", padding = { left = 1, right = 1 } },
		},
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
