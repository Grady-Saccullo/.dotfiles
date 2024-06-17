{ pkgs, outputs, ... }:
{
	home.stateVersion = "24.05";

	home.packages = with pkgs; [
		jq
		htop
		neovim
	];


	nixpkgs = {
		overlays = [
			outputs.overlays.unstable-packages
		];
		config = {
			allowUnfree = true;
		};
	};

	imports = [
		(import ./programs/programs.nix { inherit pkgs; })
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
