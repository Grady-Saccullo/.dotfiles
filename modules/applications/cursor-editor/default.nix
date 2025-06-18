{
  pkgs,
  utils,
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types;
  cfg = config.applications.cursor-editor;
in {
  options = {
    applications.cursor-editor = {
      enable = mkEnableOption "Cursor";
      package = mkOption {
        type = types.package;
        default = pkgs.unstable.code-cursor;
      };
    };
  };

  config = lib.mkIf cfg.enable (utils.mkHomeManagerUser {
    home.packages = [cfg.package];
  });
}
