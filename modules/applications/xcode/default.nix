{
  lib,
  config,
  utils,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.applications.xcode;
in {
  options = {
    applications.xcode = {
      enable = mkEnableOption "Xcode";
    };
  };
  config = lib.mkIf cfg.enable (utils.mkPlatformConfig {
      darwin = {
        homebrew = {
          masApps = {
            "Xcode" = 497799835;
          };
        };
      };
      nixos = "xcode is only supported on darwin";
      linux = "xcode is only supported on darwin";
    });
}
