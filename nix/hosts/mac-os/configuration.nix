{ pkgs, ... }: 
{
	imports = [
		./homebrew.nix
	];


	# nixpkgs = {
	# 	overlays = [
	# 		outputs.overlays.unstable-packages
	# 	];
	# 	config = {
	# 		allowUnfree = true;
	# 	};
	# };

	environment.systemPackages = with pkgs; [
		home-manager
	];

	environment.darwinConfig = "$HOME/.dotfiles/nix/hosts/mac-os/configuration.nix";

	services.nix-daemon.enable = true;

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
