{
  description = "Personal Config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
	home-manager.url = "github:nix-community/home-manager/release-24.05";
	home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ { self, ... }:
  {
	  darwinConfigurations = {
		  "Hackermans-MacBook-Pro-2" = inputs.darwin.lib.darwinSystem {
			system = "aarch64-darwin";
			specialArgs = { inherit inputs; };
			modules = [
				./hosts/mac-os/configuration.nix
				inputs.home-manager.darwinModules.home-manager
				{
					home-manager.users.hackerman = import ./home.nix;
					users.users.hackerman.home = "/Users/hackerman";
				}
			];
		  };
	  };
  };
}
