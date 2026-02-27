{
  config,
  lib,
  utils,
  pkgs,
  ...
}:
utils.mkAppModule {
  inherit config;
  path = ["jetbrains" "idea"];
  extraOptions = {
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.unstable.jetbrains.idea;
    };
  };
} (cfg:
    utils.mkHomeManagerUser {
      home.packages = [cfg.package];
    })
