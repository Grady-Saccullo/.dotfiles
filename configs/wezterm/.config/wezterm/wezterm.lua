local wezterm = require('wezterm')

local config = {
	color_scheme = "Oxocarbon Dark",
	enable_tab_bar = false,
	font = wezterm.font("JetBrains Mono", { weight = "Book" }),
	window_close_confirmation = 'NeverPrompt',
	-- default_prog = { "zsh", "-c", "tmux attach -t personal || tmux new -s personal" }
}

return config

