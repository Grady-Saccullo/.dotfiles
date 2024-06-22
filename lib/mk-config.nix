{ nixpkgs, overlays, inputs, ... }:
config:
# TODO: create path builder for imports

let
	mk-system-modules = import ./mk-system-modules.nix { inherit nixpkgs overlays inputs; };
	config-lib = import ./mk-config-helpers.nix { inherit nixpkgs; };

	machine-config = import ../machines/${config.platform}-${config.type}.nix;
	mk-modules-path = p: ../modules/${config.type}/${config.platform}${p};

	machine-specific-imports = builtins.filter builtins.pathExists [
		import (mk-modules-path /machine-specific.nix)
		# ../modules/${config.type}/${config.platform}/machine-specific.nix
	];
	machine-module = machine-config {
		inherit machine-specific-imports;
		user = config.user;
	};
	
	home-manager-config = import (mk-modules-path /home-manager.nix);
	# home-manager-config = import ../modules/${config.type}/${config.platform}/home-manager.nix;

	home-manager-module = if config.platform == "darwin" then
		[
			(inputs.home-manager.darwinModules.home-manager)
			{
				home-manager.useGlobalPkgs = true;
				home-manager.useUserPackages = true;
				home-manager.users.${config.user} = home-manager-config;
			}
		]
	else if config.platform == "nixos" then 
		[
			(inputs.home-manager.nixosModules.home-manager)
			{
				home-manager.useGlobalPkgs = true;
				home-manager.useUserPackages = true;
				home-manager.users.${config.user} = home-manager-config;
			}
	]
	else 
		home-manager-config;

	system = config-lib.systemFromConfig config;

	out = if config.platform == "darwin" then 
		  inputs.darwin.lib.darwinSystem (mk-system-modules {
			inherit config system;
			extra-modules = [
				(machine-module)
			] ++ home-manager-module;
		})
	else if config == "nixos" then
		nixpkgs.lib.nixosSystem (mk-system-modules {
			inherit config system;
			extra-modules = [
				(machine-module)
			] ++ home-manager-module;
		})
	else
		mk-system-modules {
			inherit config system;
			extra-modules = [
				(machine-module)
			] ++ home-manager-module;
		};
in out
