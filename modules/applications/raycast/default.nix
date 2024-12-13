{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: let
  inherit (inputs) self;
  inherit (lib) mkEnableOption;
  cfg = config.applications.raycast;
in {
  options = {
    applications.raycast = {
      enable = mkEnableOption "Raycast";
    };
  };

  config = lib.mkIf cfg.enable (
    if self.utils.isNotMachine "darwin"
    then throw "raycast is only supported on darwin"
    else
      self.utils.mkHomeManagerUser {
        home.packages = [pkgs.unstable.raycast];
      }
  );
}
