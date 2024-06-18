{ pkgs, outputs, ... }:
{
	imports = [
		(import ./programs/_programs.nix { inherit pkgs; })
	];

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
}
