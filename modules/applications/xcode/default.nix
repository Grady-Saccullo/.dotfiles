{
  config,
  inputs,
  lib,
  ...
}: let
  inherit (inputs) self;
  inherit (lib) mkEnableOption;
  cfg = config.applications.xcode;
in {
  options = {
    applications.xcode = {
      enable = mkEnableOption "Xcode";
    };
  };
  config = lib.mkIf cfg.enable (
    if self.utils.isNotMachine "darwin"
    then throw "xcode is only supported on darwin"
    else {
      homebrew = {
        masApps = {
          "Xcode" = 497799835;
        };
      };
    }
  );
}
