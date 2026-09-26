# A complete flake that builds a Mac on this framework. Copy flake.nix and default.nix into a new
# repo to start your own; hosts/README.md walks through it.
{
  description = "My Macs, built on Grady-Saccullo/.dotfiles";

  # Nix only reads nixConfig from the flake being run, so a binary cache has to be set here.
  # nixConfig = {
  #   extra-substituters = ["https://<your-cache>.cachix.org"];
  #   extra-trusted-public-keys = ["<your-cache>.cachix.org-1:<public key>"];
  # };

  inputs = {
    dotfiles.url = "github:Grady-Saccullo/.dotfiles";

    # Pins the framework's own inputs in this flake's lock, so `nix run .#update` here updates
    # everything. Keep the list in step with the inputs in the framework's flake.nix.
    dotfiles.inputs = {
      darwin.follows = "darwin";
      flake-parts.follows = "flake-parts";
      home-manager.follows = "home-manager";
      homebrew-cask.follows = "homebrew-cask";
      homebrew-core.follows = "homebrew-core";
      nix-homebrew.follows = "nix-homebrew";
      nixpkgs-unstable.follows = "nixpkgs-unstable";
    };
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-unstable";
    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core.url = "github:homebrew/homebrew-core";
    homebrew-core.flake = false;
    homebrew-cask.url = "github:homebrew/homebrew-cask";
    homebrew-cask.flake = false;
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Extra package sources, handed to the framework below through `overlays` and `channels`.
    llm-agents.url = "github:numtide/llm-agents.nix";
    nixpkgs-26_05.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = inputs: {
    # `nix run .#switch <host>`, `.#test`, `.#update` and `.#format`, plus `nix develop`.
    inherit (inputs.dotfiles) apps devShells;

    darwinConfigurations.example = inputs.dotfiles.lib.mkDarwinHost {
      system = "aarch64-darwin";
      user = "example";
      overlays = [inputs.llm-agents.overlays.shared-nixpkgs];
      channels.v26_05 = inputs.nixpkgs-26_05;
      modules = [
        ./default.nix
        ({pkgs, ...}: {
          applications.claude-code.package = pkgs.llm-agents.claude-code;
          applications.github-cli.package = pkgs.channels.v26_05.gh;
        })
      ];
    };
  };
}
