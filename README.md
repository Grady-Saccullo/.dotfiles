# Dotty Files

> Readme is now accurate but still a wip for new very modular setup

## Getting Started
- Have a valid nix installation (nix/nixos)
- Create a nix shell with necessary tooling for initial setup: `nix-shell -p gnumake git`.
- Clone repo
- Run `nix run .#switch <config-name>`

## Project Structure

### `/apps`
Contains scripts available within a nix develop shell.

Run with nix run `.#<command>`.

- `switch`: build and switch configuration
- `test`: test the current configuration
- `format`: format the repo with [alejandra](https://github.com/kamadorueda/alejandra)


### `/configurations`
Contains the root machine confis which get pulled into the main flake.nix. All of these
configurations are built upon the modules pulled into the root flake.nix.

### `/modules/applications` 
Contains all of the shared "applications" which can be turned on through .enable. The reasoning
for this style was so that I could easily share a given application between multiple machine
types (`darwin`, `nixos`, or `linux` which is just any other distro not nixos). I wasn't a fan of
how many configs spread applications to be shared across multiple files and felt this made 
upkeep more painful so this was my solution. Even though this is called application it contains
anything from gui applications to toolling to a cli.

### `/modules/darwin`
Contains shared darwin configurations to be pulled into `/configurations` through the `darwinModules`
set in the root flake.nix. Currently only contains `sensible`.

### `/modules/flake-parts` 
Contains shared options/imports for the root flake.nix to be used with flake-parts. Some things
in here such as utils are not actually flake-parts specific and probably need to be refactored out.

### `/modules/home-manager`
Contains shared per platform homemanager configurations to be pulled into `/configurations`
through the `homeManagerModules` set in the root flake.nix. Currently only contains `darwin`.

### `/overlays`
Contains overlays, specifically only need package overlays for now so there is only
a default.nix file in there.

---
##### Notes

A lot of initial inspiration for my config came
from [dustinlyons/nixos-config](https://github.com/dustinlyons/nixos-config/tree/main)
and [mitchellh/nixos-config](https://github.com/mitchellh/nixos-config/tree/main).
Highly recommend looking into these repos if you are just getting into nix.
