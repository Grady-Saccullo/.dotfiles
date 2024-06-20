{
  description = "Personal nix config";

  inputs = {
	nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
	nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

	home-manager = {
		url = "github:nix-community/home-manager/release-24.05";
		inputs.nixpkgs.follows = "nixpkgs";
	};

	darwin = {
		url = "github:LnL7/nix-darwin";
		inputs.nixpkgs.follows = "nixpkgs";
	};
  };

  outputs = { self, nixpkgs, home-manager, darwin, ... } @ inputs: let
	  overlays = import ./overlays { inherit inputs; };

	  mkConfig = import ./lib/mk-config.nix {
		  inherit overlays nixpkgs inputs;
	  };
  in {
	  darwinConfigurations.mbp = mkConfig "macos" {
		  system = "aarch64-darwin";
		  user = "hackerman";
	  };
  };
}
