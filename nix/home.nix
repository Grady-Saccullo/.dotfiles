{ pkgs, nixpkgs-unstable, ...}:

{
	home.stateVersion = "24.05";

	home.packages = with pkgs; [
		jq
		htop
		neovim
	];

	imports = [
		(import ./programs/programs.nix { inherit pkgs nixpkgs-unstable; })
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
