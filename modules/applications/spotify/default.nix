{
  pkgs,
  utils,
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types;
  cfg = config.applications.spotify;
in {
  options = {
    applications.spotify = {
      enable = mkEnableOption "Spotify";
      package = mkOption {
        type = types.package;
        default = pkgs.unstable.spotify;
      };
    };
  };

  config = lib.mkIf cfg.enable (utils.mkHomeManagerUser {
    home.packages = [cfg.package];
  });
}
