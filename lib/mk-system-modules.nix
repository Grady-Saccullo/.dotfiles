{ nixpkgs, overlays, inputs }:
{
	system,
	config,
	extra-modules ? []
}: {
	inherit system;

	modules = [
		{
			nixpkgs.overlays = [
				overlays.unstable-packages
			];

			nixpkgs.config = { allowUnfree = true; };
		}

		{
			config._module.args = {
				currentConfigType = config.type;
				currentSystemUser = config.user;
				inputs = inputs;
			};
		}
	] ++ extra-modules;
}
