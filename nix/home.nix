{ pkgs, ...}:

{
	home.stateVersion = "24.05";

	home.packages = with pkgs; [
		jq
		htop
		# lua
		# sqlite
		# turso
	];

	programs = {
		zsh = {
			enable = true;

			shellAliases = {
				vim = "nvim";
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

		wezterm = {
			enable = true;
			extraConfig = builtins.readFile "../configs/wezterm/.config/wezterm/wezterm.lua";
		};
		#
		# tmux = {
		# 	enable = true;
		# };
	};
}
