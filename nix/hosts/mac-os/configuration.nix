{ pkgs, ... }: 
{
	imports = [
		./homebrew.nix
	];

	environment.systemPackages = with pkgs; [
		home-manager
	];

	environment.darwinConfig = "$HOME/.dotfiles/nix";

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

	programs = {
		zsh = {
			enable = true;
		};
	};
}
