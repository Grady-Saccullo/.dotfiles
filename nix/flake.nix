{
  description = "Personal Config";

  inputs = {
	nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
	nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
	darwin.url = "github:LnL7/nix-darwin";
	darwin.inputs.nixpkgs.follows = "nixpkgs";
	home-manager.url = "github:nix-community/home-manager/release-24.05";
	home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
  	self,
	home-manager,
	darwin,
	...
  } @ inputs: let
  	inherit (self) outputs;
  in {
	  overlays = import ./overlays.nix { inherit inputs; };

	  darwinConfigurations = {
		  "Hackermans-MacBook-Pro-2" = darwin.lib.darwinSystem {
			system = "aarch64-darwin";
			specialArgs = { inherit inputs outputs; };
			modules = [
				./hosts/mac-os/configuration.nix
				home-manager.darwinModules.home-manager
				{
					home-manager.useGlobalPkgs = true;
					home-manager.users.hackerman = import ./home.nix;
					users.users.hackerman.home = "/Users/hackerman";
					home-manager.extraSpecialArgs = { inherit inputs outputs; };
				}
			];
		  };
	  };
  };
}
