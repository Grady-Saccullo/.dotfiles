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
	isDarwin = nixpkgs.lib.strings.hasSuffix "-darwin" system;
	modulePath = ../modules/${configType}/${if isDarwin then "darwin" else "${system}"};

	machineConfig = import ../machines/darwin-${configType}.nix;
	machine-specific-imports = builtins.filter builtins.pathExists [
		./${modulePath}/machine-specific.nix
	];
	
	HMConfig = import ./${modulePath}/home-manager.nix;

	systemFn = if isDarwin then inputs.darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
	HMModule = if isDarwin then inputs.home-manager.darwinModules else inputs.home-manager.nixosModules;
in systemFn rec {
	inherit system;

	modules = [
		{
			nixpkgs.overlays = [
				overlays.unstable-packages
			];

			nixpkgs.config = { allowUnfree = true; };
		}

		(machineConfig { inherit user machine-specific-imports; } )
		# userOSConfig

		HMModule.home-manager {
			home-manager.useGlobalPkgs = true;
			home-manager.useUserPackages = true;
			home-manager.users.${user} = HMConfig;
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
