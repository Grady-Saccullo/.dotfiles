{
  utils,
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.applications.github-cli;
in {
  options = {
    applications.github-cli = {
      enable = mkEnableOption "Github CLI (gh)";
    };
  };
  config = lib.mkIf cfg.enable (utils.mkHomeManagerUser {
    programs = {
      gh = {
        enable = true;
        settings = {
          git_protocol = "ssh";
        };
      };
    };
  });
}
