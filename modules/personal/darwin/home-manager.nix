{ pkgs, config, ... }:
{
	imports = [
		../../shared/programs
	];

	# TODO: look into home manager state version
	home.stateVersion = "24.05";

	xdg.enable = true;

	home.packages = pkgs.callPackage ./home-packages.nix {};

	home.file = import ../shared/home-files.nix { inherit config; };

	home.sessionVariables = {
		EDITOR = "vim";
	};
}
