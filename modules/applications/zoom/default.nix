{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: let
  inherit (inputs) self;
  inherit (lib) mkEnableOption;
  cfg = config.applications.zoom;
in {
  options = {
    applications.zoom = {
      enable = mkEnableOption "Zoom";
    };
  };
  config = lib.mkIf cfg.enable (
    self.utils.mkHomeManagerUser {
      home.packages = [pkgs.unstable.zoom-us];
    }
  );
}
