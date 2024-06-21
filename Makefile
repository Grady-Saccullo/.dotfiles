NIX_SYSTEM_NAME ?= personal

switch:
	set -x
	nix build --extra-experimental-features nix-command --extra-experimental-features flakes ".#darwinConfigurations.${NIX_SYSTEM_NAME}.system"
	./result/sw/bin/darwin-rebuild switch --flake "$$(pwd)#${NIX_SYSTEM_NAME}"

