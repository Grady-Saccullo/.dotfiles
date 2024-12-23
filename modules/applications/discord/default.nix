{
  pkgs,
  utils,
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.applications.discord;
in {
  options = {
    applications.discord = {
      enable = mkEnableOption "Discord";
    };
  };
  config = lib.mkIf cfg.enable (utils.mkHomeManagerUser {
    home.packages = [pkgs.unstable.discord];
  });
}
