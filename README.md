# Dotty Files

This config is highly dependent on nix. A lot of inspiration for this setup came
from [dustinlyons/nixos-config](https://github.com/dustinlyons/nixos-config/tree/main)
and [mitchellh/nixos-config](https://github.com/mitchellh/nixos-config/tree/main).

The goal of the setup is to allow for easily creating new config types for a given machine.
This does mean the code can be a bit tricky to follow.


## Getting Started

- Install nix/use nixos
- Create a nix shell with necessary tooling for initial setup: `nix-shell -p gnumake git vim --command "export PS1='\n\[\033[1;32m\][SETUP-SHELL:\w]\$\[\033[0m\] '; exec bash"`.
- Run setup
- Pull submodules down
- Run setup again to link config repos to config locations


## Project Structure

Naming conventions used below:
- `config-type`: the name for a specific config, e.g. `personal`, `work`, `slim-dev`
- `machine-type`: the name for a specific machine, e.g. `darwin`, `nixos`, `nixos-vm-fusion`, `fedora`

### `/configs`
Contains my configs for tooling which I want to maintain outside nix. Although this does
not follow the "nix way", I personally prefer this. Specifically I like having neovim in
its own repo. This was a pain point initially, but eventually got it working as I wanted.


### `/lib`
Contains helper functions for nix.

### `/machines`
Contains machine related nix configs. These are the shared base machines to be pulled into
/modules/<config-type>/machine-<machine-type>.nix`.

Here is an example:
We have a nixos vm which we want to run on VMWare Fusion. We will need to setup the system
to work with Fusion and there for we need to create a base nixos fusion machine which should
be reusable anytime we want to spin up a nixos fusion vm no matter the config we are 
attempting to use with it. We will put this under `/machines/nixos-vm-fusion.nix`. Inside
`/modules/<config-type>` we will create another file and call it `machine-nixos-vm-fusion.nix`.
You can see the parity here in naming schema, but this now allows us to extend the existing
machine config for a system `config-type`.

### `/modules/shared` 
Contains shared programs, packages etc for all environments.


### `/modules/<config-type>` 
Contains all files related to a given config type.

Files prefixed with `machine-<config-name>` are use for a given machine type for the
specific config. This means we could have `machine-darwin.nix`, `machine-nixos.nix`,
`machine-nixos-fusion-vm.nix`, `machine-fedora.nix`, and so on... All of these machine
types will share the same home manager, since they are under a specific config type,
eg `personal`. These specific machine configs can then pull in the base machine from
`/machines/<machine-type>.nix` make this very reusable.

### `/overlays`
Contains overlays, specifically only need package overlays for now so there is only
a default.nix file in there.

### `/tooling-scripts`
Contains helper bash cli for switching and checking configs. Pulling down git repos
and more. This is still a wip, but so far has been better to live with as compared
to using a Makefile. Also just wanted to build a small bash cli as it's been a while
since I've done one.

To use the cli run `./tooling-scripts/main.sh`. Might alias this as some point in the
future to allow for easier usage, but for now this is fine.
