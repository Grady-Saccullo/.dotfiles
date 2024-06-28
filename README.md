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

### `/configs`
Contains my configs for tooling which I want to maintain outside nix. Although this does
not follow the "nix way", I personally prefer this. Specifically I like having neovim in
its own repo. This was a pain point initially, but eventually got it working as I wanted.


### `/lib`
Contains helper functions for nix.


### `/machines`
Contains machine related nix configs. The naming scheme is very import here as we import
files dynamically via name. eg `darwin-personal.nix` is pulled in when the personal config
for a darwin os is desired. Eventually this will contain more configs such as `rbp-dev.nix`,
`linux-personal.nix` and `linux-dev.nix`.


### `/modules/shared` (WIP)
Contains shared configs for all environments.


### `/modules/<config-type>/<platform>` (WIP)
Contains all files related to a given config type for a given platform.

There is a "special" file in here called `machine-specific.nix`. This file gets injected
back into the imports of the corresponding `/machines` file. I wanted to keep all
program/non-os setup configs in modules to make it easier to discover what is being added
on top of the system. Anything which modifies the underlying system (machine) should go in
`/machine`.


### `/overlays` (WIP)
Contains shared overlays nix.
