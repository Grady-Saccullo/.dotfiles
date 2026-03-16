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
        default = pkgs.unstable.discord;
      };
      path = lib.mkOption {
        type = lib.types.str;
        default =
          if isDarwin
          then "/Applications/Discord.app"
          else "${config.applications.discord.package}/Applications/Discord.app";
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
        home.packages = [cfg.discord];
      };
      linux = utils.mkHomeManagerUser {
        home.packages = [cfg.package];
      };
    })
