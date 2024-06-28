{
  nixpkgs,
  overlays,
  inputs,
}: {
  systemConfig,
  extra-modules ? [],
}: {
  system = systemConfig.system;
  modules =
    [
      {
        nixpkgs.overlays = [
          overlays.packages
        ];

        nixpkgs.config = {
          allowUnfree = true;
          allowUnsupportedSystem = true;
        };
      }

      {
        # expose inputs and systemConfig globally so
        # we have access to them with ease in other
        # files
        config._module.args = {
          inherit systemConfig inputs;
        };
      }
    ]
    ++ extra-modules;
}
