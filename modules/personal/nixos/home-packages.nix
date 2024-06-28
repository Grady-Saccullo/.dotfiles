{ pkgs, ... }:
with pkgs;
let 
	shared-pkgs = import ../shared/home-packages.nix { inherit pkgs; };
in shared-pkgs ++ [
	git-credential-oauth
	spice-vdagent

	brave
	firefox
	spotify
]
