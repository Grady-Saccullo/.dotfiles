{ pkgs, ... }: 
{

	environment.systemPackages = with pkgs; [
		home-manager
	];

	environment.darwinConfig = "$HOME/.dotfiles/nix";

	services.nix-daemon.enable = true;

	programs = {
		zsh = {
			enable = true;
		};
	};

	nix = {
		package = pkgs.nix;
		settings = {
			"extra-experimental-features" = [
				"nix-command"
				"flakes"
			];
		};
	};

	system.stateVersion = 4;

	# fonts.fontDir.enable = true;

	homebrew = {
		enable = true;

		casks = [
			"discord"
			"betterdisplay"
			"docker"
			"brave-browser"
			"soundsource"
			"spotify"
			"slack"
		];
	};
}
