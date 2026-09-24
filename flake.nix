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

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Release channels. Every input named `nixpkgs-<major>_<minor>` is exposed
    # as `pkgs.channels.v<major>_<minor>` by overlays/channels.nix, for
    # pinning a single package to a release; base `pkgs` stays
    # nixpkgs-unstable (darwin compatibility).
    nixpkgs-26_05.url = "github:NixOS/nixpkgs/nixos-26.05";
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
    llm-agents.url = "github:numtide/llm-agents.nix";
    wezterm.url = "github:wezterm/wezterm?dir=nix";
  };

  outputs = inputs: let
    inherit (inputs.nixpkgs-unstable) lib;

    pkgsFor = system: extraOverlays:
      import inputs.nixpkgs-unstable {
        localSystem = system;
        overlays = [(import ./overlays {inherit inputs;})] ++ extraOverlays;
        config = {
          allowUnfree = true;
          allowUnsupportedSystem = true;
        };
      };

    nixpkgsModule = system: extraOverlays: {
      nixpkgs.hostPlatform = system;
      nixpkgs.pkgs = pkgsFor system extraOverlays;
    };

    # Builds a nix-darwin system on top of this repo's framework. Exported as
    # `lib.mkDarwinHost` so the private dotfiles flake, which consumes this
    # repo as input `dotfiles`, can define its hosts with the same module set,
    # special args and overlays and layer private modules/overlays on top.
    mkDarwinHost = {
      system,
      user,
      modules ? [],
      # Extra nixpkgs overlays, applied after this repo's own (private packages).
      overlays ? [],
      # Merged into specialArgs after the defaults (e.g. { privateInputs = inputs; }).
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
          ++ [(nixpkgsModule system overlays)]
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
        _module.args.pkgs = pkgsFor system [];
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

        # Library for downstream flakes. The private dotfiles repo imports this
        # flake as `dotfiles` and defines every real host through
        # `inputs.dotfiles.lib.mkDarwinHost`; this repo itself ships no real
        # host.
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
