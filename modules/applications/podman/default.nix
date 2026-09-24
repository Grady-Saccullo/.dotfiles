{
  utils,
  config,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "podman";
  inherit config;
} (cfg:
    utils.mkPlatformConfig {
      base = utils.mkHomeManagerUser {
        home.packages = [pkgs.podman-compose];
      };
      darwin = utils.mkHomeManagerUser {
        home.packages = [pkgs.podman];
      };
      nixos = {
        virtualisation.podman.enable = true;
      };
      linux = utils.mkHomeManagerUser {
        services.podman.enable = true;
        services.podman.package = pkgs.podman;
      };
    })
