{ pkgs, ... }: 
{
	imports = [
		./homebrew.nix
	];

	environment.darwinConfig = "$HOME/.dotfiles/hosts/darwin/configuration.nix";

	services.nix-daemon.enable = true;

	nix = {
		package = pkgs.nixVersions.latest;
		gc = {
			user = "root";
			automatic = true;
			interval = { Weekday = 0; Hour = 2; Minute = 0; };
			options = "--delete-older-than 30d";
		};
		settings = {
			"extra-experimental-features" = [
				"nix-command"
				"flakes"
			];
		};
	};

	system.stateVersion = 4;

	system.keyboard.enableKeyMapping = true;
	system.keyboard.remapCapsLockToEscape = true;

	system.defaults.NSGlobalDomain."com.apple.keyboard.fnState" = false;
	system.defaults.trackpad.TrackpadThreeFingerDrag = true;

	system.defaults.dock.autohide = true;

	security.pam.enableSudoTouchIdAuth = true;

	programs = {
		zsh = {
			enable = true;
		};
	};
}
