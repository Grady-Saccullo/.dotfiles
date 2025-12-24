{
  pkgs,
  utils,
  lib,
  config,
  machineType,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types;
  cfg = config.applications.spotify;
  isDarwin = machineType == "darwin";
in {
  options = {
    applications.spotify = {
      enable = mkEnableOption "Spotify";
      package = mkOption {
        type = types.package;
        default = pkgs.unstable.spotify;
      };
      path = mkOption {
        type = types.str;
        default = if isDarwin 
          then "/Applications/Spotify.app"
          else "${cfg.package}/Applications/Spotify.app";
      };
    };
  };

  config = lib.mkIf cfg.enable (utils.mkPlatformConfig {
    darwin = {
      homebrew.casks = [
        {
          name = "spotify";
          greedy = true;
        }
      ];
    };
    nixos = utils.mkHomeManagerUser {
      home.packages = [cfg.package];
    };
    linux = utils.mkHomeManagerUser {
      home.packages = [cfg.package];
    };
  });
}
