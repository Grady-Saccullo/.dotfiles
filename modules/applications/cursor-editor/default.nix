{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "cursor-editor";
  inherit config;
  extraOptions = {
    package = lib.mkPackageOption pkgs "code-cursor" {};
  };
} (cfg:
    utils.mkHomeManagerUser {
      home.packages = [cfg.package];
    })
