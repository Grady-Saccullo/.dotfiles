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
      default = pkgs.jetbrains.datagrip;
    };
    bundleId = lib.mkOption {
      type = lib.types.str;
      default = "com.jetbrains.datagrip";
      readOnly = true;
      description = "macOS bundle identifier, for window-manager rules and the like";
    };
  };
} (cfg:
    utils.mkHomeManagerUser {
      home.packages = [cfg.package];
    })
