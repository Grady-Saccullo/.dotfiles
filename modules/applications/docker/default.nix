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
          pkgs.colima
          pkgs.docker
          pkgs.docker-buildx
        ];
      };
      nixos = {
        virtualisation.docker.enable = true;
      };
      linux = utils.mkHomeManagerUser {
        home.packages = [pkgs.docker];
      };
    })
