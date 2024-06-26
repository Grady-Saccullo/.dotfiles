{ pkgs, ... }:
{
	imports = [
		../../shared/configs
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
		git-credential-oauth
		spice-vdagent

		gnumake
		brave
		firefox
		spotify
	];

	home.sessionVariables = {
		EDITOR = "vim";
	};

	programs.zsh.enable = true;
}
