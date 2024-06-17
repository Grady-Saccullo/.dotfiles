{ pkgs, ...}:

{
	home.stateVersion = "24.05";

	home.packages = with pkgs; [
		jq
		htop
		neovim
		# lua
		# sqlite
		# turso
	];

	imports = [
		./tools/wezterm.nix
	];

	# xdg.configFile = {
	# 	"wezterm/colors".source = ../configs/wezterm/.config/wezterm/colors;
	# 	"wezterm/colors".recursive = true; 
	# };
	# home.file = {
	# 	".config/wezterm/colors" = {
	# 		source = builtins.readDir ../configs/wezterm/.config/wezterm/colors;
	# 		target = "source";
	# 	};
	# };

	programs = {
		zsh = {
			enable = true;

			shellAliases = {
				#vim  "nvim";
				l = "ls -la";
			};

			oh-my-zsh = {
				enable = true;
			};
		};

		direnv = {
			enable = true;
			nix-direnv = {
				enable = true;
			};
		};

		git = {
			enable = true;

			lfs = {
				enable= true;
			};

			delta = {
				enable = true;
			};
		};

		# wezterm = {
		# 	enable = true;
		# 	extraConfig = builtins.readFile ../configs/wezterm/.config/wezterm/wezterm.lua;
		# };

		tmux = {
			enable = true;
			extraConfig = builtins.readFile ../configs/tmux/.tmux.conf;
			plugins = with pkgs.tmuxPlugins; [
				continuum
				{
					plugin = resurrect;
					extraConfig = "set -g @resurrect-strategy-nvim 'session'";
				}
			];
		};
	};
}
