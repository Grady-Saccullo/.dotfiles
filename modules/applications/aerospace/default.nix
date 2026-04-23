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
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Attrset forwarded to nix-darwin's services.aerospace.settings. Per-host configs live under configurations/<host>-configs/aerospace.nix.";
    };
  };
} (cfg:
    utils.mkPlatformConfig {
      darwin = {
        services.aerospace = {
          enable = true;
          package = pkgs.unstable.aerospace;
          inherit (cfg) settings;
        };
      };
      nixos = "aerospace is only supported on darwin";
      linux = "aerospace is only supported on darwin";
    })
