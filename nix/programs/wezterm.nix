{ ... }:
{
	xdg.configFile = {
		"wezterm/colors".source = ../../configs/wezterm/.config/wezterm/colors;
		"wezterm/colors".recursive = true; 
	};

	programs = {
		wezterm = {
			enable = true;
			extraConfig = builtins.readFile ../../configs/wezterm/.config/wezterm/wezterm.lua;
		};
	};
}
