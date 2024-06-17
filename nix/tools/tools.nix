
{ pkgs, ...}:
{
	imports = [
		./wezterm.nix
		(import ./tmux.nix { inherit pkgs; })
	];
}
