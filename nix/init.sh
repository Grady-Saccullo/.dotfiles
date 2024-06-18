# we need to manually handle installing nix-darwin due to having nvim as a submodule.

nix-channel --add https://github.com/LnL7/nix-darwin/archive/master.tar.gz darwin
nix-channel --add https://nixos.org/channels/nixpkgs-unstable

nix-channel --update

export NIX_PATH=darwin-config=$HOME/.dotfiles/nix/hosts/mac-os/configuration.nix:$HOME/.nix-defexpr/channels:$NIX_PATH

$(nix-build '<darwin>' -A system --no-out-link)/sw/bin/darwin-rebuild build switch --flake .?submodules=1
$(nix-build '<darwin>' -A system --no-out-link)/sw/bin/darwin-rebuild switch --flake .?submodules=1

. /etc/static/bashrc
