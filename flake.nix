{
  description = "Nix system manager";

  inputs = {
    alejandra.inputs.nixpkgs.follows = "nixpkgs-unstable";
    alejandra.url = "github:kamadorueda/alejandra/3.1.0";
    darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";
    darwin.url = "github:LnL7/nix-darwin";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    homebrew-bundle.flake = false;
    homebrew-bundle.url = "github:homebrew/homebrew-bundle";
    homebrew-cask.flake = false;
    homebrew-cask.url = "github:homebrew/homebrew-cask";
    homebrew-core.flake = false;
    homebrew-core.url = "github:homebrew/homebrew-core";
    nix-homebrew.inputs.nixpkgs.follows = "nixpkgs-unstable";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    wezterm.url = "github:wez/wezterm?dir=nix";
  };

  outputs = inputs @ {self, ...}:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        ./modules/flake-parts/config.nix
        ./modules/flake-parts/flake.nix
        ./modules/flake-parts/devshells.nix
        ./modules/flake-parts/apps.nix
      ];
      systems = ["aarch64-darwin"];
      perSystem = {system, ...}: {
        imports = [./modules/flake-parts/config.nix];
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
          stateVersion = "24.11";
          darwinStateVersion = 4;
        };
        applications = ./modules/applications;
        homeManagerModules = {
          darwinModule = ./modules/home-manager/darwin.nix;
        };
        darwinModules = {
          sensible = ./modules/darwin/sensible.nix;
        };
        darwinConfigurations = {
          personal-darwin = inputs.darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            specialArgs = {inherit inputs;};
            modules = [
              ./configurations/personal-darwin.nix
              ./modules/flake-parts/common.nix
              ./modules/flake-parts/config.nix
              ./modules/nixpkgs.nix
            ];
          };
        };
      };
    };
}
