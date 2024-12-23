{
  lib,
  config,
  utils,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.applications.todoist;
in {
  options = {
    applications.todoist = {
      enable = mkEnableOption "Todoist";
    };
  };
  config = lib.mkIf cfg.enable (utils.mkPlatformConfig {
    darwin = {
      homebrew.casks = [
        {
          name = "todoist";
          greedy = true;
        }
      ];
    };
    nixos = "todoist is only supported on darwin";
    linux = "todoist is only supported on darwin";
  });
}
