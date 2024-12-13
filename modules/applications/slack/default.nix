{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: let
  inherit (inputs) self;
  inherit (lib) mkEnableOption;
  cfg = config.applications.slack;
in {
  options = {
    applications.slack = {
      enable = mkEnableOption "Slack";
    };
  };
  config = lib.mkIf cfg.enable (
    self.utils.mkHomeManagerUser {
      home.packages = [pkgs.unstable.slack];
    }
  );
}
