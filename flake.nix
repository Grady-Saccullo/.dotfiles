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
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
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

    # NixOS / homelab
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # Optional: a *private* repo holding non-secret-but-private homelab data
    # (device inventories, MAC addresses, network topology). Secrets proper
    # live encrypted in ./secrets via sops-nix and are safe in this public
    # repo; this input is only for things you'd rather not publish in plain
    # text. See docs/homelab.md "Secrets and private data".
    #
    # homelab-private.url = "git+ssh://git@github.com/grady-saccullo/homelab-private";
    # homelab-private.flake = false;

    # Applications
    llm-agents.url = "github:numtide/llm-agents.nix";
    wezterm.url = "github:wezterm/wezterm?dir=nix";
  };

  outputs = inputs @ {self, ...}: let
    overlays = [(import ./overlays {inherit inputs;})];

    # Darwin machines: unstable as the base package set (see overlays/).
    pkgsFor = system:
      import inputs.nixpkgs-unstable {
        localSystem = system;
        inherit overlays;
        config = {
          allowUnfree = true;
          allowUnsupportedSystem = true;
        };
      };

    # NixOS servers: the *stable* release as the base package set, so the
    # service modules (home-assistant, adguardhome, ...) and their packages
    # move in lockstep with the release branch. `pkgs.unstable.*` is still
    # available through the overlay for individual newer packages.
    stablePkgsFor = system:
      import inputs.nixpkgs {
        localSystem = system;
        inherit overlays;
        config.allowUnfree = true;
      };

    mkDarwinHost = {
      system,
      user,
      configPath,
    }: let
      machineType = "darwin";
      me = {inherit user;};
    in
      inputs.darwin.lib.darwinSystem {
        inherit system;
        specialArgs = {
          inherit inputs me machineType;
          utils = import ./modules/flake-parts/utils.nix {
            inherit me machineType;
            inherit (inputs.nixpkgs-unstable) lib;
          };
        };
        modules = [
          configPath
          ./modules/flake-parts/common.nix
          {
            nixpkgs.hostPlatform = system;
            nixpkgs.pkgs = pkgsFor system;
          }
        ];
      };

    mkNixosHost = {
      system,
      user,
      hostName,
      configPath,
    }: let
      machineType = "nixos";
      me = {inherit user;};
    in
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs me machineType hostName;
          utils = import ./modules/flake-parts/utils.nix {
            inherit me machineType;
            inherit (inputs.nixpkgs) lib;
          };
        };
        modules = [
          configPath
          ./modules/flake-parts/common.nix
          {
            networking.hostName = hostName;
            nixpkgs.hostPlatform = system;
            nixpkgs.pkgs = stablePkgsFor system;
          }
        ];
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
        _module.args.pkgs = pkgsFor system;
      };

      flake = {
        constants = {
          stateVersion = "26.05";
          darwinStateVersion = 6;
        };

        applications = ./modules/applications;

        homeManagerModules = {
          darwinModule = ./modules/home-manager/darwin.nix;
          nixosModule = ./modules/home-manager/nixos.nix;
        };

        darwinModules = {
          sensible = ./modules/darwin/sensible.nix;
        };

        nixosModules = {
          sensible = ./modules/nixos/sensible.nix;
          homelab = ./modules/homelab;
        };

        darwinConfigurations = {
          personal = mkDarwinHost {
            system = "aarch64-darwin";
            user = "hackerman";
            configPath = ./configurations/personal-darwin.nix;
          };

          voze = mkDarwinHost {
            system = "aarch64-darwin";
            user = "grady-saccullo";
            configPath = ./configurations/voze-darwin.nix;
          };
        };

        nixosConfigurations = {
          # Raspberry Pi 4 homelab node: DNS, Home Assistant, Zigbee, MQTT.
          # Build the SD/SSD image with:
          #   nix build .#nixosConfigurations.hackerpi.config.system.build.images.sd-card
          # Deploy to a running host with:
          #   nix run .#deploy hackerpi
          hackerpi = mkNixosHost {
            system = "aarch64-linux";
            user = "hackerman";
            hostName = "hackerpi";
            configPath = ./configurations/hackerpi-nixos.nix;
          };
        };
      };
    };
}
