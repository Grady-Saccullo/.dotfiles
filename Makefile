NIX_SYSTEM_NAME ?= personal

switch:
	set -x
	nix build --extra-experimental-features nix-command --extra-experimental-features flakes "$$(pwd)#darwinConfigurations.${NIX_SYSTEM_NAME}.system"
	./result/sw/bin/darwin-rebuild switch --flake "$$(pwd)#${NIX_SYSTEM_NAME}"


test:
	set -x
	nix build --show-trace --verbose --extra-experimental-features nix-command --extra-experimental-features flakes "$$(pwd)#darwinConfigurations.${NIX_SYSTEM_NAME}.system"
	./result/sw/bin/darwin-rebuild test --flake "$$(pwd)#${NIX_SYSTEM_NAME}"

