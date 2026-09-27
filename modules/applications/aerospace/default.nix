{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "aerospace";
  inherit config;
  extraOptions = {
    package = lib.mkPackageOption pkgs "aerospace" {};
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Attrset forwarded to nix-darwin's services.aerospace.settings; set by the host module (see hosts/example/default.nix).";
    };
  };
} (cfg:
    utils.mkPlatformConfig {
      darwin = {
        services.aerospace = {
          enable = true;
          package = cfg.package;
          inherit (cfg) settings;
        };
      };
      nixos = "aerospace is only supported on darwin";
      linux = "aerospace is only supported on darwin";
    })
