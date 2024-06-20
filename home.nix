{ pkgs, inputs, config, ... }:
{
	home.stateVersion = "24.05";

	home.packages = with pkgs; [
		jq
		htop
		ripgrep
		stow
		tree
		go
		lua
	];

	programs.home-manager.enable = true;
	imports = [
		(import ./programs/_programs.nix { inherit pkgs inputs config; })
	];
}
