{
  description = "Nix system manager";

  # Personal binary cache, scoped to this flake only. Kept out of the
  # machine-wide nix-darwin substituters on purpose: as a global substituter
  # it leaked into every unrelated project, whose cache probe hits this
  # private cache unauthenticated and warns `HTTP error 401`. Scoping it here
  # means only `nix run .#switch` (operations on this flake) uses it. The
  # daemon authenticates via /etc/nix/netrc (see README).
  nixConfig = {
    extra-substituters = ["https://grady-saccullo.cachix.org"];
    extra-trusted-public-keys = [
      "grady-saccullo.cachix.org-1:eYGgNiaxvbtKg9XDaDw8POg+R92uwljqdlcE32nL9ts="
    ];
  };

  # Only what the framework's code is built on. App builds (nightlies, release pins) are the host's
  # call: an input in its own flake, fed in via mkDarwinHost's `overlays`/`channels` (README).
  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/master";

    # Utilities/Helpers
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Darwin specific packages
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-cask.flake = false;
    homebrew-cask.url = "github:homebrew/homebrew-cask";
    homebrew-core.flake = false;
    homebrew-core.url = "github:homebrew/homebrew-core";
    darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";
    darwin.url = "github:LnL7/nix-darwin";
  };

  outputs = inputs: let
    inherit (inputs.nixpkgs-unstable) lib;

    pkgsFor = {
      system,
      channels ? {},
      overlays ? [],
    }:
      import inputs.nixpkgs-unstable {
        localSystem = system;
        overlays = [(import ./overlays {inherit channels;})] ++ overlays;
        config = {
          allowUnfree = true;
          allowUnsupportedSystem = true;
        };
      };

    mkDarwinHost = {
      system,
      user,
      modules ? [],
      # Applied after this repo's overlays.
      overlays ? [],
      # Release nixpkgs sources exposed as `pkgs.channels.<name>`, e.g. { v26_05 = inputs.nixpkgs-26_05; }.
      channels ? {},
      # Merged into specialArgs after the defaults, so it can override them.
      extraSpecialArgs ? {},
      # Import darwinModules.default (sensible + home-manager + applications).
      framework ? true,
    }: let
      machineType = "darwin";
      me = {inherit user;};
    in
      inputs.darwin.lib.darwinSystem {
        inherit system;
        specialArgs =
          {
            inherit inputs me machineType;
            utils = import ./modules/flake-parts/utils.nix {
              inherit me machineType;
              inherit (inputs.nixpkgs-unstable) lib;
            };
          }
          // extraSpecialArgs;
        modules =
          lib.optional framework inputs.self.darwinModules.default
          ++ [
            {
              nixpkgs.hostPlatform = system;
              nixpkgs.pkgs = pkgsFor {inherit system channels overlays;};
            }
          ]
          ++ modules;
      };
  in
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        ./modules/flake-parts/flake.nix
        ./modules/flake-parts/devshells.nix
        ./modules/flake-parts/apps.nix
      ];

      systems = ["aarch64-darwin" "aarch64-linux"];

      perSystem = {system, ...}: {
        _module.args.pkgs = pkgsFor {inherit system;};
      };

      flake = {
        constants = {
          stateVersion = "26.05";
          darwinStateVersion = 6;
        };

        applications = ./modules/applications;

        homeManagerModules = {
          darwinModule = ./modules/home-manager/darwin.nix;
        };

        darwinModules = {
          sensible = ./modules/darwin/sensible.nix;
          # The whole framework in one module; mkDarwinHost imports it unless
          # called with `framework = false`.
          default = {
            imports = [
              ./modules/darwin/sensible.nix
              ./modules/home-manager/darwin.nix
              ./modules/applications
            ];
          };
        };

        lib = {
          inherit mkDarwinHost;
        };

        darwinConfigurations = {
          # Fixture, not a machine: a synthetic host that exercises the whole
          # module set so `nix run .#test example` type-checks it and so
          # readers can see how a host is written.
          example = mkDarwinHost {
            system = "aarch64-darwin";
            user = "example";
            modules = [./hosts/example];
          };
        };
      };
    };
}
