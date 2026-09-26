{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  inherit config;
  path = "zoom";
  extraOptions = {
    package = lib.mkPackageOption pkgs "zoom-us" {};
    bundleId = lib.mkOption {
      type = lib.types.str;
      default = "us.zoom.xos";
      readOnly = true;
      description = "macOS bundle identifier, for window-manager rules and the like";
    };
  };
} (cfg:
    utils.mkHomeManagerUser {
      home.packages = [cfg.package];
    })
