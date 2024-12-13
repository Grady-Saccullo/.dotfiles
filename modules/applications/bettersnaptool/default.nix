{
  config,
  lib,
  inputs,
  ...
}: let
  inherit (inputs) self;
  inherit (lib) mkEnableOption;
  cfg = config.applications.bettersnaptool;
in {
  options = {
    applications.bettersnaptool = {
      enable = mkEnableOption "BetterSnapTool";
    };
  };
  config = lib.mkIf cfg.enable (
    if self.utils.isNotMachine "darwin"
    then throw "bettersnaptool is only supported on darwin"
    else {
      homebrew.masApps = {
        "BetterSnapTool" = 417375580;
      };
    }
  );
}
