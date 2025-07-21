{
  config,
  lib,
  utils,
  pkgs,
  ...
}: let
  cfg = config.applications.jetbrains.rider;
  enable = utils.allEnable config.applications.jetbrains [
    "enable"
    "rider.enable"
  ];
in {
  options = {
    applications.jetbrains.rider = {
      enable = lib.mkEnableOption "JetBrains / Rider";
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.unstable.jetbrains.rider;
      };
    };
  };

  config = lib.mkIf enable (utils.mkHomeManagerUser {
    home.packages = [cfg.package];
  });
}
