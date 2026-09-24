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
      default = pkgs.jetbrains.idea;
    };
    bundleId = lib.mkOption {
      type = lib.types.str;
      default = "com.jetbrains.intellij";
      readOnly = true;
      description = "macOS bundle identifier, for window-manager rules and the like";
    };
  };
} (cfg:
    utils.mkHomeManagerUser {
      home.packages = [cfg.package];
    })
