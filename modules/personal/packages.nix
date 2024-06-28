{ pkgs, ... }:
let 
	isLinux = pkgs.stdenv.isLinux;
in with pkgs; [
	asciinema
	bat
	gh
	htop
	jq
	nodejs_22
	ripgrep
	tree
	alejandra
] ++ (lib.optionals isLinux [
	git-credential-oauth
	spice-vdagent

	brave
	firefox
	spotify
])
