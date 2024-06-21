{
  description = "Personal nix config";

  inputs = {
	nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
	nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

	home-manager = {
		url = "github:nix-community/home-manager/release-24.05";
		inputs.nixpkgs.follows = "nixpkgs";
	};

	# darwin specific inputs
	darwin = {
		url = "github:LnL7/nix-darwin";
		inputs.nixpkgs.follows = "nixpkgs";
	};
	nix-homebrew = {
		url = "github:zhaofengli-wip/nix-homebrew";
	};
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    }; 
  };

  outputs = { self, nixpkgs, home-manager, darwin, ... } @ inputs: let
	  overlays = import ./overlays { inherit inputs; };
		# TODO: create builder to make these consistent and easy refactoring
		darwinSystems = [
			{
				system = "aarch64-darwin";
				config = "personal";
				user = "hackerman";
			}
		];
		linuxSystems = [
			{
				system = "aarch64-linux";
				config = "personal";
				user = "hackerman";
			}
		];
		extractedSystems = map (s: s.system) (darwinSystems ++ linuxSystems);
		allSystems = fn: nixpkgs.lib.genAttrs extractedSystems fn;

	  mkConfig = import ./lib/mk-config.nix {
		  inherit overlays nixpkgs inputs;
	  };

	  devShell = system: let pkgs = nixpkgs.legacyPackages.${system}; in {
		  default = with pkgs; mkShell {
			  nativeBuildInputs = with pkgs; [ bashInteractive git jq ];
			  shellHook = ''
				  export EDITOR=nvim
			  '';
		  };
	  };
  in {
	  devShells =  allSystems devShell;
	  darwinConfigurations = nixpkgs.lib.genAttrs (map (s: s.config) darwinSystems) (config:
			let 
				cfg = builtins.elemAt (builtins.filter (s: s.config == config) darwinSystems) 0;
			in
			  mkConfig cfg.config {
				  system = cfg.system;
				  user = cfg.user;
			  }
		);
	  # darwinConfigurations.mbp = mkConfig "macos" {
		 #  system = "aarch64-darwin";
		 #  user = "hackerman";
	  # };
  };
}
