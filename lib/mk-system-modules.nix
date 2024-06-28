{ nixpkgs, overlays, inputs }:
{
	systemConfig,
	extra-modules ? []
}: 
{
	system = systemConfig.system;
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
