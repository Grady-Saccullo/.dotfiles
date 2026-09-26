{
  config,
  lib,
  utils,
  pkgs,
  ...
}:
utils.mkAppModule {
  inherit config;
  path = ["jetbrains" "rider"];
  extraOptions = {
    package = lib.mkPackageOption pkgs ["jetbrains" "rider"] {};
    bundleId = lib.mkOption {
      type = lib.types.str;
      default = "com.jetbrains.rider";
      readOnly = true;
      description = "macOS bundle identifier, for window-manager rules and the like";
    };
  };
} (cfg:
    utils.mkHomeManagerUser {
      home.packages = [cfg.package];
    })
