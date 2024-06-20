
NIX_CONFIG_NAME ?= mbp

switch:
	nix build \
		--extra-experimental-features nix-command \
		--extra-experimental-features flakes \
		".#darwinConfigurations.${NIX_CONFIG_NAME}.system"
	./result/sw/bin/darwin-rebuild switch --flake "$(pwd)#${NIX_CONFIG_NAME}" --verbose

