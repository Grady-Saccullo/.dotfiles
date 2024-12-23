{
  config,
  lib,
  utils,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.applications.bettersnaptool;
in {
  options = {
    applications.bettersnaptool = {
      enable = mkEnableOption "BetterSnapTool";
    };
  };
  config = lib.mkIf cfg.enable (utils.mkPlatformConfig {
    darwin = {
      homebrew.masApps = {
        "BetterSnapTool" = 417375580;
      };
    };
    nixos = "bettersnaptool is only supported on darwin";
    linux = "bettersnaptool is only supported on darwin";
  });
}
