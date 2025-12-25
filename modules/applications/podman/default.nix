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
        home.packages = [pkgs.unstable.podman-compose];
      };
      darwin = utils.mkHomeManagerUser {
        home.packages = [pkgs.unstable.podman];
      };
      nixos = {
        virtualisation.podman.enable = true;
      };
      linux = utils.mkHomeManagerUser {
        services.podman.enable = true;
        services.podman.package = pkgs.unstable.podman;
      };
    })
