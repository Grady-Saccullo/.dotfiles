{
  pkgs,
  inputs,
  lib,
  config,
  ...
}: let
  inherit (inputs) self;
  inherit (lib) mkEnableOption;
  cfg = config.applications.spotify;
in {
  options = {
    applications.spotify = {
      enable = mkEnableOption "Spotify";
    };
  };

  config = lib.mkIf cfg.enable (
    self.utils.mkHomeManagerUser {
      home.packages = [pkgs.unstable.spotify];
    }
  );
}
