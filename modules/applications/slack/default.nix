{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "slack";
  inherit config;
  extraOptions = {
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.unstable.slack;
    };
  };
} (cfg:
    utils.mkHomeManagerUser {
      home.packages = [cfg.package];
    })
