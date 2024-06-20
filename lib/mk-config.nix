{ nixpkgs, overlays, inputs }:

# e.g. macos
systemName:

# settings specific to each system
{
	# aarch64-darwin, aarch64-linux etc etc
	system,
	# user name for a given system,
	user
}:

let
	lib = import <nixpkgs/lib>;
	darwin =  lib.strings.hasSuffix "-darwin" system;
	machineConfig = ../machines/${systemName}.nix;
	userOSConfig = ../users/${user}/config-os-${if darwin then "darwin" else "nixos" }.nix;
	HMConfig = ../users/${user}/config-home-manager.nix;

	systemFn = if darwin then inputs.darwin.lin.darwinSystem else nixpkgs.lib.nixosSystem;
	HMModule = if darwin then inputs.home-manager.darwinModules else inputs.home-manager.nixosModules;
in systemFn rec {
	inherit system;

	modules = [
		{ nixpkgs.overlays = overlays; }

		machineConfig
		userOSConfig

		HMModule.home-manager.home-manager {
			useGlobalPkgs = true;
			useUserPackages = true;
			users.${user} = import HMConfig {
				inputs = inputs;
			};
		}

		{
			config._module.args = {
				currentSystem = system;
				currentSystemName = systemName;
				currentSystemUser = user;
				inputs = inputs;
			};
		}
	];
}
