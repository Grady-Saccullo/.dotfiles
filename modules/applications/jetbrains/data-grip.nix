{
  config,
  lib,
  utils,
  pkgs,
  ...
}:
utils.mkAppModule {
  inherit config;
  path = ["jetbrains" "datagrip"];
  extraOptions = {
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.unstable.jetbrains.datagrip;
    };
  };
} (cfg:
    utils.mkHomeManagerUser {
      home.packages = [cfg.package];
    })
