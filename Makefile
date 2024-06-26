NIX_SYSTEM_NAME ?= personal

UNAME := $(shell uname)
IS_NIXOS := $(shell grep -q 'ID=nixos' /etc/os-release && echo true || echo false)

switch:
ifeq ($(UNAME), Darwin)
	nix build \
		--extra-experimental-features 'nix-command flakes' \
		"$$(pwd)#darwinConfigurations.${NIX_SYSTEM_NAME}.system"
	./result/sw/bin/darwin-rebuild --flake "$$(pwd)#${NIX_SYSTEM_NAME}"
else
ifeq ($(IS_NIXOS),true)
	sudo nixos-rebuild switch --flake "$$(pwd)#${NIX_SYSTEM_NAME}"
else
	@echo "not implemented ${UNAME}"
endif
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
ifeq ($(IS_NIXOS),true)
	sudo nixos-rebuild test --flake "$$(pwd)#${NIX_SYSTEM_NAME}" --impure
else
	@echo "not implemented ${UNAME}"
endif
endif
