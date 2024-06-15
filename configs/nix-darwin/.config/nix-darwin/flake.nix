{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
	nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";
	home-manager.url = "github:nix-community/home-manager/release-24.05";
	home-manager.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  outputs = inputs @ { self, ... }:
  {
	  darwinConfigurations = {
		  "Hackermans-MacBook-Pro-2" = inputs.darwin.lib.darwinSystem {
			system = "aarch64-darwin";
			specialArgs = { inherit inputs; };
			modules = [
				./configuration.nix
				inputs.home-manager.darwinModules.home-manager
				{
					home-manager = {
						useGlobalPkgs = true;
						useUserPackages = true;
						users.hackerman = import ./home.nix;
					};
				}
			];
		  };
	  };
  };
}
