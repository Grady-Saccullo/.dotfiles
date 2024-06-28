{
  description = "Nix system manager";

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
		config-lib = import ./lib/mk-config-helpers.nix { inherit nixpkgs; };
		overlays = import ./overlays { inherit inputs; };

		darwinSystems = [
			(config-lib.mkSystemConfig {
				system = "aarch64-darwin";
				configName = "darwin";
				configType = "personal";
				user = "hackerman";
			})
		];
		nixosSystems = [
			(config-lib.mkSystemConfig {
				system = "aarch64-linux";
				configName = "nixos";
				configType = "personal";
				user = "hackerman";
			 })
		];
		genericLinuxSystems = [
			(config-lib.mkSystemConfig {
				system = "aarch64-linux";
				configName = "fedora";
				configType = "personal";
				user = "hackerman";
			 })
		];

		all-systems = map (cfg: cfg.system) (
			darwinSystems ++
			nixosSystems ++
			genericLinuxSystems
		);
		iterSystems = fn: nixpkgs.lib.genAttrs all-systems fn;

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
	  devShells = iterSystems devShell;
	  darwinConfigurations = config-lib.genSystemConfig darwinSystems mkConfig;
	  nixosConfigurations = config-lib.genSystemConfig nixosSystems mkConfig;
	  homeManagerConfigurations = config-lib.genSystemConfig genericLinuxSystems mkConfig;
  };
}
