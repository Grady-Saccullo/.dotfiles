{
  config,
  lib,
  utils,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.applications.betterdisplay;
in {
  options = {
    applications.betterdisplay = {
      enable = mkEnableOption "BetterDisplay";
    };
  };
  config = lib.mkIf cfg.enable (utils.mkPlatformConfig {
    darwin = {
      homebrew.casks = [
        {
          name = "betterdisplay";
          greedy = true;
        }
      ];
    };
    nixos = "betterdisplay is only supported on darwin";
    linux = "betterdisplay is only supported on darwin";
  });
}
