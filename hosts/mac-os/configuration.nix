{ pkgs, ... }: 
{
	imports = [
		./homebrew.nix
	];

	environment.systemPackages = with pkgs; [
		home-manager
	];

	environment.darwinConfig = "$HOME/.dotfiles/hosts/mac-os/configuration.nix";

	services.nix-daemon.enable = true;

	nix = {
		# dont want to use unstable here as there seems to be a bug with
		# <flake>?submodules=1
		# need to look into this and possible open pr
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

	system.defaults.NSGlobalDomain."com.apple.keyboard.fnState" = true;
	system.defaults.trackpad.TrackpadThreeFingerDrag = true;

	security.pam.enableSudoTouchIdAuth = true;

	programs = {
		zsh = {
			enable = true;
		};
	};
}
