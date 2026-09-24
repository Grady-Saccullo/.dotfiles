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
    bundleId = lib.mkOption {
      type = lib.types.str;
      default = "us.zoom.xos";
      readOnly = true;
      description = "macOS bundle identifier, for window-manager rules and the like";
    };
  };
} (cfg:
    utils.mkHomeManagerUser {
      home.packages = [pkgs.zoom-us];
    })
