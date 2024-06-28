{ ... }:
{
	homebrew = {
		enable = true;

		casks = [
			"betterdisplay"
			"brave-browser"
			"discord"
			"docker"
			"slack"
			"soundsource"
			"spotify"
			"utm"
		];
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
}
