{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "hoppscotch";
  inherit config;
  extraOptions = {
    package = lib.mkPackageOption pkgs "hoppscotch" {};
  };
} (cfg:
    utils.mkHomeManagerUser {
      home.packages = [cfg.package];
    })
