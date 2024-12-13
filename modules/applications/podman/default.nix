{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: let
  inherit (inputs) self;
  inherit (lib) mkEnableOption;
  cfg = config.applications.podman;
in {
  options = {
    applications.podman = {
      enable = mkEnableOption "Podman";
    };
  };
  config = lib.mkIf cfg.enable (
    if self.utils.isMachine "nixos"
    then {
      virtualisation.podman = {
        enable = true;
      };
    }
    else if self.utils.isMachine "darwin" then
      self.utils.mkHomeManagerUser {
        home.packages = [pkgs.unstable.podman];
      }
    else 
      self.utils.mkHomeManagerUser {
        services.podman.enable = true;
        services.podman.package = pkgs.unstable.podman;
      }
  );
}
