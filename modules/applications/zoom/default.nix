{
  pkgs,
  utils,
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.applications.zoom;
in {
  options = {
    applications.zoom = {
      enable = mkEnableOption "Zoom";
    };
  };
  config = lib.mkIf cfg.enable (
    utils.mkHomeManagerUser {
      home.packages = [pkgs.unstable.zoom-us];
    }
  );
}
