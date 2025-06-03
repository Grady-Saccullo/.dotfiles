{
  description = "Nix system manager";

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/master";

    # Utilities/Helpers
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Darwin specific packages
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-bundle.flake = false;
    homebrew-bundle.url = "github:homebrew/homebrew-bundle";
    homebrew-cask.flake = false;
    homebrew-cask.url = "github:homebrew/homebrew-cask";
    homebrew-core.flake = false;
    homebrew-core.url = "github:homebrew/homebrew-core";
    darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";
    darwin.url = "github:LnL7/nix-darwin";

    # Applications
    wezterm.url = "github:wezterm/wezterm?dir=nix";
  };

  outputs = inputs @ {self, ...}:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        ./modules/flake-parts/flake.nix
        ./modules/flake-parts/devshells.nix
        ./modules/flake-parts/apps.nix
      ];
      systems = ["aarch64-darwin"];
      perSystem = {system, ...}: {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [(import ./overlays {inherit inputs;})];
          config = {
            allowUnfree = true;
            allowUnsupportedSystem = true;
          };
        };
      };
      flake = {
        constants = {
          stateVersion = "25.05";
          darwinStateVersion = 6;
        };
        applications = ./modules/applications;
        homeManagerModules = {
          darwinModule = ./modules/home-manager/darwin.nix;
        };
        darwinModules = {
          sensible = ./modules/darwin/sensible.nix;
        };
        darwinConfigurations = {
          personal = inputs.darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            specialArgs = let
              machineType = "darwin";
              me = {
                user = "hackerman";
              };
            in {
              inherit inputs me machineType;
              utils = import ./modules/flake-parts/utils.nix {
                inherit me machineType;
                inherit (inputs.nixpkgs) lib;
              };
            };
            modules = [
              ./configurations/personal-darwin.nix
              ./modules/flake-parts/common.nix
              ./modules/nixpkgs.nix
            ];
          };

          voze = inputs.darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            specialArgs = let
              machineType = "darwin";
              me = {
                user = "grady-saccullo";
              };
            in {
              inherit inputs me machineType;
              utils = import ./modules/flake-parts/utils.nix {
                inherit me machineType;
                inherit (inputs.nixpkgs) lib;
              };
            };
            modules = [
              ./configurations/voze-darwin.nix
              ./modules/flake-parts/common.nix
              ./modules/nixpkgs.nix
            ];
          };
        };
      };
    };
}
