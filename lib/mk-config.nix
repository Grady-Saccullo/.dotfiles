{ nixpkgs, overlays, inputs }:
config:
# TODO: create path builder for imports

let
	make-config = import ./mk-system-config.nix;
	config-lib = import ./mk-config-helpers.nix;

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
		inputs.home-manager.darwinModules.home-manager {
		home-manager.useGlobalPkgs = true;
		home-manager.useUserPackages = true;
		home-manager.users.${config.user} = home-manager-config;
	}
	else if config.platform == "nixos" then 
		inputs.home-manager.nixosModules.home-manager {
		home-manager.useGlobalPkgs = true;
		home-manager.useUserPackages = true;
		home-manager.users.${config.user} = home-manager-config;
	}
	else 
		home-manager-config;

	system = config-lib.systemFromConfig config;

	out = if config.platform == "darwin" then 
		throw "HERE"
		# inputs.darwin.lib.darwinSystem make-config { inherit nixpkgs overlays inputs; } {
		# 	inherit machine-module home-manager-module;
		# 	base-inherits =  { inherit system; };
		# }
	else if config == "nixos" then
		nixpkgs.lib.nixosSystem make-config { inherit nixpkgs overlays inputs; } {
			inherit machine-module home-manager-module;
			base-inherits = { system = system; };
		}
	else
		make-config { inherit nixpkgs overlays inputs; } {
			inherit machine-module home-manager-module;
		};
in out
