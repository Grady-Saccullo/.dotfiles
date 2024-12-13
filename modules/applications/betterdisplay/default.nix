{
  config,
  lib,
  inputs,
  ...
}: let
  inherit (inputs) self;
  inherit (lib) mkEnableOption;
  cfg = config.applications.betterdisplay;
in {
  options = {
    applications.betterdisplay = {
      enable = mkEnableOption "BetterDisplay";
    };
  };
  config = lib.mkIf cfg.enable (
    if self.utils.isNotMachine "darwin"
    then throw "betterdisplay is only supported on darwin"
    else {
      homebrew = {
        casks = [
          {
			greedy = true;
			name = "betterdisplay";
          }
        ];
      };
    }
  );
}
