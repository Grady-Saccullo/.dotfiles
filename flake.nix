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
		darwinSystems = [
			{
				system = "aarch64-darwin";
				type = "personal";
			}
		];
		linuxSystems = [
			{
				system = "aarch64-linux";
				type = "personal";
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
	  darwinConfigurations = nixpkgs.lib.genAttrs (map (s: s.type) darwinSystems) (type:
			let 
				config = builtins.elemAt (builtins.filter (s: s.type == type) darwinSystems) 0;
			in
			  mkConfig config.type {
				  system = config.system;
				  user = "hackerman";
			  }
		);
	  # darwinConfigurations.mbp = mkConfig "macos" {
		 #  system = "aarch64-darwin";
		 #  user = "hackerman";
	  # };
  };
}
