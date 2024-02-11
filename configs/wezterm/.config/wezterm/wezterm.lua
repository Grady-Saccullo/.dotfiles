local wezterm = require('wezterm')

local config = {
	color_scheme = "Kanagawa (Gogh)",
	enable_tab_bar = false,
	macos_window_background_blur = 30,
	window_background_opacity = 1,
	window_padding = {
		left = 10,
		right = 10,
		top = 0,
		bottom = 0,
	},
	font = wezterm.font("JetBrains Mono", { weight = "Book" }),
}

-- if wezterm.config_builder then
-- 	config = wezterm.config_builder()
-- end

return config

