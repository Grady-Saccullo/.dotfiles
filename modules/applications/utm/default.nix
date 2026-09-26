{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "utm";
  inherit config;
  extraOptions = {
    package = lib.mkPackageOption pkgs "utm" {};
  };
} (cfg:
    utils.mkPlatformConfig {
      darwin = utils.mkHomeManagerUser {
        home.packages = [cfg.package];
      };
      nixos = "utm is only supported on darwin";
      linux = "utm is only supported on darwin";
    })
