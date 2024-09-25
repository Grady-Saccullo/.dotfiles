local wezterm = require('wezterm')

local config = {
	color_scheme = "oxocarbon-dark",
	enable_tab_bar = false,
	font = wezterm.font("JetBrains Mono", { weight = "Book" }),
	window_close_confirmation = 'NeverPrompt',
}

return config

