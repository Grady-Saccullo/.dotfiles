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
	  overlays = import ./overlays.nix { inherit inputs; };
  
		# nixpkgsConf = {
		# 	config = { allowUnfree = true; };
		# 	overlays = [self.overlays.unstable-packages];
		# };
	  mkConfig = import ./lib/mk-config.nix {
		  inherit overlays nixpkgs inputs;
	  };
  in {
	  darwinConfigurations.mbp = mkConfig "macos" {
		  system = "aarch64-darwin";
		  user = "hackerman";
	  };
	  # darwinConfigurations = {
		 #  "Hackermans-MacBook-Pro-2" = darwin.lib.darwinSystem {
			# system = "aarch64-darwin";
			# specialArgs = { inherit inputs outputs; };
			# modules = [
			# 	./hosts/darwin/configuration.nix
			# 	home-manager.darwinModules.home-manager
			# 	{
			# 		nixpkgs = nixpkgsConf;
			# 		home-manager.useGlobalPkgs = true;
			# 		home-manager.users.hackerman = import ./home.nix;
			# 		users.users.hackerman.home = "/Users/hackerman";
			# 		home-manager.extraSpecialArgs = { inherit inputs outputs; };
			# 	}
			# ];
		 #  };
	  # };
  };
}
