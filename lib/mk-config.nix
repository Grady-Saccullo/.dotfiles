{ nixpkgs, overlays, inputs, ... }:

config:

# TODO refactor this. much of this can be reused/simplified, but it works for now while figuring out multiple systems
let
	mk-system-modules = import ./mk-system-modules.nix { inherit nixpkgs overlays inputs; };
	config-lib = import ./mk-config-helpers.nix { inherit nixpkgs; };

	machine-config = import ../machines/${config.platform}-${config.type}.nix;

	machine-specific-imports = builtins.filter builtins.pathExists [
		../modules/${config.type}/${config.platform}/machine-specific.nix
	];
	machine-module = machine-config {
		inherit machine-specific-imports;
		user = config.user;
	};
	
	home-manager-config = import ../modules/${config.type}/${config.platform}/home-manager.nix;

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
