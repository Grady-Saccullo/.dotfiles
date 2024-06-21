# nix-darwin base config for personal
{ config, pkgs, ... }:
{
	nix.useDaemon = true;
	nix = {
		extraOptions = ''
			experimental-features = nix-command flakes
		'';
	};

	programs.zsh = {
		enable = true;

		shellInit = ''
			# Nix
			if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
			  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
			fi
			# End Nix
		'';
	};

	environment.shells = with pkgs; [ bashInteractive zsh ];

	# environment.darwinConfig = "$HOME/.dotfiles/machines/macos.nix";

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
				# Make function keys stay function keys
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
}
