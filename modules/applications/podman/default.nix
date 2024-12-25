{
  config,
  utils,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.applications.podman;
in {
  options = {
    applications.podman = {
      enable = mkEnableOption "Podman";
    };
  };
  config = lib.mkIf cfg.enable (utils.mkPlatformConfig {
    base = utils.mkHomeManagerUser {
      home.packages = [pkgs.unstable.podman-compose];
    };
    darwin = utils.mkHomeManagerUser {
      home.packages = [pkgs.unstable.podman];
    };
    nixos = {
      virtualisation.podman = {
        enable = true;
      };
    };
    linux = utils.mkHomeManagerUser {
      services.podman.enable = true;
      services.podman.package = pkgs.unstable.podman;
    };
  });
}
