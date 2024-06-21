{ ... }:
{
	users.users.hackerman = {
		home = "/Users/hackerman";
	};

	# system = {
	# 	stateVersion = 4;
	#
	# 	defaults = {
	# 		dock = {
	# 			autohide = true;
	# 		};
	#
	# 		finder = {
	# 			AppleShowAllFiles = true;
	# 			QuitMenuItem = true;
	# 			_FXShowPosixPathInTitle = true;
	# 		};
	#
	# 		LaunchServices = {
	# 			LSQuarantine = true;
	# 		};
	#
	# 		NSGlobalDomain = {
	# 			"com.apple.keyboard.fnState" = true;
	# 			# I am a weirdo and like the natural scroll direction... don't ask
	# 			"com.apple.swipescrolldirection" = true;
	# 		};
	#
	# 		trackpad = {
	# 			TrackpadThreeFingerDrag = true;
	# 		};
	# 	};
	#
	# 	keyboard = {
	# 		enableKeyMapping = true;
	# 		remapCapsLockToEscape = true;
	# 	};
	# };
	#
	# security.pam.enableSudoTouchIdAuth = true;

	homebrew = {
		enable = true;

		casks = [
			# "discord"
			"betterdisplay"
			# "docker"
			# "brave-browser"
			"soundsource"
			# "spotify"
			"slack"
			"utm"
		];
	};
}
