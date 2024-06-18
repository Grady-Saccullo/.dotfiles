{ pkgs, ... }:
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

	programs.home-manager.enable = true;
}
