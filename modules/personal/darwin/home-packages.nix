
{ pkgs, ... }:
let 
	shared-pkgs = import ../shared/home-packages.nix { inherit pkgs; };
in shared-pkgs
