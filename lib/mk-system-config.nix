{ nixpkgs, overlays, inputs }:
{
	base-inherits,
	system,
	config,
	machine-module,
	manager-module,
}: {
	inherit base-inherits;

	modules = [
		{
			nixpkgs.overlays = [
				overlays.unstable-packages
			];

			nixpkgs.config = { allowUnfree = true; };
		}

		machine-module
		manager-module

		{
			config._module.args = {
				currentConfigType = config.type;
				currentSystemUser = config.user;
				inputs = inputs;
			};
		}
	];
}
