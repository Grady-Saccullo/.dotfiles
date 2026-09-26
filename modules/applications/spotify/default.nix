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
      package = lib.mkPackageOption pkgs "spotify" {};
      path = lib.mkOption {
        type = lib.types.str;
        default =
          if isDarwin
          then "/Applications/Spotify.app"
          else "${config.applications.spotify.package}/Applications/Spotify.app";
      };
      bundleId = lib.mkOption {
        type = lib.types.str;
        default = "com.spotify.client";
        readOnly = true;
        description = "macOS bundle identifier, for window-manager rules and the like";
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
