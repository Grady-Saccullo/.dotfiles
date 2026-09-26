{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "devenv";
  inherit config;
  extraOptions = {
    package = lib.mkPackageOption pkgs "devenv" {};
  };
} (cfg:
    utils.mkHomeManagerUser {
      home.packages = [cfg.package];
    })
