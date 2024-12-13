{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: let
  inherit (inputs) self;
  inherit (lib) mkEnableOption;
  cfg = config.applications.discord;
in {
  options = {
    applications.discord = {
      enable = mkEnableOption "Discord";
    };
  };
  config = lib.mkIf cfg.enable (
    self.utils.mkHomeManagerUser {
      home.packages = [pkgs.unstable.discord];
    }
  );
}
