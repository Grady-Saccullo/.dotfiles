local wezterm = require('wezterm')

local config = {
	color_scheme = "Catpuccin Mocha",
	enable_tab_bar = false,
	macos_window_background_blur = 30,
	window_background_opacity = 0.9,
}

-- if wezterm.config_builder then
-- 	config = wezterm.config_builder()
-- end

return config
