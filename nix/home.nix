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
		(import ./tools/tools.nix { inherit pkgs; })
	];

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
