{
  inputs,
  lib,
  config,
  ...
}: let
  inherit (inputs) self;
  inherit (lib) mkEnableOption;
  cfg = config.applications.github-cli;
in {
  options = {
    applications.github-cli = {
      enable = mkEnableOption "Github CLI (gh)";
    };
  };
  config = lib.mkIf cfg.enable (
    self.utils.mkHomeManagerUser {
      programs = {
        gh = {
          enable = true;
        };
      };
    }
  );
}
