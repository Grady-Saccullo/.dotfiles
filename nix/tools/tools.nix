
{ pkgs, ...}:
{
	inherit pkgs;
	imports = [
		./wezterm.nix
	];
}
