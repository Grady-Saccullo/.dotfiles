{ pkgs, ... }:
user:
{
	users.users.${user} = {
		home = "/Users/${user}";
	};

	imports = [
		../../shared/configs
		./homebrew.nix
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
		discord
	];

	home.sessionVariables = {
		EDITOR = "vim";
	};
}
