{ pkgs, outputs, ... }:
{
	home.stateVersion = "24.05";

	home.packages = with pkgs; [
		jq
		htop
		ripgrep
		stow
		tree
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
				l = "ls -la";
			};

			oh-my-zsh = {
				enable = true;

				plugins = [
					"git"
				];
				theme = "robbyrussell";
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
