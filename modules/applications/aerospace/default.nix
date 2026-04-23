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
    profile = lib.mkOption {
      type = lib.types.enum ["personal" "voze"];
      default = "personal";
      description = "Which aerospace profile to use. Names mirror host config names.";
    };
  };
} (cfg:
    utils.mkPlatformConfig {
      darwin = {
        services.aerospace = {
          enable = true;
          package = pkgs.unstable.aerospace;
          settings =
            if cfg.profile == "personal"
            then import ./personal.nix
            else import ./voze.nix;
        };
      };
      nixos = "aerospace is only supported on darwin";
      linux = "aerospace is only supported on darwin";
    })
