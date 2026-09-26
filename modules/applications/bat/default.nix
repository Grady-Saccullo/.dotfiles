{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "bat";
  inherit config;
  default = true;
  extraOptions = {
    package = lib.mkPackageOption pkgs "bat" {};
  };
} (cfg:
    utils.mkHomeManagerUser {
      programs.bat = {
        enable = true;
        package = cfg.package;
      };
    })
