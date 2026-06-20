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
    path = "steam";
    inherit config;
    extraOptions = {
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.unstable.steam;
      };
      path = lib.mkOption {
        type = lib.types.str;
        default =
          if isDarwin
          then "/Applications/Steam.app"
          else "${config.applications.steam.package}/Applications/Steam.app";
      };
    };
  } (cfg:
    utils.mkPlatformConfig {
      darwin = {
        homebrew.casks = [
          {
            name = "steam";
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
