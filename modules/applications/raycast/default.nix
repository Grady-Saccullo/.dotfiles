{
  config,
  utils,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.applications.raycast;
in {
  options = {
    applications.raycast = {
      enable = mkEnableOption "Raycast";
    };
  };

  config = lib.mkIf cfg.enable (utils.mkPlatformConfig {
    darwin = utils.mkHomeManagerUser {
      home.packages = [pkgs.unstable.raycast];
    };
    nixos = "raycast is only supported on darwin";
    linux = "raycast is only supported on darwin";
  });
}
