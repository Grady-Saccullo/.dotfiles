{ inputs, ... }:
{ config, lib, pkgs, ... }:
{
	imports = [
		./direnv.nix
		./git.nix
		./nvim.nix
		./tmux.nix
		./wezterm.nix
		./zsh.nix
	];
	
	# TODO: look into home manager state version
	home.stateVersion = "24.05";

	xdg.enable = true;

	home.packages = with pkgs;  [
		asciinema #TODO explore asciinema
		bat
		gh
		htop
		jq
		nodejs_22
		ripgrep
		stow
		tree
	];

	home.sessionVariables = {
		EDITOR = "vim";
	};
}
