{
  description = "Nix system manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

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

  outputs = {
    self,
    nixpkgs,
    home-manager,
    darwin,
    nix-homebrew,
    homebrew-core,
    homebrew-cask,
    homebrew-bundle,
    wezterm,
    ...
  } @ inputs: let
    helpers = import ./lib/helpers.nix {inherit nixpkgs;};
    overlays = import ./overlays {inherit inputs;};
    nix-config = import ./.nix-config.nix;
    darwinSystems = [
      (helpers.mkSystemConfig {
        system = "aarch64-darwin";
        machine = "darwin";
        module = "personal";
        user = "hackerman";
      })
      (helpers.mkSystemConfig {
        system = "aarch64-darwin";
        machine = "darwin";
        module = "work-voze";
        user = "hackerman";
      })
    ];
    nixosSystems = [
      (helpers.mkSystemConfig {
        system = "aarch64-linux";
        machine = "nixos-vm-fusion";
        module = "personal";
        user = "hackerman";
      })
    ];
    genericLinuxSystems = [
      (helpers.mkSystemConfig {
        system = "aarch64-linux";
        machine = "fedora";
        module = "personal";
        user = "hackerman";
      })
    ];

    all-systems = map (cfg: cfg.system) (
      darwinSystems
      ++ nixosSystems
      ++ genericLinuxSystems
    );
    iterSystems = fn: nixpkgs.lib.genAttrs all-systems fn;

    mkConfig = import ./lib/mk-config.nix {
      inherit overlays nixpkgs inputs;
    };

    devShell = system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = with pkgs;
        mkShell {
          nativeBuildInputs = with pkgs; [bashInteractive git jq];
          shellHook = ''
            export EDITOR=nvim
            export NIX_CONFIG_MACHINE=${nix-config.machine}
            export NIX_CONFIG_MODULE=${nix-config.module}
          '';
        };
    };
    mkApp = system: name: {
      type = "app";
      program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin name ''
        #!/usr/bin/env bash
        PATH=${inputs.alejandra.defaultPackage.${system}}./bin:$PATH
        echo "Running ${name} for ${system}"
        exec ${self}/apps/${name}
      '')}/bin/${name}";
    };
    makeApps = system: {
      "switch" = mkApp system "switch";
      "test" = mkApp system "test";
      "format" = mkApp system "format";
    };
  in {
    apps = iterSystems makeApps;
    devShells = iterSystems devShell;
    darwinConfigurations = helpers.genSystemConfig darwinSystems mkConfig;
    nixosConfigurations = helpers.genSystemConfig nixosSystems mkConfig;
    homeManagerConfigurations = helpers.genSystemConfig genericLinuxSystems mkConfig;
  };
}
