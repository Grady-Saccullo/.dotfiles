{ nixpkgs, overlays, inputs }:

# e.g. personal
configType:

# settings specific to each system
{
	# aarch64-darwin, aarch64-linux etc etc
	system,
	# user name for a given system,
	user
}:

let
	darwin = nixpkgs.lib.strings.hasSuffix "-darwin" system;
	machineConfig = ../machines/darwin-${configType}.nix;
	
	# userOSConfig = ../users/${user}/config-os-${if darwin then "darwin" else "nixos" }.nix;
	# HMConfig = ../users/${user}/config-home-manager.nix;
	HMConfig = ../modules/${configType}/${if darwin then "darwin" else "${system}"};

	systemFn = if darwin then inputs.darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
	HMModule = if darwin then inputs.home-manager.darwinModules else inputs.home-manager.nixosModules;
in systemFn rec {
	inherit system;

	modules = [
		{
			nixpkgs.overlays = [
				overlays.unstable-packages
			];

			nixpkgs.config = { allowUnfree = true; };
		}

		(machineConfig user)
		# userOSConfig

		HMModule.home-manager {
			home-manager.useGlobalPkgs = true;
			home-manager.useUserPackages = true;
			home-manager.users.${user} = import HMConfig user {
				inputs = inputs;
			};
		}

		{
			config._module.args = {
				currentSystem = system;
				currentConfigType = configType;
				currentSystemUser = user;
				inputs = inputs;
			};
		}
	];
}
