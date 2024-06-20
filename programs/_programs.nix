{ pkgs, inputs, config, ... }:
{
	imports = [
		./wezterm.nix
		./direnv.nix
		./zsh.nix
		./git.nix
		(import ./tmux.nix { inherit pkgs; })
		(import ./neovim.nix { inherit pkgs inputs config; })
	];
}
