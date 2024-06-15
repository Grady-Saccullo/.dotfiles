{ config, pkgs, ... }: 
{

	environment.systemPackages = with pkgs; [
		home-manager
	];

	services.nix-dameon.enable = true;

	nix = {
		package = pkgs.nix;
		settings = {
			"extra-experimental-features" = [ "nix-command" "falkes" ];
		};
	};

	programs = {
		zsh.enable = true;
	};

	system.stateVersion = 4;

	# fonts.fontDir.enable = true;

	homebrew = {
		enable = true;

		casks = [
			"discord"
		];
	};
}
