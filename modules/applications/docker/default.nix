{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "docker";
  inherit config;
  extraOptions = {
    package = lib.mkPackageOption pkgs "docker" {};
  };
} (cfg:
    utils.mkPlatformConfig {
      darwin = utils.mkHomeManagerUser {
        home.packages = [
          pkgs.colima
          cfg.package
          pkgs.docker-buildx
        ];
      };
      nixos = {
        virtualisation.docker.enable = true;
        virtualisation.docker.package = cfg.package;
      };
      linux = utils.mkHomeManagerUser {
        home.packages = [cfg.package];
      };
    })
