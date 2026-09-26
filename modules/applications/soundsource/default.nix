{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "soundsource";
  inherit config;
  extraOptions = {
    package = lib.mkPackageOption pkgs "soundsource" {};
  };
} (cfg:
    utils.mkPlatformConfig {
      darwin = utils.mkHomeManagerUser {
        home.packages = [cfg.package];
      };
      nixos = "soundsource is only supported on darwin";
      linux = "soundsource is only supported on darwin";
    })
