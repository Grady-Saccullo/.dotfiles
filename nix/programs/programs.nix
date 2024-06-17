@inputs{ inputs }:
{
	imports = [
		./wezterm.nix
		(import ./tmux.nix { inherit inputs; })
		(import ./neovim.nix { inherit inputs; })
	];
}
