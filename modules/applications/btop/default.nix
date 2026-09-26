{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "btop";
  inherit config;
  default = true;
  extraOptions = {
    package = lib.mkPackageOption pkgs "btop" {};
  };
} (cfg:
    utils.mkHomeManagerUser {
      programs.btop = {
        enable = true;
        package = cfg.package;
      };
    })
