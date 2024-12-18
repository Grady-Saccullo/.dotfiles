{
  pkgs,
  inputs,
  lib,
  config,
  ...
}: let
  inherit (inputs) self;
  inherit (lib) mkEnableOption mkOption types;
  cfg = config.applications.spotify;
in {
  options = {
    applications.spotify = {
      enable = mkEnableOption "Spotify";
      package = mkOption {
        type = types.package;
        default = pkgs.unstable.spotify;
      };
    };
  };

  config = lib.mkIf cfg.enable (
    self.utils.mkHomeManagerUser {
      home.packages = [cfg.package];
    }
  );
}
