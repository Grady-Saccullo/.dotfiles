{
  config,
  lib,
  utils,
  pkgs,
  ...
}: let
  cfg = config.applications.jetbrains.idea;
  enable = utils.allEnable config.applications.jetbrains [
    "enable"
    "idea.enable"
  ];
in {
  options = {
    applications.jetbrains.idea = {
      enable = lib.mkEnableOption "JetBrains / IDEA";
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.unstable.jetbrains.idea-ultimate;
      };
    };
  };

  config = lib.mkIf enable (utils.mkHomeManagerUser {
    home.packages = [cfg.package];
  });
}
