{
  description = "Nix system manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # packages for overlays
    alejandra = {
      url = "github:kamadorueda/alejandra/3.1.0";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    wezterm.url = "github:wez/wezterm?dir=nix";

    # darwin specific inputs
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
  };

  outputs = inputs @ {self, ...}:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        ./modules/flake-parts/config.nix
        ./modules/flake-parts/flake.nix
      ];
      systems = ["aarch64-darwin"];
      perSystem = {
        config,
        system,
        pkgs,
        ...
      }: let
        mkApp = name: {
          type = "app";
          program = "${(pkgs.writeScriptBin name ''
            #!/usr/bin/env bash
            PATH=${inputs.alejandra.defaultPackage.${system}}./bin:$PATH
            echo "Running ${name} for ${system}"
            exec ${self}/apps/${name}
          '')}/bin/${name}";
        };
      in {
        imports = [./modules/flake-parts/config.nix];
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            (final: prev: {
              unstable = import inputs.nixpkgs-unstable {
                system = final.system;
                config.allowUnfree = true;
              };
              alejandra = inputs.alejandra.defaultPackage.${final.system};
              wezterm-nightly = inputs.wezterm;
            })
          ];
          config = {
            allowUnfree = true;
            allowUnsupportedSystem = true;
          };
        };

        apps = with builtins;
          listToAttrs (
            map (appName: {
              name = appName;
              value = mkApp appName;
            })
            (attrNames (readDir ./apps))
          );

        devShells = {
          default = pkgs.mkShell {
            packages = with pkgs; [bashInteractive git jq];
            shellHook = ''
              export EDITOR=nvim
              export NIX_CONFIG_MACHINE=${config.configuration.machine}
              # TOOD: change MODULE -> NAME
              export NIX_CONFIG_MODULE=${config.configuration.name}
            '';
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
            specialArgs = {
              inherit inputs;
            };
            modules = [
              ./modules/flake-parts/config.nix
              ./modules/flake-parts/common.nix
              ./configurations/personal-darwin.nix
              {
                nixpkgs = {
                  overlays = [
                    (final: prev: {
                      unstable = import inputs.nixpkgs-unstable {
                        system = final.system;
                        config.allowUnfree = true;
                      };
                      alejandra = inputs.alejandra.defaultPackage.${final.system};
                      wezterm-nightly = inputs.wezterm;
                    })
                  ];
                  config = {
                    allowUnfree = true;
                    allowUnsupportedSystem = true;
                  };
                };
              }
            ];
          };
        };
      };
    };
}
