{
  utils,
  config,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "docker";
  inherit config;
} (cfg:
    utils.mkPlatformConfig {
      darwin = utils.mkHomeManagerUser {
        home.packages = [
          pkgs.unstable.colima
          pkgs.unstable.docker
          pkgs.unstable.docker-buildx
        ];
      };
      nixos = {
        virtualisation.docker.enable = true;
      };
      linux = utils.mkHomeManagerUser {
        home.packages = [pkgs.unstable.docker];
      };
    })
