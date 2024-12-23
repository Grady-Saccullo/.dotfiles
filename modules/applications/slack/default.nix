{
  pkgs,
  utils,
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types;
  cfg = config.applications.slack;
in {
  options = {
    applications.slack = {
      enable = mkEnableOption "Slack";
      package = mkOption {
        type = types.package;
        default = pkgs.unstable.slack;
      };
    };
  };
  config = lib.mkIf cfg.enable (utils.mkHomeManagerUser {
    home.packages = [cfg.package];
  });
}
