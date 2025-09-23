{
  config,
  utils,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.applications.docker;
in {
  options = {
    applications.docker = {
      enable = mkEnableOption "Docker";
    };
  };
  config = lib.mkIf cfg.enable (utils.mkPlatformConfig {
    darwin = utils.mkHomeManagerUser {
      home.packages = [
        pkgs.unstable.colima
        pkgs.unstable.docker
      ];
    };
    nixos = {
      virtualisation.docker = {
        enable = true;
      };
    };
    linux = utils.mkHomeManagerUser {
      home.packages = [pkgs.unstable.docker];
    };
  });
}
