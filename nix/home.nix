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
		./tools/tools.nix
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
	};
}
