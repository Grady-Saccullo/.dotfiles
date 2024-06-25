NIX_SYSTEM_NAME ?= personal

UNAME := $(shell uname)

switch:
ifeq ($(UNAME), Darwin)
	nix build \
		--extra-experimental-features 'nix-command flakes' \
		"$$(pwd)#darwinConfigurations.${NIX_SYSTEM_NAME}.system"
	 ./result/sw/bin/darwin-rebuild --flake "$$(pwd)#${NIX_SYSTEM_NAME}"
else
	@echo "not implemented ${UNAME}"
endif

check:
ifeq ($(UNAME), Darwin)
	nix build \
		--show-trace \
		--verbose \
		--extra-experimental-features 'nix-command flakes' \
		"$$(pwd)#darwinConfigurations.${NIX_SYSTEM_NAME}.system"
	 ./result/sw/bin/darwin-rebuild check --flake "$$(pwd)#${NIX_SYSTEM_NAME}"
else
	@echo "not implemented ${UNAME}"
endif
