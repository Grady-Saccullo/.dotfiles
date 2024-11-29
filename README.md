# Dotty Files

This config/setup is dependent on nix. A lot of inspiration for this setup came
from [dustinlyons/nixos-config](https://github.com/dustinlyons/nixos-config/tree/main)
and [mitchellh/nixos-config](https://github.com/mitchellh/nixos-config/tree/main).
Highly recommend looking into these repos.

The goal of the setup is to allow for easily creating new config types, `module-name`, for a given machine.
This does mean the code can be a bit tricky to follow, specifically in the entry flake.nix.

## Getting Started
- Have a valid nix installation (nix/nixos)
- Create a nix shell with necessary tooling for initial setup: `nix-shell -p gnumake git vim`.
- Clone repo
- Copy `example.nix-config.nix` -> `./.nix-config.nix` and update `machine`/`module` with corresponding config available in flake.nix
- Pull down submodules if necessary
- Leave nix shell and enter `nix develop`
- Run `nix run .#switch`
- Run setup again to link config repos to config locations


## Project Structure

Naming conventions used below:
- `module-name`: the name for a specific config, e.g. `personal`, `work`, `slim-dev`
- `machine-name`: the name for a specific machine, e.g. `darwin`, `nixos`, `nixos-vm-fusion`, `fedora`

### `/apps`
Contains scripts available within a nix develop shell.

Run with nix run `.#<command>`.

- `switch`: build and switch configuration
- `test`: test the current configuration
- `format`: format the repo with [alejandra](https://github.com/kamadorueda/alejandra)

### `/lib`
Contains helpers/common functions for nix.

### `/machines`
Contains machine related nix configs. These are the shared base machines to be pulled into
`/modules/<module-name>/machine-<machine-name>.nix`.

Here is an example:
We have a nixos vm which we want to run on VMWare Fusion. We will need to setup the system
to work with Fusion and there for we need to create a base nixos fusion machine which should
be reusable anytime we want to spin up a nixos fusion vm no matter the config we are 
attempting to use with it. We will put this under `/machines/nixos-vm-fusion.nix`. Inside
`/modules/<module-name>` we will create another file and call it `machine-nixos-vm-fusion.nix`.
You can see the parity here in naming schema, but this now allows us to extend the existing
machine config for a system `module-name`.

### `/modules/shared` 
Contains shared programs, packages etc for various modules.

### `/modules/<module-name>` 
Contains all files related to a given config type.

Files prefixed with `machine-<machine-name>` are use for a given machine type for the
specific config. This means we could have `machine-darwin.nix`, `machine-nixos.nix`,
`machine-nixos-fusion-vm.nix`, `machine-fedora.nix`, and so on... All of these machine
types will share the same home manager, since they are under a specific module name,
eg `personal`. These specific machine configs can then pull in the base machine from
`/machines/<machine-name>.nix` making easily reusable.

### `/overlays`
Contains overlays, specifically only need package overlays for now so there is only
a default.nix file in there.
