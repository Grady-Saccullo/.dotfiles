{
  config,
  lib,
  utils,
  pkgs,
  ...
}: let
  cfg = config.applications.jetbrains.datagrip;
  enable = utils.allEnable config.applications.jetbrains [
    "enable"
    "datagrip.enable"
  ];
in {
  options = {
    applications.jetbrains.datagrip = {
      enable = lib.mkEnableOption "JetBrains / DataGrip";
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.unstable.jetbrains.datagrip;
      };
    };
  };

  config = lib.mkIf enable (utils.mkHomeManagerUser {
    home.packages = [cfg.package];
  });
}
