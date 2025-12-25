{
  utils,
  config,
  lib,
  pkgs,
  machineType,
  ...
}: let
  isDarwin = machineType == "darwin";
in
  utils.mkAppModule {
    path = "spotify";
    inherit config;
    extraOptions = {
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.unstable.spotify;
      };
      path = lib.mkOption {
        type = lib.types.str;
        default =
          if isDarwin
          then "/Applications/Spotify.app"
          else "${config.applications.spotify.package}/Applications/Spotify.app";
      };
    };
  } (cfg:
    utils.mkPlatformConfig {
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
    })
