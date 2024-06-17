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

		# wezterm = {
		# 	enable = true;
		# };
		#
		tmux = {
			enable = true;

			extraConfig = 

			plugins = with pkgs.tmuxPlugins; [
				{
					plugin = resurrect;
					extraConfig = "set -g @resurrect-strategy-nvim 'session'";
				}
				continuum
				tmux-fzf
			];
		};
	};
}
