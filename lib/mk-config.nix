{ nixpkgs, overlays, inputs, ... }:

systemConfig:

# TODO refactor this. much of this can be reused/simplified, but it works for now while figuring out multiple systems
let
	mk-system-modules = import ./mk-system-modules.nix { inherit nixpkgs overlays inputs; };
	machine-module = import ../modules/${systemConfig.configType}/machine-${systemConfig.configName}.nix;

	home-manager-config = import ../modules/${systemConfig.configType}/home-manager.nix;

	is-platform = p: nixpkgs.lib.strings.hasInfix p systemConfig.configName;

	home-manager-module = if is-platform "darwin" then
		[
			(inputs.home-manager.darwinModules.home-manager)
			{
				home-manager.useGlobalPkgs = true;
				home-manager.useUserPackages = true;
				home-manager.users.${systemConfig.user} = home-manager-config;
			}
		]
	else if is-platform "nixos" then 
		[
			(inputs.home-manager.nixosModules.home-manager)
			{
				home-manager.useGlobalPkgs = true;
				home-manager.useUserPackages = true;
				home-manager.users.${systemConfig.user} = home-manager-config;
			}
	]
	else 
		home-manager-config;

	system-modules = (mk-system-modules {
			inherit systemConfig;
			system = systemConfig.system;
			extra-modules = [
				(machine-module)
			] ++ home-manager-module;
	});

	out = if is-platform "darwin" then 
		  inputs.darwin.lib.darwinSystem system-modules
	else if is-platform "nixos" then
		nixpkgs.lib.nixosSystem system-modules
	else
		system-modules;
in out
