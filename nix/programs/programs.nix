{ pkgs, ... }:
{
	imports = [
		./wezterm.nix
		(import ./tmux.nix { inherit pkgs; })
		(import ./neovim.nix { inherit pkgs; })
	];
}
