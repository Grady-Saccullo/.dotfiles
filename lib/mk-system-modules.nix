{ nixpkgs, overlays, inputs }:
{
	system,
	systemConfig,
	extra-modules ? []
}: {
	inherit system;

	modules = [
		{
			nixpkgs.overlays = [
				overlays.unstable-packages
			];

			nixpkgs.config = {
				allowUnfree = true;
				allowUnsupportedSystem = true;
			};
		}

		{
			config._module.args = {
				inherit systemConfig;
				inputs = inputs;
			};
		}
	] ++ extra-modules;
}
