{
  pkgs,
  utils,
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.applications.devenv;
in {
  options = {
    applications.devenv = {
      enable = mkEnableOption "devenv";
    };
  };
  config = lib.mkIf cfg.enable (utils.mkHomeManagerUser {
    home.packages = [pkgs.unstable.devenv];
  });
}
