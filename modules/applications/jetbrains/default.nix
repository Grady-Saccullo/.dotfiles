{
  pkgs,
  utils,
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types;
  inherit (utils) allEnable;
  cfg = config.applications.jetbrains;
  datagripEnable = allEnable cfg [
    "enable"
    "datagrip.enable"
  ];
  ideaEnable = allEnable cfg [
    "enable"
    "idea.enable"
  ];
in {
  options = {
    applications.jetbrains = {
      enable = mkEnableOption "JetBrains";
      datagrip = {
        package = mkOption {
          type = types.package;
          default = pkgs.unstable.jetbrains.datagrip;
        };
        enable = mkEnableOption "JetBrains / DataGrip";
      };
      idea = {
        package = mkOption {
          type = types.package;
          default = pkgs.unstable.jetbrains.idea-ultimate;
        };
        enable = mkEnableOption "JetBrains / IDEA";
      };
    };
  };

  config = lib.mkIf cfg.enable (utils.mkHomeManagerUser {
    home.packages =
      []
      ++ lib.optionals datagripEnable [cfg.datagrip.package]
      ++ lib.optionals ideaEnable [cfg.idea.package];
  });
}
