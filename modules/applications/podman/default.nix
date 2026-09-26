{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "podman";
  inherit config;
  extraOptions = {
    package = lib.mkPackageOption pkgs "podman" {};
  };
} (cfg:
    utils.mkPlatformConfig {
      base = utils.mkHomeManagerUser {
        home.packages = [pkgs.podman-compose];
      };
      darwin = utils.mkHomeManagerUser {
        home.packages = [cfg.package];
      };
      nixos = {
        virtualisation.podman.enable = true;
        virtualisation.podman.package = cfg.package;
      };
      linux = utils.mkHomeManagerUser {
        services.podman.enable = true;
        services.podman.package = cfg.package;
      };
    })
