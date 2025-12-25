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
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.unstable.code-cursor;
    };
  };
} (cfg:
    utils.mkHomeManagerUser {
      home.packages = [cfg.package];
    })
