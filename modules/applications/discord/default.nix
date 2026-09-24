{
  utils,
  config,
  pkgs,
  lib,
  machineType,
  ...
}: let
  isDarwin = machineType == "darwin";
in
  utils.mkAppModule {
    path = "discord";
    inherit config;
    extraOptions = {
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.discord;
      };
      path = lib.mkOption {
        type = lib.types.str;
        default =
          if isDarwin
          then "/Applications/Discord.app"
          else "${config.applications.discord.package}/Applications/Discord.app";
      };
      bundleId = lib.mkOption {
        type = lib.types.str;
        default = "com.hnc.Discord";
        readOnly = true;
        description = "macOS bundle identifier, for window-manager rules and the like";
      };
    };
  } (cfg:
    utils.mkPlatformConfig {
      darwin = {
        homebrew.casks = [
          {
            name = "discord";
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
