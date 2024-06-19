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

	system = {
		stateVersion = 4;

		defaults = {
			dock = {
				autohide = true;
			};

			finder = {
				AppleShowAllFiles = true;
				QuitMenuItem = true;
				_FXShowPosixPathInTitle = true;
			};

			LaunchServices = {
				LSQuarantine = true;
			};

			NSGlobalDomain = {
				"com.apple.keyboard.fnState" = true;
				# I am a weirdo and like the natural scroll direction... don't ask
				"com.apple.swipescrolldirection" = true;
			};

			trackpad = {
				TrackpadThreeFingerDrag = true;
			};
		};

		keyboard = {
			enableKeyMapping = true;
			remapCapsLockToEscape = true;
		};
	};

	security.pam.enableSudoTouchIdAuth = true;

	programs = {
		zsh = {
			enable = true;
		};
	};
}
